# KoiKnife 1.0.0 — The Swiss Army Knife of Koi Knowledge

## Get KoiKnife
- **iPhone & iPad:** App Store, https://apps.apple.com/app/id6822839703 (1.0.1 in review)
- **Android:** Google Play, https://play.google.com/store/apps/details?id=nyc.jelia.koiknife (1.0.1 in review)
- **Website:** https://koiknife.jelia.nyc · privacy: https://koiknife.jelia.nyc/privacy/ · support: koiknife@jelia.nyc

## Media and content licences
- **Code:** MIT (see LICENSE), © 2026 LIBCSYSTEMS LLC.
- **Koi photos and history images:** each keeps its own licence (CC BY / CC BY-SA / CC0 / public domain,
  mostly from Wikimedia Commons). The artist, licence and source page for every file are in
  `content/credits.json` and shown in the app's Credits screen; keep that attribution if you reuse them.
- **B&M Aquatics material** (`assets/bm/`, `content/bm.json`): © B&M Aquatics, Hamburg NJ, used with
  permission; not covered by the MIT licence.
- **KoiKnife name and logo:** © LIBCSYSTEMS LLC; not covered by the MIT licence.


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
