"""Merge RT prices + OW schedules into flights.json (4 adults, ICN-NRT)."""
from __future__ import annotations

import json
import re
from datetime import datetime, timedelta, timezone
from pathlib import Path

from fast_flights import FlightQuery, Passengers, create_query, fetch_flights_html

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"
FLIGHTS = DATA / "flights.json"
KST = timezone(timedelta(hours=9))

AIRLINES = [
    "제주항공", "진에어", "티웨이항공", "이스타항공", "파라타항공",
    "에어부산", "에어프레미아", "아시아나항공", "대한항공", "피치항공",
    "집에어", "에어서울",
]

GOOGLE_RT = (
    "https://www.google.com/travel/flights?hl=ko&curr=KRW"
    "#flt=ICN.NRT.2026-11-07*NRT.ICN.2026-11-10;c:KRW;e:1;px:4;s:0;sd:1;t:f"
)
NAVER_RT = (
    "https://flight.naver.com/flights/international/"
    "ICN-NRT-20261107/NRT-ICN-20261110?adult=4&fareType=Y&isDirect=true"
)


def mins(t: str) -> int:
    h, m = map(int, t.split(":"))
    return h * 60 + m


def norm(t: str) -> str:
    h, m = t.split(":")
    return f"{int(h):02d}:{m}"


def parse_ow(html: str) -> list[dict]:
    rows = []
    for m in re.finditer(r'aria-label="(\d+) 대한민국 원"', html):
        price = int(m.group(1))
        if price < 50_000:
            continue
        before = html[max(0, m.start() - 8000) : m.start()]
        after = html[m.start() : m.start() + 800]
        airline = None
        pos = -1
        for a in AIRLINES:
            j = before.rfind(a)
            if j > pos:
                pos, airline = j, a
        times: list[str] = []
        for t in re.findall(r"(?<!\d)(\d{1,2}:\d{2})(?!\d)", before[-2000:] + after):
            tt = norm(t)
            if tt not in times:
                times.append(tt)
        rows.append({"airline": airline, "price": price, "times": times})
    seen: set[tuple] = set()
    out = []
    for r in rows:
        key = (r["airline"], tuple(r["times"][:2]), r["price"])
        if key in seen:
            continue
        seen.add(key)
        out.append(r)
    return sorted(out, key=lambda x: x["price"])


def parse_rt(html: str) -> list[dict]:
    offers = []
    for m in re.finditer(r'aria-label="(\d+) 대한민국 원"', html):
        price = int(m.group(1))
        if not (1_000_000 <= price <= 3_500_000):
            continue
        before = html[max(0, m.start() - 12000) : m.start()]
        window = before + html[m.start() : m.start() + 3000]
        airline = None
        pos = -1
        for a in AIRLINES:
            j = before.rfind(a)
            if j > pos:
                pos, airline = j, a
        times: list[str] = []
        for t in re.findall(r"(?<!\d)(\d{1,2}:\d{2})(?!\d)", window[-5000:]):
            tt = norm(t)
            if tt not in times:
                times.append(tt)
        offers.append({"price_krw": price, "airline": airline, "times": times})
    best: dict[int, dict] = {}
    for o in offers:
        prev = best.get(o["price_krw"])
        score = len(o["times"]) + (5 if o["airline"] else 0)
        if prev is None or score > len(prev["times"]) + (5 if prev["airline"] else 0):
            best[o["price_krw"]] = o
    return sorted(best.values(), key=lambda x: x["price_krw"])


def legs_from_times(times: list[str]) -> list[tuple[str, str]]:
    legs = []
    for i in range(0, len(times) - 1, 2):
        legs.append((times[0], times[1]) if i == 0 else (times[i], times[i + 1]))
    if len(times) >= 2:
        legs.append((times[0], times[1]))
    # dedupe
    seen = set()
    out = []
    for a, b in legs:
        if (a, b) not in seen:
            seen.add((a, b))
            out.append((a, b))
    return out


def out_ok(dep: str, arr: str) -> bool:
    return 6 <= int(dep.split(":")[0]) <= 12 and mins(arr) >= 12 * 60


def ret_ok(dep: str, arr: str) -> bool:
    dh = int(dep.split(":")[0])
    ah = int(arr.split(":")[0])
    # daytime return: depart 6–14, arrive same-ish day before 18:00
    if not (6 <= dh <= 14):
        return False
    if ah < 6 and dh >= 7:
        return False  # likely mis-parse overnight
    return mins(arr) <= 18 * 60 or ah >= dh


def index_ow(path: Path, outbound: bool) -> dict[str, list[tuple[str, str]]]:
    rows = json.loads(path.read_text(encoding="utf-8"))
    by_airline: dict[str, list[tuple[str, str]]] = {}
    for r in rows:
        al = r.get("airline")
        if not al:
            continue
        t = r.get("times") or []
        if len(t) < 2:
            continue
        dep, arr = t[0], t[1]
        ok = out_ok(dep, arr) if outbound else ret_ok(dep, arr)
        if ok:
            by_airline.setdefault(al, []).append((dep, arr))
    return by_airline


def pick_return(ret_map: dict[str, list[tuple[str, str]]], airline: str | None) -> tuple[str, str] | None:
    if not airline or airline not in ret_map:
        return None
    # prefer morning/midday
    opts = sorted(ret_map[airline], key=lambda x: mins(x[0]))
    for dep, arr in opts:
        if ret_ok(dep, arr):
            return dep, arr
    return opts[0] if opts else None


def pick_outbound(out_map: dict[str, list[tuple[str, str]]], airline: str | None) -> tuple[str, str] | None:
    if not airline or airline not in out_map:
        return None
    opts = [x for x in out_map[airline] if out_ok(x[0], x[1])]
    opts.sort(key=lambda x: (mins(x[0]), mins(x[1])))
    return opts[0] if opts else None


def card(
    price: int,
    airline: str,
    out_dep: str,
    out_arr: str,
    ret_dep: str,
    ret_arr: str,
    match: str,
    rank: int,
) -> dict:
    return {
        "rank": rank,
        "airport": "NRT",
        "match": match,
        "airline": airline,
        "out": {"dep": out_dep, "arr": out_arr, "from": "ICN", "to": "NRT"},
        "ret": {
            "dep": ret_dep,
            "arr": ret_arr,
            "from": "NRT",
            "to": "ICN",
            "airline": airline,
        },
        "price_krw": price,
        "price_per_person_krw": round(price / 4),
        "price_label": f"₩{price:,} (4인)",
        "price_pp_label": f"1인 약 ₩{round(price / 4):,}",
        "notes": "2026-08-26 Google Flights 스냅샷",
        "book_google": GOOGLE_RT,
        "book_naver": NAVER_RT,
        "available": True,
    }


def build_returns(ret_rows: list[dict]) -> list[dict]:
    out = []
    seen = set()
    for r in ret_rows:
        al = r.get("airline")
        t = r.get("times") or []
        if not al or len(t) < 2:
            continue
        dep, arr = t[0], t[1]
        if not ret_ok(dep, arr):
            continue
        key = (al, dep, arr)
        if key in seen:
            continue
        seen.add(key)
        out.append(
            {
                "airline": al,
                "dep": dep,
                "arr": arr,
                "from": "NRT",
                "to": "ICN",
                "ow_price_4": r["price"],
                "notes": "편도 4인 참고",
                "book_google": GOOGLE_RT,
                "book_naver": NAVER_RT,
            }
        )
    out.sort(key=lambda x: x["ow_price_4"])
    return out[:8]


def main() -> None:
    q_rt = create_query(
        flights=[
            FlightQuery(date="2026-11-07", from_airport="ICN", to_airport="NRT"),
            FlightQuery(date="2026-11-10", from_airport="NRT", to_airport="ICN"),
        ],
        trip="round-trip",
        seat="economy",
        passengers=Passengers(adults=4),
        language="ko",
        currency="KRW",
        max_stops=0,
    )
    html_rt = fetch_flights_html(q_rt)
    (DATA / "google_raw_4p.html").write_text(html_rt, encoding="utf-8")
    rt_offers = parse_rt(html_rt)
    (DATA / "rt_parse.json").write_text(
        json.dumps(rt_offers, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )

    q_out = create_query(
        flights=[
            FlightQuery(
                date="2026-11-07",
                from_airport="ICN",
                to_airport="NRT",
                earliest_departure_hour=6,
                latest_departure_hour=13,
            )
        ],
        trip="one-way",
        seat="economy",
        passengers=Passengers(adults=4),
        language="ko",
        currency="KRW",
        max_stops=0,
    )
    html_out = fetch_flights_html(q_out)
    out_rows = parse_ow(html_out)
    (DATA / "out_nov07.json").write_text(
        json.dumps(out_rows[:50], ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )

    q_ret = create_query(
        flights=[FlightQuery(date="2026-11-10", from_airport="NRT", to_airport="ICN")],
        trip="one-way",
        seat="economy",
        passengers=Passengers(adults=4),
        language="ko",
        currency="KRW",
        max_stops=0,
    )
    html_ret = fetch_flights_html(q_ret)
    ret_rows = parse_ow(html_ret)
    (DATA / "ret_nov10.json").write_text(
        json.dumps(ret_rows[:50], ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )

    out_map = index_ow(DATA / "out_nov07.json", outbound=True)
    ret_map = index_ow(DATA / "ret_nov10.json", outbound=False)

    recommended: list[dict] = []
    also: list[dict] = []
    used = set()

    for o in rt_offers:
        al = o["airline"] or "항공사"
        price = o["price_krw"]
        ob = pick_outbound(out_map, o["airline"])
        rb = pick_return(ret_map, o["airline"])
        if not ob or not rb:
            continue
        out_dep, out_arr = ob
        ret_dep, ret_arr = rb
        key = (al, out_dep, out_arr, ret_dep, ret_arr)
        if key in used:
            continue
        used.add(key)
        c = card(price, al, out_dep, out_arr, ret_dep, ret_arr, "아침 출발·점심 이후 도착", 0)
        recommended.append(c)

    recommended.sort(key=lambda x: x["price_krw"])
    for i, c in enumerate(recommended, 1):
        c["rank"] = i

    # alt: RT offers without filter or different times
    for o in rt_offers:
        al = o["airline"] or "항공사"
        t = o.get("times") or []
        if len(t) < 2:
            continue
        out_dep, out_arr = t[0], t[1]
        ret_dep, ret_arr = (t[2], t[3]) if len(t) >= 4 else ("—", "—")
        if out_ok(out_dep, out_arr):
            continue
        key = (al, out_dep, out_arr, o["price_krw"])
        if any(
            x["airline"] == al and x["price_krw"] == o["price_krw"] for x in recommended
        ):
            continue
        rb = pick_return(ret_map, o["airline"])
        if rb:
            ret_dep, ret_arr = rb
        also.append(
            card(
                o["price_krw"],
                al,
                out_dep,
                out_arr,
                ret_dep,
                ret_arr,
                "조건 완화 / 참고",
                0,
            )
        )

    also.sort(key=lambda x: x["price_krw"])
    for i, c in enumerate(also[:6], 1):
        c["rank"] = i

    prices = [o["price_krw"] for o in rt_offers]
    data = json.loads(FLIGHTS.read_text(encoding="utf-8"))
    now = datetime.now(KST).isoformat(timespec="seconds")
    data["queried_at"] = now
    data["source"] = f"Google Flights · 성인 4명 · NRT · {now[:10]}"
    nrt = data["airports"]["NRT"]
    nrt["recommended"] = recommended[:6]
    nrt["also_consider"] = also[:6]
    nrt["return_options"] = build_returns(ret_rows)
    nrt["market_summary"] = {
        "route_min_krw_total4": min(prices) if prices else 0,
        "route_max_krw_total4": max(prices) if prices else 0,
        "best_match_krw": recommended[0]["price_krw"] if recommended else 0,
        "note": (
            f"직항 {len(rt_offers)}건 · 조건맞춤 {len(recommended)}건 "
            f"(조회 {now[:16].replace('T', ' ')})"
        ),
    }
    data["links"] = {"google_nrt_4p": GOOGLE_RT, "naver_nrt_4p": NAVER_RT}
    FLIGHTS.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"OK rt={len(rt_offers)} rec={len(recommended)} ret_opts={len(nrt['return_options'])}")


if __name__ == "__main__":
    main()
