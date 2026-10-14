# RETIRED 2026-10-14: the app icon now comes from the brand logo (tools/apply_logo.py). Kept for history.
# KoiKnife app icon: one Kohaku curving through night-pond water.
# Same spine/width model as lib/pond.dart so the icon matches the in-app fish.
import math, sys
from PIL import Image, ImageDraw, ImageFilter
S = 1024; SS = 3; W = S * SS  # supersample for smooth edges
img = Image.new("RGB", (W, W))
# radial water
cx = cy = W / 2
px = img.load()
for y in range(0, W, 1):
    pass
bg = Image.new("RGB", (W, W)); d = ImageDraw.Draw(bg)
for r in range(int(W * 0.75), 0, -6):
    t = r / (W * 0.75)
    c0, c1 = (0x2a, 0x6e, 0x70), (0x06, 0x1a, 0x1f)
    col = tuple(int(c0[i] * (1 - t) + c1[i] * t) for i in range(3))
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=col)
img = bg
# fish spine: an S-curve arc around the centre, head up-right
L = W * 0.78; N = 60
def spine(t):
    a = -0.9 + t * 2.2                       # sweep angle along an arc
    R = W * 0.30
    x = cx + R * math.cos(a) * 0.95 - W * 0.02
    y = cy - R * math.sin(a) * 0.95 + W * 0.02
    return x, y
def width(t):
    return L * 0.125 * math.sin(math.pi * (t ** 0.62) * 0.98) + L * 0.01
pts = [spine(1 - i / N) for i in range(N + 1)]  # i=0 nose
# centre the fish (body + tail) in the frame
xs=[p[0] for p in pts]; ys=[p[1] for p in pts]
ox = cx - (min(xs)+max(xs))/2 - W*0.03; oy = cy - (min(ys)+max(ys))/2 - W*0.03
pts = [(x+ox, y+oy) for x, y in pts]
left, right = [], []
for i, p in enumerate(pts):
    a = pts[max(0, i - 1)]; b = pts[min(N, i + 1)]
    dx, dy = b[0] - a[0], b[1] - a[1]; n = math.hypot(dx, dy) or 1
    nx, ny = -dy / n, dx / n; w = width(i / N)
    left.append((p[0] + nx * w, p[1] + ny * w)); right.append((p[0] - nx * w, p[1] - ny * w))
body = left + right[::-1]
# shadow
sh = Image.new("L", (W, W), 0); ImageDraw.Draw(sh).polygon([(x + W*0.02, y + W*0.03) for x, y in body], fill=120)
sh = sh.filter(ImageFilter.GaussianBlur(W * 0.02))
img.paste((0, 0, 0), mask=sh)
dr = ImageDraw.Draw(img)
# tail fins
tx, ty = pts[-1]; ax, ay = pts[-6]
ang = math.atan2(ty - ay, tx - ax); tl = L * 0.24
for s in (-1, 1):
    a2 = ang + s * 0.55
    dr.polygon([(tx, ty), (tx + tl * math.cos(a2 - 0.25 * s), ty + tl * math.sin(a2 - 0.25 * s)),
                (tx + tl * 0.8 * math.cos(a2 + 0.2 * s), ty + tl * 0.8 * math.sin(a2 + 0.2 * s))], fill=(235, 232, 225))
# pectoral fins
fx, fy = pts[int(N * 0.24)]; bx, by = pts[int(N * 0.20)]
fa = math.atan2(fy - by, fx - bx)
for s in (-1, 1):
    a2 = fa + s * 2.3; pf = L * 0.15
    dr.polygon([(fx, fy), (fx + pf * math.cos(a2 - 0.3), fy + pf * math.sin(a2 - 0.3)),
                (fx + pf * math.cos(a2 + 0.3), fy + pf * math.sin(a2 + 0.3))], fill=(240, 236, 228))
# body white + Kohaku red pattern clipped to body
mask = Image.new("L", (W, W), 0); ImageDraw.Draw(mask).polygon(body, fill=255)
white = Image.new("RGB", (W, W), (248, 245, 238)); img.paste(white, mask=mask)
red = Image.new("L", (W, W), 0); rd = ImageDraw.Draw(red)
for t, s, r in [(0.14, 0.0, 0.075), (0.30, 0.35, 0.07), (0.36, -0.3, 0.06), (0.52, 0.15, 0.085), (0.68, -0.25, 0.05)]:
    i = int(t * N); x, y = pts[i]; rr = L * r
    a = pts[max(0, i - 1)]; b = pts[min(N, i + 1)]; dx, dy = b[0]-a[0], b[1]-a[1]; n = math.hypot(dx, dy) or 1
    x += -dy / n * s * width(t); y += dx / n * s * width(t)
    rd.ellipse([x - rr, y - rr * 0.75, x + rr * 1.15, y + rr * 0.85], fill=255)
from PIL import ImageChops
red = ImageChops.multiply(red, mask)
img.paste((222, 46, 32), mask=red)
# eyes
hx, hy = pts[4]; nx_, ny_ = pts[0][0] - pts[4][0], pts[0][1] - pts[4][1]; n = math.hypot(nx_, ny_)
px_, py_ = -ny_ / n, nx_ / n
for s in (-1, 1):
    ex, ey = hx + px_ * s * width(4/60) * 0.55, hy + py_ * s * width(4/60) * 0.55
    dr.ellipse([ex - W*0.008, ey - W*0.008, ex + W*0.008, ey + W*0.008], fill=(20, 20, 20))
# gold ring: the "knife"/tool motif kept subtle — a ring like a tool's lanyard loop
ring = W * 0.44
dr.ellipse([cx - ring, cy - ring, cx + ring, cy + ring], outline=(242, 194, 48), width=int(W * 0.012))
img = img.resize((S, S), Image.LANCZOS)
img.save(sys.argv[1]); print("ok", img.size, img.mode)
