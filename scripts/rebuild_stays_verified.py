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
    2: [
        {
            "id": "1648221931259790752",
            "name": "우에노·아키하바라 더블 욕실",
            "rating": 5.0,
            "note": "욕실 2 · 아키하바라 도보권",
            "total": 739811,
        },
        {
            "id": "26418319",
            "name": "【彩 Sai】다와라마치 2분 · 4인",
            "rating": 4.75,
            "note": "1DK · 싱글 4 · 우에노·아사쿠사 접근",
            "total": 767210,
        },
    ],
    3: [
        {
            "id": "1172128897619011588",
            "name": "Japandi Studio 아사쿠사바시",
            "rating": 4.89,
            "note": "나리타·하네다 직통 · 신주쿠 직통",
            "total": 751665,
        },
    ],
    4: [
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
    5: [
        {
            "id": "22852461",
            "name": "신주쿠 근처 넓은 숙소",
            "rating": 4.96,
            "note": "넓고 편안 · 신주쿠 접근",
            "total": 779672,
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
