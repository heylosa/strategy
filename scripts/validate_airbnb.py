"""Validate Airbnb candidates: available on dates, rating>=4, 4 guests, price band."""
from __future__ import annotations

import json
import re
import urllib.request
from pathlib import Path

PARAMS = "check_in=2026-11-07&check_out=2026-11-10&adults=4&currency=KRW"
HEADERS = {"User-Agent": "Mozilla/5.0", "Accept-Language": "ko-KR,ko;q=0.9"}
MIN_NIGHT = 600_000
MAX_NIGHT = 1_000_000
MIN_TOTAL = 600_000  # 60만
MAX_TOTAL = 1_000_000  # 100만 for 3 nights? User said 60-100 - could be per night OR total

# User asked 60-100 올려서 - in context of 3박 totals, use 60-100만 total for 3 nights
MIN_TOTAL_3N = 600_000
MAX_TOTAL_3N = 1_000_000

CANDIDATES = {
    "asakusa": [
        "1740580454363418821", "1749138978286595434", "1114738990947261614",
        "1493873270422901329", "23615874", "48258253",
    ],
    "ueno": [
        "1749138978286595434", "1597444474716342203", "1729700739586109953",
        "1687629257762259553",
    ],
    "asakusabashi": [
        "1241926614031562339", "1234118105011866807", "1411184221461003011",
        "1289827399476238359",
    ],
    "kinshicho": [
        "1215868303472065960", "1607201196181498884", "1557587056002785328",
    ],
    "shinjuku": [
        "1730333373467601656", "1440146085380961828", "1082363284302921530",
        "1728838033573494122",
    ],
}


def parse(html: str) -> dict:
    out: dict = {"available": True}
    if re.search(r"날짜.{0,8}이용.{0,4}불가", html):
        out["available"] = False
    if re.search(r"Those dates are not available", html, re.I):
        out["available"] = False
    if re.search(r'"canInstantBook"\s*:\s*false', html) and not re.search(
        r'"priceTotal"[^}]*"amount"\s*:\s*(\d+)', html
    ):
        pass  # weak signal
    m = re.search(r'"guestSatisfactionOverall"\s*:\s*([0-5]\.\d+)', html)
    if m:
        out["rating"] = float(m.group(1))
    m = re.search(r'"maxGuestCapacity"\s*:\s*(\d+)', html)
    if m:
        out["max_guests"] = int(m.group(1))
    m = re.search(r'"priceTotal"[^}]*"amount"\s*:\s*(\d+)', html)
    if m:
        out["price_krw_total"] = int(m.group(1))
    m = re.search(r'"listingTitle"\s*:\s*"((?:[^"\\]|\\.)*)"', html)
    if m:
        t = m.group(1).encode().decode("unicode_escape")
        out["title"] = t
    if out.get("rating", 0) < 4.0:
        out["available"] = False
        out["reason"] = "rating<4"
    if out.get("max_guests", 0) < 4:
        out["available"] = False
        out["reason"] = "guests<4"
    p = out.get("price_krw_total")
    if p and not (MIN_TOTAL_3N <= p <= MAX_TOTAL_3N):
        out["price_band_ok"] = False
    elif p:
        out["price_band_ok"] = True
    return out


def main() -> None:
    seen: set[str] = set()
    results: dict[str, list] = {}
    for area, ids in CANDIDATES.items():
        results[area] = []
        for rid in ids:
            if rid in seen:
                continue
            seen.add(rid)
            url = f"https://www.airbnb.co.kr/rooms/{rid}?{PARAMS}"
            try:
                html = urllib.request.urlopen(
                    urllib.request.Request(url, headers=HEADERS), timeout=25
                ).read().decode("utf-8", "replace")
                row = {"id": rid, "url": url.split("?")[0], **parse(html)}
                results[area].append(row)
                ok = row.get("available") and row.get("rating", 0) >= 4 and row.get("max_guests", 0) >= 4
                print(json.dumps({**row, "ok": ok}, ensure_ascii=False))
            except Exception as e:
                print(json.dumps({"id": rid, "error": str(e)}, ensure_ascii=False))
    Path(__file__).resolve().parents[1].joinpath("data", "airbnb_validated.json").write_text(
        json.dumps(results, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )


if __name__ == "__main__":
    main()
