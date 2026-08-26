"""Check Airbnb room availability for trip dates via browser-exported JSON.
This file is filled by agent browser checks; then prune stays.json.
"""
from __future__ import annotations

import json
from datetime import datetime, timedelta, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
STAYS = ROOT / "data" / "stays.json"
CHECK = ROOT / "data" / "avail_check.json"
KST = timezone(timedelta(hours=9))


def room_id_from_url(url: str) -> str:
    return url.split("/rooms/")[1].split("?")[0]


def main() -> None:
    checks = {c["id"]: c for c in json.loads(CHECK.read_text(encoding="utf-8"))}
    data = json.loads(STAYS.read_text(encoding="utf-8"))
    now = datetime.now(KST).isoformat(timespec="seconds")
    removed: list[str] = []
    featured: list[dict] = []

    for area in data["areas"]:
        kept = []
        for p in area.get("airbnb_picks") or []:
            rid = room_id_from_url(p["url"])
            c = checks.get(rid)
            if not c or c.get("unavail") or not c.get("bookable"):
                removed.append(f"{area['name']}: {p['name']} ({rid})")
                continue
            if c.get("total"):
                total = int(c["total"])
                p["price_krw_total"] = total
                p["price_label"] = f"₩{total:,} (3박·4인·총액)"
                p["price_per_night_krw"] = round(total / 3)
            p["available"] = True
            p["checked_at"] = now
            kept.append(p)
            featured.append({**p, "area": area["name"]})
        area["airbnb_picks"] = kept

    featured.sort(key=lambda x: (-x["rating"], x["price_krw_total"]))
    data["featured_airbnb"] = featured[:8]
    data["queried_at"] = now
    data["airbnb_note"] = (
        "예약 가능(총액·예약하기 확인) 숙소만 표시. "
        f"3박·4인·11/7–11/10 · ₩60–100만 총액 (검증 {now[:16].replace('T', ' ')})."
    )
    STAYS.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"kept={len(featured)} removed={len(removed)}")
    for r in removed:
        print("REMOVED", r)


if __name__ == "__main__":
    main()
