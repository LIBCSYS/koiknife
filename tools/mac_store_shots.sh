#!/bin/zsh
# Mac App Store screenshots, 2880x1800 (Apple's largest 16:10 Mac size), with no Screen Recording
# permission: each shot is a debug build that sizes its window to 1440x900 (KOI_WINDOW), opens on
# one screen (KOI_TAB / KOI_ROUTE), photographs itself at 2x (KOI_SHOT) and quits.
set -e
cd "${0:A:h}/.."
OUT=${1:-build/storeshots/mac}; mkdir -p $OUT
TMP=~/Library/Containers/nyc.jelia.koiknife/Data/tmp      # the sandboxed app's temp folder
shots=(
  "01_home|--dart-define=KOI_TAB=0"
  "02_kohaku|--dart-define=KOI_ROUTE=variety:kohaku"
  "03_identify|--dart-define=KOI_TAB=1"
  "04_history|--dart-define=KOI_ROUTE=chapter:8"
  "05_prices|--dart-define=KOI_TAB=3"
)
for s in $shots; do
  name=${s%%|*}; def=${s#*|}
  flutter build macos --debug $def --dart-define=KOI_SHOT=$name >/dev/null
  rm -f $TMP/$name.png
  KOI_WINDOW=1440x900 build/macos/Build/Products/Debug/KoiKnife.app/Contents/MacOS/KoiKnife >/dev/null 2>&1 || true
  cp $TMP/$name.png $OUT/$name.png && echo "$name: $(sips -g pixelWidth -g pixelHeight $OUT/$name.png | tail -2 | awk '{print $2}' | tr '\n' 'x')"
done
