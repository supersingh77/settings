import itertools
import pathlib
import tempfile
import unittest
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from threading import Thread
from unittest.mock import patch

from laptop import download

PAYLOAD = bytes(range(256)) * 4096


def handler(ranges):
    class Handler(BaseHTTPRequestHandler):
        def do_GET(self):
            requested = self.headers.get("Range")
            if requested and ranges:
                start, end = map(int, requested.removeprefix("bytes=").split("-"))
                chunk = PAYLOAD[start : end + 1]
                self.send_response(206)
                self.send_header("Content-Range", f"bytes {start}-{end}/{len(PAYLOAD)}")
                self.send_header("Content-Length", str(len(chunk)))
                self.end_headers()
                self.wfile.write(chunk)
                return
            self.send_response(200)
            self.send_header("Content-Length", str(len(PAYLOAD)))
            self.end_headers()
            self.wfile.write(PAYLOAD)

        def log_message(self, *_args):
            return

    return Handler


class DownloadTests(unittest.TestCase):
    def serve(self, ranges):
        server = ThreadingHTTPServer(("127.0.0.1", 0), handler(ranges))
        thread = Thread(target=server.serve_forever, daemon=True)
        thread.start()
        self.addCleanup(thread.join, 2)
        self.addCleanup(server.server_close)
        self.addCleanup(server.shutdown)
        return f"http://127.0.0.1:{server.server_port}/payload"

    def fetch(self, ranges):
        url = self.serve(ranges)
        with tempfile.TemporaryDirectory() as directory:
            target = pathlib.Path(directory) / "nested" / "payload.bin"
            with patch.object(download.time, "sleep", lambda *_a: None):
                download.download(url, target, 4)
            return target.read_bytes()

    def test_ranged_download_is_complete(self):
        self.assertEqual(self.fetch(True), PAYLOAD)

    def test_server_without_ranges_uses_single_stream(self):
        self.assertEqual(self.fetch(False), PAYLOAD)

    def test_formats_bytes(self):
        self.assertEqual(download.format_bytes(512), "512.0 B")
        self.assertEqual(download.format_bytes(1024**2), "1.0 MB")
        self.assertEqual(download.format_bytes(-2048), "-2.0 KB")

    def test_ranges_cover_total_without_overlap(self):
        for total, parts in ((10, 3), (1, 16), (1000, 16), (7, 7)):
            ranges = download.split_ranges(total, parts)
            self.assertEqual(ranges[0][0], 0)
            self.assertEqual(ranges[-1][1], total - 1)
            for (_, end), (start, _) in itertools.pairwise(ranges):
                self.assertEqual(start, end + 1)


if __name__ == "__main__":
    unittest.main()
