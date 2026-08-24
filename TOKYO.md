# Tokyo flights (2026-11-07 ~ 11-10)

Added `tokyo.html` + `data/flights.json` for morning-depart / after-lunch-arrive
ICN↔NRT round-trip options with live Naver snapshot prices.

## SSL / Git

Corporate HTTPS MITM: issuer `ePrism SSL, O=SOOSAN INT, C=KR`.
Use SSH remote only: `git@github.com:heylosa/strategy.git`.

## Update loop

1. Re-check Naver / Google for dates
2. Edit `data/flights.json`
3. `git add` / commit / `git push origin main` (SSH)
4. Pages: `https://heylosa.github.io/strategy/tokyo.html`
