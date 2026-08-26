"""Run full snapshot update: flights + stays."""
from __future__ import annotations

import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def run(name: str) -> None:
    print(f"--- {name} ---")
    subprocess.check_call([sys.executable, str(ROOT / "scripts" / name)])


if __name__ == "__main__":
    run("update_flights.py")
    run("rebuild_stays_verified.py")
    print("Done.")
