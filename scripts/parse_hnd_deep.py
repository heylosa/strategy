"""Deeper parse of HND RT HTML + full outbound list."""
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
    "전일본공수",
    "일본항공",
]


def parse(html: str, min_price: int) -> list[dict]:
    items = []
    for m in re.finditer(r'aria-label="(\d+) 대한민국 원"', html):
        price = int(m.group(1))
        if price < min_price:
            continue
        before = html[max(0, m.start() - 10000) : m.start()]
        after = html[m.start() : m.start() + 1500]
        airline = None
        pos = -1
        for a in AIRLINES:
            j = before.rfind(a)
            if j > pos:
                pos = j
                airline = a
        chunk = before[-3000:] + after
        times = []
        for t in re.findall(r"(?<!\d)(\d{1,2}:\d{2})(?!\d)", chunk):
            h, mi = t.split(":")
            tt = f"{int(h):02d}:{mi}"
            if tt not in times:
                times.append(tt)
        items.append({"airline": airline, "price": price, "times": times[:10]})
    seen = set()
    out = []
    for it in items:
        key = (it["airline"], tuple(it["times"][:4]), it["price"])
        if key in seen:
            continue
        seen.add(key)
        out.append(it)
    return sorted(out, key=lambda x: x["price"])


def main() -> None:
    # all-day outbound HND
    q = create_query(
        flights=[
            FlightQuery(date="2026-11-07", from_airport="ICN", to_airport="HND")
        ],
        trip="one-way",
        seat="economy",
        passengers=Passengers(adults=4),
        language="ko",
        currency="KRW",
        max_stops=0,
    )
    html = fetch_flights_html(q)
    (DATA / "hnd_out_all.html").write_text(html, encoding="utf-8")
    rows = parse(html, 50_000)
    (DATA / "hnd_out_all.json").write_text(
        json.dumps(rows[:40], ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print("out_all", len(rows))
    for r in rows[:30]:
        print(r)

    rt = parse((DATA / "hnd_rt.html").read_text(encoding="utf-8"), 200_000)
    print("rt", len(rt))
    for r in rt:
        print(r)


if __name__ == "__main__":
    main()
