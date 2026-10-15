# KoiKnife 1.0.2 — The Swiss Army Knife of Koi Knowledge

Koi field guide, history, price guide and pond-care toolkit, presented with
B&M Aquatics (Hamburg, NJ). One Flutter codebase → iPhone, iPad, Mac, Android.
iPhone is the primary target.

- Content source of truth: `content/*.json` (copied to `assets/data/` at build)
- Text derived from aquatics.jelia.nyc (koi guide, koihistory, products, services, resources)
- Photos: Wikimedia Commons (licences verified against the Commons API 2026-10-14) + B&M's own
- Icon: J's brand logo `assets/brand/koiknife-logo-1024.png` → `python3 tools/apply_logo.py` writes every icon (iOS/iPadOS, macOS, Android incl. adaptive) and the in-app header logo. It is the only icon generator.

## Run
    flutter test                              # every screen at iPhone + iPad sizes
    flutter run -d <simulator>                # --dart-define=KOI_TAB=n opens on tab n
    flutter build ipa                         # App Store / TestFlight

Bundle ID `nyc.jelia.koiknife` (registered, UNIVERSAL). Team 46AXDWA6F8.
