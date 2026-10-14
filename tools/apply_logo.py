"""apply_logo.py — every KoiKnife app icon comes from the one brand logo (J, 2026-10-14).

Replaces tools/make_icon.py (the drawn Kohaku). Source: ../brand/koiknife-logo-1024.png.
  iOS/iPadOS + macOS: each PNG in the AppIcon sets, at the size its own Contents.json declares
                      (opaque RGB: App Store rejects alpha in the 1024 marketing icon)
  Android:           legacy mipmap ic_launcher (full square logo) and the adaptive-icon foreground:
                      the gold-ring circle with transparency outside it, so the launcher's circle /
                      squircle mask never bites into the logo; the outside is filled by
                      @color/ic_launcher_background, matched to the logo's own teal.
usage: python3 tools/apply_logo.py        (run from the app root)
"""
import json, os, sys
from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LOGO = os.path.normpath(os.path.join(ROOT, "..", "brand", "koiknife-logo-1024.png"))
RING_R = 453            # outer edge of the gold ring in the 1024 master (measured), plus 2 px of slack
BG_HEX = "#12353A"      # the logo's teal just inside its edge: shows around the adaptive foreground

logo = Image.open(LOGO).convert("RGB")
assert logo.size == (1024, 1024), "brand master must be 1024x1024"

def appiconset(folder):
    """Fill one Xcode AppIcon set using the sizes its Contents.json asks for."""
    meta = json.load(open(os.path.join(folder, "Contents.json")))
    done = 0
    for img in meta["images"]:
        if "filename" not in img: continue
        pts = float(img["size"].split("x")[0]); scale = int(img["scale"].rstrip("x"))
        px = round(pts * scale)
        logo.resize((px, px), Image.LANCZOS).save(os.path.join(folder, img["filename"]))
        done += 1
    return done

def circle_foreground(px):
    """Round logo on transparency, supersampled 4x so the cut edge is smooth."""
    big = 1024 * 4
    mask = Image.new("L", (big, big), 0)
    c = big // 2; r = RING_R * 4
    ImageDraw.Draw(mask).ellipse((c - r, c - r, c + r, c + r), fill=255)
    rgba = logo.convert("RGBA"); rgba.putalpha(mask.resize((1024, 1024), Image.LANCZOS))
    return rgba.resize((px, px), Image.LANCZOS)

n_ios = appiconset(os.path.join(ROOT, "ios/Runner/Assets.xcassets/AppIcon.appiconset"))
n_mac = appiconset(os.path.join(ROOT, "macos/Runner/Assets.xcassets/AppIcon.appiconset"))

res = os.path.join(ROOT, "android/app/src/main/res"); n_and = 0
for dens, launcher_px in (("mdpi", 48), ("hdpi", 72), ("xhdpi", 96), ("xxhdpi", 144), ("xxxhdpi", 192)):
    logo.resize((launcher_px, launcher_px), Image.LANCZOS).save(os.path.join(res, f"mipmap-{dens}", "ic_launcher.png")); n_and += 1
    fg_dir = os.path.join(res, f"drawable-{dens}"); fg_path = os.path.join(fg_dir, "ic_launcher_foreground.png")
    if os.path.exists(fg_path):                                   # keep each density's existing canvas size
        fg_px = Image.open(fg_path).size[0]
        circle_foreground(fg_px).save(fg_path); n_and += 1

colors = os.path.join(res, "values/colors.xml"); s = open(colors).read()
import re
s2 = re.sub(r'(<color name="ic_launcher_background">)#[0-9A-Fa-f]{6}(</color>)', r"\g<1>" + BG_HEX + r"\g<2>", s)
open(colors, "w").write(s2)
print(f"iOS {n_ios} · macOS {n_mac} · Android {n_and} files · adaptive background {BG_HEX}")
