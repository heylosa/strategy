"""Fetch ICN<->HND for Nov 7-10, 4 adults (RT + OW)."""
from __future__ import annotations

import json
import re
from pathlib import Path

from fast_flights import FlightQuery, Passengers, create_query, fetch_flights_html

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"
AIRLINES = [
    "제주항공",
    "진에어",
    "티웨이항공",
    "이스타항공",
    "파라타항공",
    "에어부산",
    "에어프레미아",
    "아시아나항공",
    "대한항공",
    "피치항공",
    "집에어",
    "에어서울",
    "ANA",
    "전일본공수",
    "일본항공",
    "JAL",
]


def parse(html: str, min_price: int = 50_000) -> list[dict]:
    items = []
    for m in re.finditer(r'aria-label="(\d+) 대한민국 원"', html):
        price = int(m.group(1))
        if price < min_price:
            continue
        before = html[max(0, m.start() - 8000) : m.start()]
        after = html[m.start() : m.start() + 800]
        airline = None
        pos = -1
        for a in AIRLINES:
            j = before.rfind(a)
            if j > pos:
                pos = j
                airline = a
        times: list[str] = []
        for t in re.findall(r"(?<!\d)(\d{1,2}:\d{2})(?!\d)", before[-2000:] + after):
            h, mi = t.split(":")
            tt = f"{int(h):02d}:{mi}"
            if tt not in times:
                times.append(tt)
        items.append({"airline": airline, "price": price, "times": times[:6]})
    seen = set()
    out = []
    for it in items:
        key = (it["airline"], tuple(it["times"][:2]), it["price"])
        if key in seen:
            continue
        seen.add(key)
        out.append(it)
    return sorted(out, key=lambda x: x["price"])


def grab(label: str, flights: list[FlightQuery], trip: str = "one-way") -> list[dict]:
    q = create_query(
        flights=flights,
        trip=trip,
        seat="economy",
        passengers=Passengers(adults=4),
        language="ko",
        currency="KRW",
        max_stops=0,
    )
    html = fetch_flights_html(q)
    (DATA / f"{label}.html").write_text(html, encoding="utf-8")
    rows = parse(html, 200_000 if trip == "round-trip" else 50_000)
    (DATA / f"{label}.json").write_text(
        json.dumps(rows[:60], ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print("===", label, "n=", len(rows))
    for it in rows[:25]:
        print(" ", it)
    return rows


def main() -> None:
    grab(
        "hnd_rt",
        [
            FlightQuery(date="2026-11-07", from_airport="ICN", to_airport="HND"),
            FlightQuery(date="2026-11-10", from_airport="HND", to_airport="ICN"),
        ],
        trip="round-trip",
    )
    grab(
        "hnd_out",
        [
            FlightQuery(
                date="2026-11-07",
                from_airport="ICN",
                to_airport="HND",
                earliest_departure_hour=5,
                latest_departure_hour=14,
            )
        ],
    )
    grab(
        "hnd_ret",
        [FlightQuery(date="2026-11-10", from_airport="HND", to_airport="ICN")],
    )


if __name__ == "__main__":
    main()
