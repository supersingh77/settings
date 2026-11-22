import json
from pathlib import Path

DECLARED_DIR = Path(__file__).resolve().parent.parent / "declared"


def load(name):
    return json.loads((DECLARED_DIR / f"{name}.json").read_text())
