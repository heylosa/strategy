"""Refresh Tokyo flight snapshot helpers.

Primary live prices for this trip were captured from Naver Flights in-browser
(corporate SSL MITM breaks some HTTPS scrapers; prefer manual/browser refresh).

Optional: pip install fast-flights  then attempt Google Flights HTML fetch.
Push updates with SSH only: git@github.com:heylosa/strategy.git
"""
from __future__ import annotations

import json
from datetime import datetime, timezone, timedelta
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data" / "flights.json"
KST = timezone(timedelta(hours=9))


def stamp() -> None:
    data = json.loads(DATA.read_text(encoding="utf-8"))
    data["queried_at"] = datetime.now(KST).isoformat(timespec="seconds")
    DATA.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Updated queried_at -> {data['queried_at']}")


if __name__ == "__main__":
    stamp()
