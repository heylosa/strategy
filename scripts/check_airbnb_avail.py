"""Check Airbnb listing availability + rating for fixed dates (4 adults)."""
from __future__ import annotations

import json
import re
import urllib.request
from pathlib import Path

PARAMS = "check_in=2026-11-07&check_out=2026-11-10&adults=4&currency=KRW"
HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
    "Accept-Language": "ko-KR,ko;q=0.9",
}

UNAVAIL = (
    "날짜 이용 불가",
    "이용 불가",
    "not available",
    "Those dates are not available",
    "선택한 날짜",
    "예약할 수 없",
    "unavailable",
    '"available":false',
    "CALENDAR_BLOCKED",
)

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


def check(html: str) -> dict:
    out: dict = {"available": True}
    low = html.lower()
    for pat in UNAVAIL:
        if pat.lower() in low or pat in html:
            out["available"] = False
            out["reason"] = pat
            break
    if re.search(r'"isAvailable"\s*:\s*false', html):
        out["available"] = False
        out["reason"] = "isAvailable:false"
    m = re.search(r'"guestSatisfactionOverall"\s*:\s*([4-5]\.\d+)', html)
    if m:
        out["rating"] = float(m.group(1))
    for pat in (
        r'"priceTotal"[^}]*"amount"\s*:\s*(\d+)',
        r'"totalPrice"[^}]*"amount"\s*:\s*(\d+)',
    ):
        m = re.search(pat, html)
        if m:
            out["price_krw_total"] = int(m.group(1))
            break
    m = re.search(r'"listingTitle"\s*:\s*"([^"]+)"', html)
    if m:
        out["title"] = m.group(1)
    return out


def main() -> None:
    rows = []
    for rid in ROOMS:
        url = f"https://www.airbnb.co.kr/rooms/{rid}?{PARAMS}"
        try:
            req = urllib.request.Request(url, headers=HEADERS)
            html = urllib.request.urlopen(req, timeout=25).read().decode("utf-8", "replace")
            row = {"id": rid, **check(html)}
            rows.append(row)
            print(json.dumps(row, ensure_ascii=False))
        except Exception as e:
            rows.append({"id": rid, "error": str(e), "available": False})
            print(json.dumps(rows[-1], ensure_ascii=False))
    Path(__file__).resolve().parents[1].joinpath("data", "airbnb_avail.json").write_text(
        json.dumps(rows, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )


if __name__ == "__main__":
    main()
