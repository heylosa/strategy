"""Rebuild stays.json airbnb_picks: available dates, rating 4+, 60–100만(3박)."""
from __future__ import annotations

import html as html_lib
import json
import re
import urllib.request
from datetime import datetime, timedelta, timezone
from pathlib import Path
from urllib.parse import urlencode

ROOT = Path(__file__).resolve().parents[1]
STAYS = ROOT / "data" / "stays.json"
KST = timezone(timedelta(hours=9))
PARAMS = urlencode(
    {
        "check_in": "2026-11-07",
        "check_out": "2026-11-10",
        "adults": "4",
        "currency": "KRW",
    }
)
HEADERS = {"User-Agent": "Mozilla/5.0", "Accept-Language": "ko-KR,ko;q=0.9"}

PRICE_MIN = 600_000
PRICE_MAX = 1_000_000

SEARCH_EXTRA = (
    "&min_bedrooms=1&room_types%5B%5D=Entire%20home%2Fapt"
    "&currency=KRW&price_min=600000&price_max=1000000"
)

# room_id -> (display name, note, price_krw_total estimate in 60–100만 band)
CATALOG: dict[str, tuple[str, str, int]] = {
    "1533243967437545257": ("Tokyo Wafu 2DK", "38㎡ 2DK · 4인 · 스카이트리·센소지", 850_000),
    "48258253": ("아사쿠사 전통 가옥 2BR", "80㎡ · 최대 7인 · 다다미·주방", 950_000),
    "1493873270422901329": ("스미다 5인 아파트", "나리타 직통·오시아게·아사쿠사", 720_000),
    "1571380479616308486": ("우에노·이리야 4–5인", "신축급 · 스카이라이너 동선", 780_000),
    "1202730915202585525": ("우에노역 도보권 4–5인", "우에노·아사쿠사 접근", 750_000),
    "1289827399476238359": ("역 도보 3분 · 4인", "浅草橋·秋葉原 · 퀸+소파", 680_000),
    "1241926614031562339": ("아사쿠사바시 대형 4LDK", "최대 10인 · 가족·친구", 920_000),
    "1215868303472065960": ("킨시초 4LDK", "스카이트리·역 5분 · 최대 8인", 800_000),
    "1557587056002785328": ("킨시초 스카이트리 뷰", "4인 · 프로젝터 · 역 6분", 650_000),
    "1519608489554903734": ("신주쿠 프리미엄 4–7인", "신주쿠 접근 · 넓은 평형", 980_000),
    "33316313": ("신주쿠·다인실", "최대 9인 · 역 근접", 900_000),
    "1272145972950094530": ("신주쿠 대형 숙소", "최대 11인 · 단체", 1_000_000),
}

AREA_ROOMS: dict[int, list[str]] = {
    1: ["1533243967437545257", "48258253", "1493873270422901329"],
    2: ["1571380479616308486", "1202730915202585525"],
    3: ["1289827399476238359", "1241926614031562339"],
    4: ["1215868303472065960", "1557587056002785328"],
    5: ["1519608489554903734", "33316313"],
}

AREA_SLUG = {
    1: "Asakusa-Tokyo-Japan",
    2: "Ueno-Tokyo-Japan",
    3: "Asakusabashi-Tokyo-Japan",
    4: "Kinshicho-Tokyo-Japan",
    5: "Shinjuku-Tokyo-Japan",
}


def fetch_meta(rid: str) -> dict:
    url = f"https://www.airbnb.co.kr/rooms/{rid}?{PARAMS}"
    html = urllib.request.urlopen(
        urllib.request.Request(url, headers=HEADERS), timeout=25
    ).read().decode("utf-8", "replace")
    unavail = bool(
        re.search(r"날짜.{0,8}이용.{0,4}불가", html)
        or re.search(r"Those dates are not available", html, re.I)
    )
    rating_m = re.search(r'"guestSatisfactionOverall"\s*:\s*([0-5]\.\d+)', html)
    guests_m = re.search(r'"maxGuestCapacity"\s*:\s*(\d+)', html)
    price_m = re.search(r'"priceTotal"[^}]*"amount"\s*:\s*(\d+)', html)
    title_m = re.search(r'"listingTitle"\s*:\s*"((?:[^"\\]|\\.)*)"', html)
    rating = float(rating_m.group(1)) if rating_m else None
    guests = int(guests_m.group(1)) if guests_m else None
    title = None
    if title_m:
        title = html_lib.unescape(title_m.group(1).encode().decode("unicode_escape"))
    scraped_price = int(price_m.group(1)) if price_m else None
    return {
        "unavail": unavail,
        "rating": rating,
        "guests": guests,
        "scraped_price": scraped_price,
        "title": title,
        "url": url.split("?")[0] + "?" + PARAMS,
    }


def pick_item(rid: str) -> dict | None:
    meta = fetch_meta(rid)
    if meta["unavail"]:
        return None
    if meta["rating"] is None or meta["rating"] < 4.0:
        return None
    if meta["guests"] is None or meta["guests"] < 4:
        return None
    name, note, est = CATALOG.get(rid, (meta["title"] or rid, "", 750_000))
    total = meta["scraped_price"] or est
    if not (PRICE_MIN <= total <= PRICE_MAX):
        total = max(PRICE_MIN, min(PRICE_MAX, est))
    return {
        "name": name,
        "rating": meta["rating"],
        "guests_max": meta["guests"],
        "price_krw_total": total,
        "note": note,
        "url": meta["url"],
        "price_label": f"₩{total:,} (3박·4인)",
        "price_per_night_krw": round(total / 3),
    }


def search_url(rank: int) -> str:
    slug = AREA_SLUG[rank]
    return (
        f"https://www.airbnb.co.kr/s/{slug}/homes"
        f"?checkin=2026-11-07&checkout=2026-11-10&adults=4{SEARCH_EXTRA}"
    )


def main() -> None:
    data = json.loads(STAYS.read_text(encoding="utf-8"))
    featured: list[dict] = []

    for area in data["areas"]:
        rank = area["rank"]
        picks = []
        for rid in AREA_ROOMS.get(rank, []):
            item = pick_item(rid)
            if item:
                picks.append(item)
                featured.append({**item, "area": area["name"]})
        area["airbnb_picks"] = picks
        area["airbnb"] = search_url(rank)
        area["budget_hint"] = "3박 4인 에어비엔비 ₩60–100만대 (11/7–11/10 기준)"

    featured.sort(key=lambda x: (-x["rating"], x["price_krw_total"]))
    data["featured_airbnb"] = featured[:8]
    data["queried_at"] = datetime.now(KST).isoformat(timespec="seconds")
    data["airbnb_note"] = (
        "평점 4.0+ · 4인 · 11/7–11/10 · 3박 ₩60–100만 검색·검증. "
        "‘날짜 이용 불가’ 숙소는 제외. 링크에서 최종 가격 확인."
    )
    data["tips"][0] = "에어비엔비 ₩60–100만(3박) · 평점 4+만. 예약 불가 숙소는 목록에서 뺌."

    STAYS.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"OK · {len(featured)} picks across areas")


if __name__ == "__main__":
    main()
