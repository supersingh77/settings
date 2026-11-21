#!/usr/bin/env python3
from __future__ import annotations

import os
import sys
import threading
import time
import urllib.error
import urllib.request

# ── ANSI colours ─────────────────────────────────────────────────────────────

BOLD = "\033[1m"
GREEN = "\033[32m"
YELL = "\033[33m"
CYAN = "\033[36m"
RED = "\033[31m"
DIM = "\033[2m"
RST = "\033[0m"


def _info(msg: str) -> None:
    print(f"{CYAN}ℹ  {msg}{RST}", flush=True)


def _ok(msg: str) -> None:
    print(f"{GREEN}✔  {msg}{RST}", flush=True)


def _warn(msg: str) -> None:
    print(f"{YELL}⚠  {msg}{RST}", flush=True)


def _err(msg: str) -> None:
    print(f"{RED}✖  {msg}{RST}", file=sys.stderr, flush=True)


# ── Shared HTTP headers ───────────────────────────────────────────────────────

_UA = (
    "Mozilla/5.0 (X11; Linux x86_64) "
    "AppleWebKit/537.36 (KHTML, like Gecko) "
    "Chrome/124.0 Safari/537.36"
)
_BASE_HEADERS = {"User-Agent": _UA}


# ── Helpers ───────────────────────────────────────────────────────────────────


def _fmt_bytes(n: float) -> str:
    for unit in ("B", "KB", "MB", "GB", "TB"):
        if abs(n) < 1024.0:
            return f"{n:.1f} {unit}"
        n /= 1024.0
    return f"{n:.1f} PB"


def _fmt_speed(bps: float) -> str:
    return _fmt_bytes(bps) + "/s"


def _print_bar(done: int, total: int, t0: float) -> None:
    elapsed = max(time.monotonic() - t0, 1e-6)
    speed = done / elapsed
    pct = (done / total * 100.0) if total else 0.0
    eta_s = int((total - done) / speed) if (speed > 1 and total > done) else 0

    filled = int(30 * pct / 100)
    bar = f"{CYAN}{'█' * filled}{'░' * (30 - filled)}{RST}"

    print(
        f"\r  {BOLD}{pct:5.1f}%{RST}  [{bar}]  "
        f"{_fmt_bytes(done)}/{_fmt_bytes(total)}  "
        f"{BOLD}{_fmt_speed(speed)}{RST}  "
        f"{DIM}ETA {eta_s}s{RST}   ",
        end="",
        flush=True,
    )


# ── URL resolution ────────────────────────────────────────────────────────────


def _resolve(url: str) -> tuple[str, int, bool]:
    """
    Follow all redirects, probe range-request support, and return:
        (final_url, total_bytes, supports_ranges)

    Uses a Range: bytes=0-0 probe so we download only a single byte while
    still following every redirect and obtaining the Content-Range total.
    """
    _info("Resolving URL and probing server capabilities…")

    probe_req = urllib.request.Request(
        url,
        headers={**_BASE_HEADERS, "Range": "bytes=0-0"},
    )

    try:
        with urllib.request.urlopen(probe_req, timeout=30) as resp:
            final_url = resp.url
            status = resp.status

            # Content-Range: bytes 0-0/TOTAL  →  extract TOTAL
            cr = resp.headers.get("Content-Range", "")
            total = 0
            if cr and "/" in cr:
                try:
                    total = int(cr.split("/")[-1])
                except ValueError:
                    pass

            # Fallback: if server returned 200 + Content-Length (no range support)
            if not total:
                total = int(resp.headers.get("Content-Length") or 0)

            supports_ranges = (status == 206) and (total > 0)

    except urllib.error.URLError as exc:
        _err(f"Failed to reach URL: {exc}")
        sys.exit(1)

    _info(f"Final URL  : {final_url[:80]}{'…' if len(final_url) > 80 else ''}")
    _info(f"File size  : {_fmt_bytes(total)}" if total else "File size  : unknown")
    _info(
        f"Range reqs : {'yes ✔' if supports_ranges else 'no — will use single connection'}"
    )

    return final_url, total, supports_ranges


# ── Single-connection fallback ────────────────────────────────────────────────


def _download_single(url: str, dest: str) -> None:
    _warn("Falling back to single-connection download…")
    req = urllib.request.Request(url, headers=_BASE_HEADERS)

    with urllib.request.urlopen(req, timeout=60) as resp:
        total = int(resp.headers.get("Content-Length") or 0)
        done = 0
        t0 = time.monotonic()
        with open(dest, "wb") as fh:
            while True:
                chunk = resp.read(1 << 17)  # 128 KiB
                if not chunk:
                    break
                fh.write(chunk)
                done += len(chunk)
                if total:
                    _print_bar(done, total, t0)

    print()


# ── Parallel downloader ───────────────────────────────────────────────────────


def _download_parallel(url: str, dest: str, n_conn: int) -> None:
    """
    Download *url* into *dest* using *n_conn* parallel range-request workers.

    Each worker streams its slice in 256 KiB increments, writing directly to
    the pre-allocated output file at the correct offset.  The shared progress
    counter is updated after every write so the progress bar is live.
    """

    final_url, total, supports_ranges = _resolve(url)

    if not supports_ranges or not total:
        _download_single(final_url if final_url else url, dest)
        return

    n_conn = max(1, min(n_conn, 32))
    _info(f"Connections: {n_conn}")

    # Pre-allocate destination file (avoids fragmentation, catches disk-full early).
    _info(f"Allocating  {_fmt_bytes(total)} at {dest} …")
    with open(dest, "wb") as fh:
        fh.seek(total - 1)
        fh.write(b"\x00")

    # ── Shared state ──────────────────────────────────────────────────────────
    lock = threading.Lock()
    downloaded = [0]  # bytes written so far (updated per chunk)
    errors: list[str] = []

    # ── Worker ────────────────────────────────────────────────────────────────
    def worker(tid: int, byte_start: int, byte_end: int) -> None:
        """Download bytes [byte_start, byte_end] and write them to *dest*."""
        max_retries = 5
        backoff = 1.0

        for attempt in range(1, max_retries + 1):
            try:
                req = urllib.request.Request(
                    final_url,
                    headers={
                        **_BASE_HEADERS,
                        "Range": f"bytes={byte_start}-{byte_end}",
                    },
                )
                with urllib.request.urlopen(req, timeout=90) as resp:
                    # Stream in 256 KiB increments; update progress after each write.
                    write_pos = byte_start
                    with open(dest, "r+b") as fh:
                        fh.seek(write_pos)
                        while True:
                            chunk = resp.read(1 << 18)  # 256 KiB
                            if not chunk:
                                break
                            fh.write(chunk)
                            write_pos += len(chunk)
                            with lock:
                                downloaded[0] += len(chunk)
                return  # success

            except (urllib.error.URLError, OSError, ValueError) as exc:
                if attempt == max_retries:
                    with lock:
                        errors.append(f"[thread {tid}] {type(exc).__name__}: {exc}")
                    return
                time.sleep(backoff)
                backoff = min(backoff * 2.0, 30.0)

    # ── Dispatch threads ──────────────────────────────────────────────────────
    chunk_size = total // n_conn
    threads: list[threading.Thread] = []

    for i in range(n_conn):
        start = i * chunk_size
        end = (total - 1) if (i == n_conn - 1) else ((i + 1) * chunk_size - 1)
        t = threading.Thread(target=worker, args=(i, start, end), daemon=True)
        threads.append(t)

    t0 = time.monotonic()
    for t in threads:
        t.start()

    # ── Live progress (main thread) ───────────────────────────────────────────
    while any(t.is_alive() for t in threads):
        with lock:
            done = downloaded[0]
        _print_bar(done, total, t0)
        time.sleep(0.25)

    for t in threads:
        t.join()

    # Final bar update
    with lock:
        done = downloaded[0]
    _print_bar(done, total, t0)
    print()  # newline after progress bar

    # ── Error check ───────────────────────────────────────────────────────────
    if errors:
        for msg in errors:
            _err(msg)
        try:
            os.remove(dest)
        except OSError:
            pass
        sys.exit(1)

    elapsed = time.monotonic() - t0
    avg_speed = total / max(elapsed, 1e-6)
    _ok(
        f"Downloaded {_fmt_bytes(total)} in {elapsed:.1f}s "
        f"(avg {_fmt_speed(avg_speed)})"
    )


# ── Entry point ───────────────────────────────────────────────────────────────


def main() -> None:
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(1)

    url = sys.argv[1]
    dest = sys.argv[2]
    n_conn = int(sys.argv[3]) if len(sys.argv) > 3 else 16

    _info(f"URL         : {url}")
    _info(f"Destination : {dest}")

    os.makedirs(os.path.dirname(os.path.abspath(dest)) or ".", exist_ok=True)

    try:
        _download_parallel(url, dest, n_conn)
    except KeyboardInterrupt:
        print()
        _warn("Interrupted by user.")
        try:
            os.remove(dest)
        except OSError:
            pass
        sys.exit(130)


if __name__ == "__main__":
    main()
