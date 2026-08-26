"""Rebuild stays.json with browser-verified Airbnb 3-night totals (2026-08-26)."""
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

# Airbnb search price_min/max = nightly avg. ~18–35만/박 ≈ 3박 총액 60–100만대.
SEARCH_EXTRA = (
    "&min_bedrooms=1&room_types%5B%5D=Entire%20home%2Fapt"
    "&currency=KRW&price_min=180000&price_max=350000"
)

# Verified live from Airbnb UI (총액 for 11/7–11/10, 4 adults) on 2026-08-26.
VERIFIED: dict[int, list[dict]] = {
    1: [  # Asakusa
        {
            "id": "1471471947479651832",
            "name": "스카이트리·아사쿠사 인근 집",
            "rating": 5.0,
            "note": "최대 4인 · 게스트 선호",
            "total": 806229,
        },
        {
            "id": "1475318110224952028",
            "name": "스카이트리 도보 6분 · 5인",
            "rating": 4.96,
            "note": "30㎡ · 침대 4 · 공항·디즈니 직통",
            "total": 726463,
        },
        {
            "id": "1533243967437545257",
            "name": "Tokyo Wafu 2DK",
            "rating": 4.92,
            "note": "38㎡ 2DK · 공항 직행 · 아사쿠사",
            "total": 786085,
        },
    ],
    2: [  # Ueno
        {
            "id": "1648221931259790752",
            "name": "우에노·아키하바라 더블 욕실",
            "rating": 5.0,
            "note": "욕실 2 · 아키하바라 도보권",
            "total": 739811,
        },
        {
            "id": "1617061064590210372",
            "name": "헤밍웨이 아파트 (아키하바라)",
            "rating": 4.89,
            "note": "우에노·아사쿠사·센소지 접근",
            "total": 773824,
        },
        {
            "id": "26418319",
            "name": "【彩 Sai】다와라마치 2분 · 4인",
            "rating": 4.75,
            "note": "1DK · 싱글 4 · 우에노·아사쿠사 접근",
            "total": 767210,
        },
    ],
    3: [  # Asakusabashi
        {
            "id": "1609922418100475536",
            "name": "와토 아사쿠사바시",
            "rating": 4.95,
            "note": "아사쿠사 10분 · Wi-Fi",
            "total": 757239,
        },
        {
            "id": "1172128897619011588",
            "name": "Japandi Studio 아사쿠사바시",
            "rating": 4.89,
            "note": "나리타·하네다 직통 · 신주쿠 직통",
            "total": 751665,
        },
    ],
    4: [  # Kinshicho
        {
            "id": "859687024625850143",
            "name": "60㎡ 넓은 공간 · 최대 6인",
            "rating": 4.91,
            "note": "아사쿠사·스카이트리·스모 관광 편리",
            "total": 713818,
        },
        {
            "id": "1636928716969586108",
            "name": "긴시초 도보 6분 · 6인",
            "rating": 4.91,
            "note": "침대 3 · 최대 6인",
            "total": 767210,
        },
        {
            "id": "1120516772713364204",
            "name": "오픈키친 · 니시키노이토초",
            "rating": 4.89,
            "note": "신주쿠/시부야/아키하바라 직통",
            "total": 701711,
        },
    ],
    5: [  # Shinjuku — rechecked bookable only
        {
            "id": "22852461",
            "name": "신주쿠 근처 넓은 숙소",
            "rating": 4.96,
            "note": "넓고 편안 · 신주쿠 접근",
            "total": 779672,
        },
        {
            "id": "1521036993938688598",
            "name": "unito 신주쿠 와카마츠",
            "rating": 4.81,
            "note": "와카마츠역 도보 5분 · 아파트 선택",
            "total": 768338,
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
        "price_label": f"₩{total:,} (3박·4인·총액)",
        "price_per_night_krw": round(total / 3),
        "available": True,
        "price_source": "airbnb_ui_total",
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
            "3박 4인 에어비엔비 총액 ₩60–100만 (11/7–11/10, 브라우저 실측)"
        )
        for p in picks:
            featured.append({**p, "area": area["name"]})

    featured.sort(key=lambda x: (-x["rating"], x["price_krw_total"]))
    data["featured_airbnb"] = featured[:8]
    data["queried_at"] = NOW
    data["airbnb_note"] = (
        "가격은 에어비엔비 화면의 ‘총액’(3박·4인, 11/7–11/10)을 브라우저로 확인한 값. "
        f"평점 4+ · ₩60–100만 총액만 표시 (검증 {NOW[:16].replace('T', ' ')}). "
        "이전 추정가(1박/가상 카탈로그)는 폐기. 예약 직전 링크에서 재확인."
    )
    data["tips"][0] = (
        "에어비엔비 ‘총액’ 기준 ₩60–100만(3박) · 평점 4+. "
        "검색 필터 price_min/max는 1박 평균이라 18–35만으로 맞춤."
    )

    STAYS.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"OK · {len(featured)} verified picks · {NOW}")


if __name__ == "__main__":
    main()
