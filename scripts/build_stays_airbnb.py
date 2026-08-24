"""Merge verified Airbnb picks (rating>=4, 4 guests) into stays.json."""
from __future__ import annotations

import json
import re
from datetime import datetime, timedelta, timezone
from pathlib import Path
from urllib.parse import urlencode

ROOT = Path(__file__).resolve().parents[1]
STAYS = ROOT / "data" / "stays.json"
KST = timezone(timedelta(hours=9))

QUERY = urlencode(
    {
        "check_in": "2026-11-07",
        "check_out": "2026-11-10",
        "adults": "4",
        "currency": "KRW",
    }
)

# rating from scripts/fetch_airbnb.py (2026-08-24). price_krw_total = 3-night reference
# from area budget bands; confirm on Airbnb before booking.
PICKS: dict[int, list[dict]] = {
    1: [
        {
            "name": "Tokyo Wafu 2DK · 아사쿠사",
            "rating": 4.92,
            "guests_max": 4,
            "price_krw_total": 468000,
            "note": "38㎡ 2DK · 4인 · 스카이트리·센소지 도보권",
            "room_id": "1533243967437545257",
        },
        {
            "name": "스미다강·스카이트리 뷰 (구라마에)",
            "rating": 4.81,
            "guests_max": 4,
            "price_krw_total": 385000,
            "note": "아사쿠사역 9분·구라마에 4분",
            "room_id": "41419635",
        },
        {
            "name": "오시아게·스카이트리 4인",
            "rating": 4.67,
            "guests_max": 4,
            "price_krw_total": 320000,
            "note": "오시아게역 4분 · 넷플릭스",
            "room_id": "1509219974753168316",
        },
    ],
    2: [
        {
            "name": "SK401 · 우에노·이리야 신축",
            "rating": 5.0,
            "guests_max": 4,
            "price_krw_total": 495000,
            "note": "우에노 1정거장 · 스카이트리 뷰 · 엘리베이터",
            "room_id": "1687629257762259553",
        },
        {
            "name": "Max4 · 우에노·아키하바라 4인",
            "rating": 4.53,
            "guests_max": 4,
            "price_krw_total": 520000,
            "note": "유시마·오카치마치 도보 · Dyson",
            "room_id": "1698630136741897746",
        },
    ],
    3: [
        {
            "name": "역 도보 3분 · 4인 퀸+소파",
            "rating": 4.92,
            "guests_max": 4,
            "price_krw_total": 410000,
            "note": "浅草橋·秋葉原 접근 · 집 전체",
            "room_id": "1289827399476238359",
        },
        {
            "name": "Louis Stage · 동아사쿠사",
            "rating": 4.68,
            "guests_max": 4,
            "price_krw_total": 450000,
            "note": "센소지 도보 · 주방·세탁",
            "room_id": "1725085449270433615",
        },
    ],
    4: [
        {
            "name": "킨시초역·스카이트리 뷰",
            "rating": 4.5,
            "guests_max": 4,
            "price_krw_total": 340000,
            "note": "킨시초역 6분 · 프로젝터",
            "room_id": "1557587056002785328",
        },
    ],
    5: [
        {
            "name": "신주쿠 4분 · 4인 아파트",
            "rating": 4.84,
            "guests_max": 4,
            "price_krw_total": 580000,
            "note": "히가시신주쿠 4분 · 세탁건조",
            "room_id": "1730962067075190343",
        },
        {
            "name": "신주쿠 10분 · 프로젝터",
            "rating": 5.0,
            "guests_max": 4,
            "price_krw_total": 620000,
            "note": "2026 신축 · 낙산남 2분",
            "room_id": "1728838033573494122",
        },
    ],
}


def url(room_id: str) -> str:
    return f"https://www.airbnb.co.kr/rooms/{room_id}?{QUERY}"


def label(krw: int) -> str:
    return f"₩{krw:,}"


def main() -> None:
    data = json.loads(STAYS.read_text(encoding="utf-8"))
    featured: list[dict] = []

    for area in data["areas"]:
        rank = area["rank"]
        picks = []
        for p in PICKS.get(rank, []):
            if p["rating"] < 4.0:
                continue
            item = {
                **p,
                "url": url(p["room_id"]),
                "price_label": f"{label(p['price_krw_total'])} (3박·4인)",
                "price_per_night_krw": round(p["price_krw_total"] / 3),
            }
            item.pop("room_id", None)
            picks.append(item)
            featured.append({**item, "area": area["name"]})
        area["airbnb_picks"] = picks
        area["examples"] = []

    featured.sort(key=lambda x: (-x["rating"], x["price_krw_total"]))
    data["featured_airbnb"] = featured[:8]
    data["queried_at"] = datetime.now(KST).isoformat(timespec="seconds")
    data["airbnb_note"] = (
        "평점 4.0+ · 4인 · 11/7–11/10(3박) 기준. "
        "가격은 권역·시즌 참고가(자동 조회 불가)이며 링크에서 최종 확인."
    )
    data["tips"][0] = "에어비엔비 추천은 평점 4+만 표시. 카드·지도 팝업에서 링크 탭."

    STAYS.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Updated {STAYS} · {len(featured)} featured picks")


if __name__ == "__main__":
    main()
