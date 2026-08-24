"""Map Google Flights 4-adult offers to airline + schedule."""
from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
html = (ROOT / "data" / "google_raw_4p.html").read_text(encoding="utf-8", errors="ignore")

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
]


def norm_time(t: str) -> str:
    h, m = t.split(":")
    return f"{int(h):02d}:{m}"


offers = []
for m in re.finditer(r'aria-label="(\d+) 대한민국 원"', html):
    price = int(m.group(1))
    if not (1_000_000 <= price <= 5_000_000):
        continue
    # Prefer looking AFTER the price label for list card content too
    before = html[max(0, m.start() - 6000) : m.start()]
    after = html[m.start() : m.start() + 2500]
    window = before[-3500:] + after

    airline = None
    pos = -1
    for a in AIRLINES:
        for chunk in (before, after, window):
            i = chunk.rfind(a) if chunk is before else chunk.find(a)
            # use last occurrence in before
            j = before.rfind(a)
            if j > pos:
                pos = j
                airline = a

    # times near price: look in a tighter window around price
    tight = html[max(0, m.start() - 2500) : m.start() + 1200]
    times = [norm_time(t) for t in re.findall(r"(?<!\d)(\d{1,2}:\d{2})(?!\d)", tight)]
    # de-dupe preserve order
    seen = set()
    uniq_times = []
    for t in times:
        if t not in seen:
            seen.add(t)
            uniq_times.append(t)

    offers.append(
        {
            "price_total_4": price,
            "price_per_person": round(price / 4),
            "airline": airline,
            "times": uniq_times[:8],
        }
    )

# collapse identical price+airline keeping richest times
merged: dict[tuple, dict] = {}
for o in offers:
    key = (o["price_total_4"], o["airline"])
    if key not in merged or len(o["times"]) > len(merged[key]["times"]):
        merged[key] = o

result = sorted(merged.values(), key=lambda x: x["price_total_4"])
path = ROOT / "data" / "parsed_4p.json"
path.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print(f"wrote {len(result)} offers -> {path}")
