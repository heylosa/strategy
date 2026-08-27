"""Scrape room IDs from Airbnb area search (price 60-100만/박, 4 adults)."""
from __future__ import annotations

import json
import re
import urllib.parse
import urllib.request

HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
    "Accept-Language": "ko-KR,ko;q=0.9",
}

# price_min/max on airbnb.co.kr = NIGHTLY average KRW
# For ~₩60–100만 / 3 nights stay total, use ~180000–350000 per night.
AREAS = {
    "asakusa": "Asakusa-Tokyo-Japan",
    "ueno": "Ueno-Tokyo-Japan",
    "asakusabashi": "Asakusabashi-Tokyo-Japan",
    "kinshicho": "Kinshicho-Tokyo-Japan",
    "shinjuku": "Shinjuku-Tokyo-Japan",
}

BASE = (
    "https://www.airbnb.co.kr/s/{slug}/homes"
    "?checkin=2026-11-07&checkout=2026-11-10&adults=4"
    "&min_bedrooms=1&room_types%5B%5D=Entire%20home%2Fapt"
    "&currency=KRW&price_min=180000&price_max=350000"
)


def room_ids(html: str) -> list[str]:
    return list(dict.fromkeys(re.findall(r'"listingId"\s*:\s*"(\d+)"', html)))[:15]


def main() -> None:
    out = {}
    for key, slug in AREAS.items():
        url = BASE.format(slug=slug)
        try:
            req = urllib.request.Request(url, headers=HEADERS)
            html = urllib.request.urlopen(req, timeout=25).read().decode("utf-8", "replace")
            ids = room_ids(html)
            out[key] = {"url": url, "ids": ids, "count": len(ids)}
            print(key, len(ids), ids[:5])
        except Exception as e:
            out[key] = {"error": str(e)}
            print(key, "ERR", e)
    print(json.dumps(out, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
