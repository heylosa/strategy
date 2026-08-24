"""Fetch Airbnb listing rating/price snippets for snapshot dates."""
from __future__ import annotations

import json
import re
import urllib.request
from pathlib import Path

PARAMS = "check_in=2026-11-07&check_out=2026-11-10&adults=4&currency=KRW"
HEADERS = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"}

ROOMS = [
    "1509219974753168316",
    "1533243967437545257",
    "1725085449270433615",
    "41419635",
    "1726877927058939818",
    "48258253",
    "1687629257762259553",
    "1698630136741897746",
    "1557587056002785328",
    "1730962067075190343",
    "1728838033573494122",
    "1289827399476238359",
]


def parse(html: str) -> dict:
    out: dict = {}
    m = re.search(r'"guestSatisfactionOverall"\s*:\s*([4-5]\.\d+)', html)
    if not m:
        m = re.search(r'Rated ([4-5]\.\d+) out of 5', html)
    if not m:
        m = re.search(r'([4-5]\.\d+) out of 5 average rating', html)
    if m:
        out["rating"] = float(m.group(1))
    for pat in (
        r'"priceTotal"[^}]*"amount"\s*:\s*(\d+)',
        r'"totalPrice"[^}]*"amount"\s*:\s*(\d+)',
        r'"amountFormatted"\s*:\s*"([^"]+)"',
        r'"primaryLine"[^}]*"price"\s*:\s*"([^"]+)"',
    ):
        m = re.search(pat, html)
        if m:
            val = m.group(1)
            if val.isdigit():
                out["price_krw"] = int(val)
            else:
                out["price_label"] = val
            break
    m = re.search(r'"listingTitle"\s*:\s*"([^"]+)"', html)
    if m:
        out["title"] = m.group(1).encode().decode("unicode_escape")
    elif (m := re.search(r"<title>([^<]+)</title>", html)) and "404" not in m.group(1):
        out["title"] = m.group(1).split(" - ")[0].strip()
    m = re.search(r'"maxGuestCapacity"\s*:\s*(\d+)', html)
    if m:
        out["max_guests"] = int(m.group(1))
    return out


def main() -> None:
    results = []
    for rid in ROOMS:
        url = f"https://www.airbnb.com/rooms/{rid}?{PARAMS}"
        try:
            req = urllib.request.Request(url, headers=HEADERS)
            html = urllib.request.urlopen(req, timeout=25).read().decode("utf-8", "replace")
            row = {"id": rid, "url": url.split("?")[0], **parse(html)}
            results.append(row)
            print(json.dumps(row, ensure_ascii=False))
        except Exception as e:
            print(json.dumps({"id": rid, "error": str(e)}, ensure_ascii=False))
    Path(__file__).resolve().parents[1].joinpath("data", "airbnb_fetch.json").write_text(
        json.dumps(results, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )


if __name__ == "__main__":
    main()
