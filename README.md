# KoiKnife 1.0.0 — The Swiss Army Knife of Koi Knowledge

Koi field guide, history, price guide and pond-care toolkit, presented with
B&M Aquatics (Hamburg, NJ). One Flutter codebase → iPhone, iPad, Mac, Android.
iPhone is the primary target.

- Content source of truth: `content/*.json` (copied to `assets/data/` at build)
- Text derived from aquatics.jelia.nyc (koi guide, koihistory, products, services, resources)
- Photos: Wikimedia Commons (licences verified against the Commons API 2026-10-14) + B&M's own
- Icon: `tools/make_icon.py` → `assets/icon/icon.png` → `dart run flutter_launcher_icons`

## Run
    flutter test                              # every screen at iPhone + iPad sizes
    flutter run -d <simulator>                # --dart-define=KOI_TAB=n opens on tab n
    flutter build ipa                         # App Store / TestFlight

Bundle ID `nyc.jelia.koiknife` (registered, UNIVERSAL). Team 46AXDWA6F8.
