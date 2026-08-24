from pathlib import Path
import re
import json

html = Path(__file__).resolve().parents[1].joinpath(
    "data", "google_raw_4p.html"
).read_text(encoding="utf-8")

# Rebuild price->times from earlier reliable method
price_times = {}
for m in re.finditer("\u20a9\\s*([\\d,]{6,})", html):
    price = int(m.group(1).replace(",", ""))
    if not (1_000_000 <= price <= 5_000_000):
        continue
    window = html[max(0, m.start() - 2500) : m.start() + 200]
    times = re.findall(r"(?<!\d)(\d{1,2}:\d{2})(?!\d)", window)
    norm = []
    for t in times:
        h, mi = t.split(":")
        tt = f"{int(h):02d}:{mi}"
        if tt not in norm:
            norm.append(tt)
    if price not in price_times or len(norm) > len(price_times[price]):
        price_times[price] = norm

airlines = {
    1549848: "피치항공",
    1623448: "에어프레미아",
    1695448: "제주항공",
    1727048: "에어부산",
    1775448: "제주항공",
    1800647: "티웨이항공",
    1880647: "티웨이항공",
    1992648: "에어서울",
    1994247: "진에어",
    2153047: "아시아나항공",
    2425847: "아시아나항공",
}

# Known outbound mappings from time proximity (Google snapshot)
schedule_hints = {
    1549848: {"out_dep": "12:40", "out_arr": "15:15", "note": "오후 출발"},
    1623448: {"out_dep": "08:45", "out_arr": "11:20", "note": "아침 도착(점심 전)"},
    1695448: {
        "variants": [
            {"out_dep": "09:50", "out_arr": "12:15"},
            {"out_dep": "10:25", "out_arr": "12:50"},
            {"out_dep": "08:10", "out_arr": "10:35"},
        ]
    },
    1727048: {"out_dep": "07:35", "out_arr": "10:15", "note": "아침 도착"},
    1775448: {"out_dep": "11:30", "out_arr": "14:10"},
    1800647: {"out_dep": "10:20", "out_arr": "12:50"},
    1880647: {"out_dep": "08:35", "out_arr": "10:55", "note": "아침 도착"},
    1992648: {"out_dep": "09:20", "out_arr": "11:50", "note": "점심 직전"},
    1994247: {"out_dep": "07:30", "out_arr": "09:55", "note": "아침 도착"},
    2153047: {"out_dep": "09:00", "out_arr": "11:20", "note": "점심 전"},
}

rows = []
for price, airline in airlines.items():
    rows.append(
        {
            "airline": airline,
            "price_total_4": price,
            "price_per_person": round(price / 4),
            "times_near_price": price_times.get(price, []),
            "hint": schedule_hints.get(price),
        }
    )

out = Path(__file__).resolve().parents[1] / "data" / "offer_map_4p.json"
out.write_text(json.dumps(rows, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print("wrote", out)
