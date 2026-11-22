import os
import sys
import threading
import time
import urllib.error
import urllib.request
from pathlib import Path

USER_AGENT = (
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/124.0 Safari/537.36"
)
CONNECTIONS = 16
MAX_CONNECTIONS = 32
RETRIES = 5
SINGLE_CHUNK = 1 << 17
RANGE_CHUNK = 1 << 18
UNITS = ("B", "KB", "MB", "GB", "TB")


class DownloadError(Exception):
    pass


def format_bytes(count):
    value = float(count)
    for unit in UNITS:
        if abs(value) < 1024.0:
            return f"{value:.1f} {unit}"
        value /= 1024.0
    return f"{value:.1f} PB"


def split_ranges(total, parts):
    parts = max(1, min(parts, MAX_CONNECTIONS, total))
    size = total // parts
    ranges = []
    for index in range(parts):
        start = index * size
        end = total - 1 if index == parts - 1 else (index + 1) * size - 1
        ranges.append((start, end))
    return ranges


def total_from_headers(content_range, content_length):
    if content_range and "/" in content_range:
        tail = content_range.rsplit("/", 1)[1]
        if tail.isdigit():
            return int(tail)
    return int(content_length or 0)


def progress_line(done, total, started, now):
    elapsed = max(now - started, 1e-6)
    percent = done / total * 100.0 if total else 0.0
    return (
        f"{percent:5.1f}%  {format_bytes(done)}/{format_bytes(total)}  "
        f"{format_bytes(done / elapsed)}/s"
    )


def request(url, headers=None):
    return urllib.request.Request(
        url, headers={"User-Agent": USER_AGENT, **(headers or {})}
    )


def probe(url):
    try:
        with urllib.request.urlopen(
            request(url, {"Range": "bytes=0-0"}), timeout=30
        ) as response:
            total = total_from_headers(
                response.headers.get("Content-Range", ""),
                response.headers.get("Content-Length"),
            )
            return response.url, total, response.status == 206 and total > 0
    except urllib.error.URLError as error:
        raise DownloadError(f"cannot reach {url}: {error}") from error


def download_single(url, destination):
    try:
        with (
            urllib.request.urlopen(request(url), timeout=60) as response,
            open(destination, "wb") as handle,
        ):
            while chunk := response.read(SINGLE_CHUNK):
                handle.write(chunk)
    except (urllib.error.URLError, OSError) as error:
        raise DownloadError(f"download failed: {error}") from error


class Counter:
    def __init__(self):
        self.lock = threading.Lock()
        self.done = 0
        self.errors = []

    def add(self, amount):
        with self.lock:
            self.done += amount

    def fail(self, message):
        with self.lock:
            self.errors.append(message)

    def snapshot(self):
        with self.lock:
            return self.done, list(self.errors)


def fetch_range(url, destination, start, end, counter):
    delay = 1.0
    for attempt in range(1, RETRIES + 1):
        try:
            with urllib.request.urlopen(
                request(url, {"Range": f"bytes={start}-{end}"}), timeout=90
            ) as response:
                position = start
                with open(destination, "r+b") as handle:
                    handle.seek(position)
                    while chunk := response.read(RANGE_CHUNK):
                        handle.write(chunk)
                        position += len(chunk)
                        counter.add(len(chunk))
            return
        except (urllib.error.URLError, OSError, ValueError) as error:
            if attempt == RETRIES:
                counter.fail(f"{type(error).__name__}: {error}")
                return
            time.sleep(delay)
            delay = min(delay * 2.0, 30.0)


def show_progress(done, total, started):
    if sys.stdout.isatty():
        line = progress_line(done, total, started, time.monotonic())
        print(f"\r{line}", end="", flush=True)


def download_parallel(url, destination, connections):
    final_url, total, ranged = probe(url)
    if not ranged:
        download_single(final_url, destination)
        return
    with open(destination, "wb") as handle:
        handle.seek(total - 1)
        handle.write(b"\x00")
    counter = Counter()
    threads = [
        threading.Thread(
            target=fetch_range,
            args=(final_url, destination, start, end, counter),
            daemon=True,
        )
        for start, end in split_ranges(total, connections)
    ]
    started = time.monotonic()
    for thread in threads:
        thread.start()
    while any(thread.is_alive() for thread in threads):
        show_progress(counter.snapshot()[0], total, started)
        time.sleep(0.25)
    for thread in threads:
        thread.join()
    done, errors = counter.snapshot()
    show_progress(done, total, started)
    if sys.stdout.isatty():
        print()
    if errors or done != total:
        raise DownloadError("; ".join(errors) or f"received {done} of {total} bytes")


def download(url, destination, connections=CONNECTIONS):
    destination = Path(destination)
    destination.parent.mkdir(parents=True, exist_ok=True)
    try:
        download_parallel(url, destination, connections)
    except (DownloadError, OSError) as parallel_error:
        print(f"parallel download failed ({parallel_error}); retrying single stream")
        try:
            download_single(url, destination)
        except DownloadError:
            if destination.exists():
                os.remove(destination)
            raise
