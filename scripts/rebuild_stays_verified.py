"""Rebuild stays.json — single-unit listings only; prices marked as snapshot.

Multi-unit (호텔형·아파트 선택) listings are excluded: search card totals
often differ from the unit the detail page shows.
"""
from __future__ import annotations

import json
from datetime import datetime, timedelta, timezone
from pathlib import Path
from urllib.parse import urlencode

ROOT = Path(__file__).resolve().parents[1]
STAYS = ROOT / "data" / "stays.json"
KST = timezone(timedelta(hours=9))
NOW = datetime.now(KST).isoformat(timespec="seconds")
Q = urlencode(
    {
        "check_in": "2026-11-07",
        "check_out": "2026-11-10",
        "adults": "4",
        "currency": "KRW",
    }
)

SEARCH_EXTRA = (
    "&min_bedrooms=1&room_types%5B%5D=Entire%20home%2Fapt"
    "&currency=KRW&price_min=180000&price_max=350000"
)

# Single-unit only. total = last browser 총액 snapshot (may differ on your account).
VERIFIED: dict[int, list[dict]] = {
    1: [
        {
            "id": "1354840124363109612",
            "name": "아사쿠사역 · 센소지 8분",
            "rating": 4.87,
            "note": "잇슈쿠-아사쿠사 · 센소지 8분",
            "total": 897786,
        },
        {
            "id": "1637723331148618007",
            "name": "유니토 레지던스 아사쿠사",
            "rating": 4.86,
            "note": "혼조-아즈마바시 · 아사쿠사 도보",
            "total": 848658,
        },
        {
            "id": "1299900641572294659",
            "name": "오시아게 10분 · 키토하나 401",
            "rating": 4.87,
            "note": "30㎡ · 침대 3 · 2024 개장",
            "total": 699825,
        },
    ],
    2: [
        {
            "id": "1497534322551548783",
            "name": "르루미에르 료고쿠",
            "rating": 4.91,
            "note": "최대 4인 · 료고쿠",
            "total": 760681,
        },
        {
            "id": "1617040285392787399",
            "name": "헤밍 아파트 · 아키하바라 900m",
            "rating": 4.89,
            "note": "아키하바라·우에노·아사쿠사 접근",
            "total": 775128,
        },
    ],
    3: [
        {
            "id": "51217211",
            "name": "아키하바라·아사쿠사 501",
            "rating": 4.84,
            "note": "최상층 1층 전체 · 초고속 Wi-Fi",
            "total": 787863,
        },
    ],
    4: [
        {
            "id": "1186565071649771622",
            "name": "35㎡ · 스카이트리 직통",
            "rating": 4.89,
            "note": "NRT/HND/디즈니 직통 · 욕실 건조기",
            "total": 710033,
        },
        {
            "id": "1436204794436667774",
            "name": "역 근처 아파트 · 긴시초",
            "rating": 4.95,
            "note": "★ 4.95 · 역 도보",
            "total": 966254,
        },
        {
            "id": "1485157050326019894",
            "name": "네스테이 · 스카이트리",
            "rating": 4.82,
            "note": "스카이트리 인근",
            "total": 906469,
        },
    ],
    5: [
        {
            "id": "1521036993938688598",
            "name": "unito 신주쿠 와카마츠",
            "rating": 4.81,
            "note": "와카마츠역 도보 5분",
            "total": 768356,
        },
    ],
}

AREA_SLUG = {
    1: "Asakusa-Tokyo-Japan",
    2: "Ueno-Tokyo-Japan",
    3: "Asakusabashi-Tokyo-Japan",
    4: "Kinshicho-Tokyo-Japan",
    5: "Shinjuku-Tokyo-Japan",
}


def room_url(rid: str) -> str:
    return f"https://www.airbnb.co.kr/rooms/{rid}?{Q}"


def pick(row: dict) -> dict:
    total = int(row["total"])
    return {
        "name": row["name"],
        "rating": row["rating"],
        "guests_max": 4,
        "price_krw_total": total,
        "note": row["note"],
        "url": room_url(row["id"]),
        "price_label": f"참고 ₩{total:,} · 링크에서 확인",
        "price_per_night_krw": round(total / 3),
        "available": True,
        "price_source": "snapshot_may_differ",
        "checked_at": NOW,
    }


def search_url(rank: int) -> str:
    return (
        f"https://www.airbnb.co.kr/s/{AREA_SLUG[rank]}/homes"
        f"?checkin=2026-11-07&checkout=2026-11-10&adults=4{SEARCH_EXTRA}"
    )


def main() -> None:
    data = json.loads(STAYS.read_text(encoding="utf-8"))
    featured: list[dict] = []

    for area in data["areas"]:
        rank = area["rank"]
        picks = [pick(r) for r in VERIFIED.get(rank, [])]
        area["airbnb_picks"] = picks
        area["airbnb"] = search_url(rank)
        area["budget_hint"] = (
            "목표 3박 총액 ₩60–100만. 화면에 적은 금액은 참고용 — 최종은 링크."
        )
        for p in picks:
            featured.append({**p, "area": area["name"]})

    featured.sort(key=lambda x: (-x["rating"], x["price_krw_total"]))
    data["featured_airbnb"] = featured[:8]
    data["queried_at"] = NOW
    data["airbnb_note"] = (
        "가격은 스냅샷 참고값입니다. 에어비엔비는 계정·쿠키·객실 선택에 따라 "
        "총액이 다르게 보일 수 있습니다. 호텔형(아파트 여러 개) 리스팅은 제외했습니다. "
        f"최종 금액은 반드시 링크에서 확인 ({NOW[:16].replace('T', ' ')})."
    )
    data["tips"][0] = (
        "숙소 가격 = 링크 총액이 정답. 페이지 숫자는 참고 스냅샷일 뿐."
    )

    STAYS.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"OK · {len(featured)} single-unit picks · {NOW}")


if __name__ == "__main__":
    main()
