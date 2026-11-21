import importlib.util
import pathlib
import tempfile
import unittest
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from threading import Thread
from unittest.mock import patch

SCRIPT = pathlib.Path(__file__).parents[1] / "scripts" / "parallel-download.py"
SPEC = importlib.util.spec_from_file_location("parallel_download", SCRIPT)
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class DownloadTests(unittest.TestCase):
    def test_formats_bytes(self):
        self.assertEqual(MODULE._fmt_bytes(512), "512.0 B")
        self.assertEqual(MODULE._fmt_bytes(1024), "1.0 KB")
        self.assertEqual(MODULE._fmt_bytes(1024**2), "1.0 MB")

    def test_formats_negative_bytes(self):
        self.assertEqual(MODULE._fmt_bytes(-2048), "-2.0 KB")

    def test_range_download_writes_complete_payload(self):
        payload = bytes(range(256)) * 4096

        class Handler(BaseHTTPRequestHandler):
            def do_GET(self):
                byte_range = self.headers.get("Range")
                if byte_range:
                    start, end = map(int, byte_range.removeprefix("bytes=").split("-"))
                    chunk = payload[start : end + 1]
                    self.send_response(206)
                    self.send_header(
                        "Content-Range", f"bytes {start}-{end}/{len(payload)}"
                    )
                    self.send_header("Content-Length", str(len(chunk)))
                    self.end_headers()
                    self.wfile.write(chunk)
                    return
                self.send_response(200)
                self.send_header("Content-Length", str(len(payload)))
                self.end_headers()
                self.wfile.write(payload)

            def log_message(self, *_args):
                return

        server = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
        thread = Thread(target=server.serve_forever, daemon=True)
        thread.start()
        try:
            with tempfile.TemporaryDirectory() as directory:
                target = pathlib.Path(directory) / "payload.bin"
                url = f"http://127.0.0.1:{server.server_port}/payload"
                with (
                    patch.object(MODULE, "_print_bar", lambda *_args: None),
                    patch.object(MODULE.time, "sleep", lambda *_args: None),
                ):
                    MODULE._download_parallel(url, str(target), 4)
                self.assertEqual(target.read_bytes(), payload)
        finally:
            server.shutdown()
            server.server_close()
            thread.join(timeout=2)


if __name__ == "__main__":
    unittest.main()
