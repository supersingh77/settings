import json
import subprocess
import urllib.request

from .download import USER_AGENT
from .model import Result


def run(argv, cwd=None):
    try:
        done = subprocess.run(
            argv, capture_output=True, text=True, check=False, cwd=cwd
        )
    except FileNotFoundError as error:
        return Result(127, "", str(error))
    return Result(done.returncode, done.stdout, done.stderr)


def run_live(argv, cwd=None):
    try:
        return subprocess.run(argv, check=False, cwd=cwd).returncode
    except FileNotFoundError:
        return 127


def fetch_json(url):
    request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(request, timeout=30) as response:
        return json.load(response)


def say(message):
    print(message, flush=True)
