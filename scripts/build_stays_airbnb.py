"""Rebuild stays.json airbnb_picks — DO NOT invent prices.

Airbnb HTML scrape usually hides live totals. Prefer:
  1) Browser-verified totals (scripts/rebuild_stays_verified.py)
  2) Or re-run search with nightly filter ~180k–350k (= ~60–100만 / 3박)

Search URL price_min/max on airbnb.co.kr is NIGHTLY average, not stay total.
Never label catalog guesses as 3박 totals.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def main() -> None:
    print(
        "Refusing estimate-based rebuild.\n"
        "Run: python scripts/rebuild_stays_verified.py\n"
        "Or update VERIFIED totals after browser check, then rebuild."
    )
    # Keep verified path as the supported update.
    sys.path.insert(0, str(ROOT / "scripts"))
    import rebuild_stays_verified as v

    v.main()


if __name__ == "__main__":
    main()
