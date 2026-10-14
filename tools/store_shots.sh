#!/bin/zsh
# Capture App Store screenshots on the required device sizes.
# Each shot is a separate debug build opened on one screen via --dart-define.
set -e
cd "${0:A:h}/.."
OUT=${1:-build/storeshots}; mkdir -p $OUT
PHONE=AD39AD7B-31C0-4422-99FD-7B7D704F2C2F   # iPhone 18 Pro Max (6.9")
PAD=FE4E3EAF-1390-4124-AFCA-E13000F4042A     # iPad Pro 13" (M5)
for d in $PHONE $PAD; do
  xcrun simctl boot $d 2>/dev/null || true
  xcrun simctl status_bar $d override --time "9:41" --batteryState charged --batteryLevel 100 --wifiBars 3 --cellularBars 4
done
shots=(
  "01_home|--dart-define=KOI_TAB=0"
  "02_kohaku|--dart-define=KOI_ROUTE=variety:kohaku"
  "03_identify|--dart-define=KOI_TAB=1"
  "04_history|--dart-define=KOI_ROUTE=chapter:8"
  "05_prices|--dart-define=KOI_TAB=3"
  "06_feeding|--dart-define=KOI_ROUTE=feeding"
  "07_bm|--dart-define=KOI_ROUTE=bm"
)
for s in $shots; do
  name=${s%%|*}; def=${s#*|}
  flutter build ios --simulator --debug $def >/dev/null
  for d in $PHONE $PAD; do
    xcrun simctl install $d build/ios/iphonesimulator/Runner.app
    xcrun simctl terminate $d nyc.jelia.koiknife 2>/dev/null || true
    xcrun simctl launch $d nyc.jelia.koiknife >/dev/null
  done
  sleep 9   # let images decode and the pond fish spread out
  xcrun simctl io $PHONE screenshot $OUT/iphone_$name.png >/dev/null
  xcrun simctl io $PAD screenshot $OUT/ipad_$name.png >/dev/null
  echo "shot $name"
done
