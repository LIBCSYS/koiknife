// The living pond on the home screen.
//
// Everything is drawn procedurally with CustomPainter — no sprite sheets — so the
// fish stay crisp on a 13" iPad and a small Android phone alike, and each fish
// wears its real variety's colours straight from varieties.json.
//
// Interaction: tap drops food (fish race for it), drag sends a ripple trail
// and the fish shy away from your finger, the way real koi do until they trust you.
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'data.dart';

class _Fish {
  Offset pos;
  double heading; // radians, 0 = facing +x
  double speed;
  double length;
  double phase = 0; // tail-beat phase
  Offset target;
  final Variety v;
  final List<_Patch> patches;

  _Fish(this.v, this.pos, this.heading, this.length, this.target, this.patches)
      : speed = 30;
}

/// A coloured blotch in fish-local coordinates (t along body 0=nose..1=tail, s across -1..1).
class _Patch {
  final double t, s, r;
  final Color c;
  _Patch(this.t, this.s, this.r, this.c);
}

class _Ripple {
  Offset at;
  double age = 0;
  final double strength;
  _Ripple(this.at, this.strength);
}

class _Pellet {
  Offset at;
  double age = 0;
  _Pellet(this.at);
}

class KoiPond extends StatefulWidget {
  final List<Variety> varieties;
  final int fishCount;
  final bool lilies; // off for single-fish portraits
  const KoiPond({super.key, required this.varieties, this.fishCount = 8, this.lilies = true});

  @override
  State<KoiPond> createState() => _KoiPondState();
}

class _KoiPondState extends State<KoiPond> with SingleTickerProviderStateMixin {
  final _rng = math.Random(7);
  final List<_Fish> _fish = [];
  final List<_Ripple> _ripples = [];
  final List<_Pellet> _pellets = [];
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  Size _size = Size.zero;
  Offset? _finger;
  double _clock = 0;

  // The fish we show first: the classic pond line-up, then whatever else exists.
  static const _preferred = [
    'kohaku', 'sanke', 'showa', 'ogon', 'chagoi', 'tancho', 'platinum_ogon',
    'asagi', 'shiro_bekko', 'kujaku', 'hi_utsuri', 'butterfly'
  ];

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _spawn(Size size) {
    _fish.clear();
    final bySlug = {for (final v in widget.varieties) v.slug: v};
    final picks = [
      for (final s in _preferred)
        if (bySlug[s] != null) bySlug[s]!,
      for (final v in widget.varieties)
        if (!_preferred.contains(v.slug)) v,
    ];
    final base = math.min(size.width, size.height);
    for (var i = 0; i < widget.fishCount && i < picks.length; i++) {
      final v = picks[i];
      final len = widget.fishCount == 1
          ? base * 0.62
          : base * (0.17 + _rng.nextDouble() * 0.09);
      _fish.add(_Fish(v, _randomPoint(size), _rng.nextDouble() * math.pi * 2, len,
          _randomPoint(size), _patternFor(v)));
    }
  }

  // Pattern recipes. Real koi patterns are judged on placement, so we place
  // patches with intent: Kohaku red on the back, Sanke black spots behind
  // the head, Showa black wrapping the head, Tancho one spot only.
  List<_Patch> _patternFor(Variety v) {
    final r = math.Random(v.slug.hashCode);
    final cs = v.colors;
    final out = <_Patch>[];
    if (v.slug == 'tancho') {
      out.add(_Patch(0.12, 0, 0.42, cs[1]));
      return out;
    }
    if (cs.length < 2) return out;
    if (v.slug == 'ogon' || v.slug == 'platinum_ogon' || v.slug == 'chagoi' ||
        v.slug == 'soragoi' || v.slug == 'kigoi' || v.slug == 'benigoi' ||
        v.slug == 'karashigoi') {
      // Solid fish: a faint second tone along the back for depth.
      out.add(_Patch(0.4, 0, 0.9, cs[1].withValues(alpha: 0.35)));
      return out;
    }
    // Main pattern blocks in colour 2.
    final blocks = 2 + r.nextInt(3);
    for (var i = 0; i < blocks; i++) {
      out.add(_Patch(0.12 + i * (0.6 / blocks) + r.nextDouble() * 0.08,
          (r.nextDouble() - 0.5) * 0.6, 0.45 + r.nextDouble() * 0.35, cs[1]));
    }
    // Accent spots in colour 3 (Sanke/Showa black, Kujaku net, etc.).
    if (cs.length > 2) {
      final spots = 3 + r.nextInt(3);
      for (var i = 0; i < spots; i++) {
        out.add(_Patch(0.2 + r.nextDouble() * 0.55, (r.nextDouble() - 0.5) * 1.2,
            0.18 + r.nextDouble() * 0.2, cs[2]));
      }
    }
    return out;
  }

  Offset _randomPoint(Size s) => Offset(
      s.width * (0.1 + _rng.nextDouble() * 0.8), s.height * (0.1 + _rng.nextDouble() * 0.8));

  void _tick(Duration now) {
    final dt = _last == Duration.zero
        ? 1 / 60
        : math.min((now - _last).inMicroseconds / 1e6, 1 / 20); // clamp after a stall
    _last = now;
    _clock += dt;
    if (_size == Size.zero) return;

    for (final p in _pellets) {
      p.age += dt;
    }
    _pellets.removeWhere((p) => p.age > 14);
    for (final r in _ripples) {
      r.age += dt;
    }
    _ripples.removeWhere((r) => r.age > 2.4);

    for (final f in _fish) {
      // 1. Choose where to go: nearest food beats wandering.
      _Pellet? food;
      double best = double.infinity;
      for (final p in _pellets) {
        final d = (p.at - f.pos).distance;
        if (d < best && d < _size.longestSide * 0.7) {
          best = d;
          food = p;
        }
      }
      var goal = food?.at ?? f.target;
      var urgency = food != null ? 1.0 : 0.0;

      // 2. Shy away from a dragging finger.
      if (_finger != null) {
        final away = f.pos - _finger!;
        final d = away.distance;
        if (d < f.length * 2.2 && d > 0) {
          goal = f.pos + away / d * f.length * 3;
          urgency = 1.4;
        }
      }

      if (food == null && (f.target - f.pos).distance < f.length * 0.6) {
        f.target = _randomPoint(_size);
      }

      // 3. Steer: turn toward goal at a limited rate (koi bank, they don't pivot).
      final want = math.atan2(goal.dy - f.pos.dy, goal.dx - f.pos.dx);
      var diff = (want - f.heading) % (math.pi * 2);
      if (diff > math.pi) diff -= math.pi * 2;
      final turnRate = 1.2 + urgency * 1.6;
      f.heading += diff.clamp(-turnRate * dt, turnRate * dt);

      final cruise = f.length * (0.35 + urgency * 0.9);
      f.speed += (cruise - f.speed) * math.min(1, dt * 1.5);
      f.pos += Offset(math.cos(f.heading), math.sin(f.heading)) * f.speed * dt;
      f.phase += dt * (2.2 + f.speed / f.length * 3.0);

      // 4. Keep inside the pond with a soft wall.
      const pad = 0.04;
      f.pos = Offset(f.pos.dx.clamp(-_size.width * pad, _size.width * (1 + pad)),
          f.pos.dy.clamp(-_size.height * pad, _size.height * (1 + pad)));
      if (f.pos.dx < 0 || f.pos.dx > _size.width || f.pos.dy < 0 || f.pos.dy > _size.height) {
        f.target = Offset(_size.width / 2, _size.height / 2);
      }

      // 5. Eat.
      if (food != null && best < f.length * 0.28) {
        _pellets.remove(food);
        _ripples.add(_Ripple(food.at, 0.6));
      }
    }
    setState(() {});
  }

  void _feed(Offset at) {
    _ripples.add(_Ripple(at, 1));
    for (var i = 0; i < 4; i++) {
      _pellets.add(_Pellet(at + Offset(_rng.nextDouble() * 30 - 15, _rng.nextDouble() * 30 - 15)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final size = Size(box.maxWidth, box.maxHeight);
      if (size != _size) {
        final first = _size == Size.zero;
        _size = size;
        if (first || _fish.isEmpty) _spawn(size);
      }
      return Semantics(
        label: 'Animated koi pond. Tap to feed the fish.',
        child: GestureDetector(
          onTapDown: (d) => _feed(d.localPosition),
          onPanStart: (d) => _finger = d.localPosition,
          onPanUpdate: (d) {
            _finger = d.localPosition;
            if (_rng.nextDouble() < 0.25) _ripples.add(_Ripple(d.localPosition, 0.45));
          },
          onPanEnd: (_) => _finger = null,
          onPanCancel: () => _finger = null,
          child: CustomPaint(
            size: size,
            painter: _PondPainter(_fish, _ripples, _pellets, _clock, widget.lilies),
          ),
        ),
      );
    });
  }
}

class _PondPainter extends CustomPainter {
  final List<_Fish> fish;
  final List<_Ripple> ripples;
  final List<_Pellet> pellets;
  final double clock;
  final bool lilies;
  _PondPainter(this.fish, this.ripples, this.pellets, this.clock, this.lilies);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Water: deep green-teal with a lighter centre, like looking into a clear pond.
    canvas.drawRect(
        rect,
        Paint()
          ..shader = ui.Gradient.radial(size.center(Offset.zero), size.longestSide * 0.75,
              const [Color(0xFF1F5A5E), Color(0xFF0E3238), Color(0xFF071C21)], [0, 0.6, 1]));

    // Drifting caustic light: a few large soft blobs moving slowly.
    final caustic = Paint()
      ..blendMode = BlendMode.plus
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);
    for (var i = 0; i < 6; i++) {
      final a = clock * 0.07 + i * 1.7;
      final c = Offset(size.width * (0.5 + 0.42 * math.sin(a * 1.3 + i)),
          size.height * (0.5 + 0.42 * math.cos(a + i * 0.6)));
      caustic.color = const Color(0xFF3FA9A0).withValues(alpha: 0.10);
      canvas.drawCircle(c, size.shortestSide * 0.22, caustic);
    }

    // Shadows first (fish sit a little above the pond floor).
    for (final f in fish) {
      canvas.save();
      canvas.translate(f.pos.dx + f.length * 0.12, f.pos.dy + f.length * 0.16);
      canvas.rotate(f.heading);
      canvas.drawPath(
          _bodyPath(f),
          Paint()
            ..color = Colors.black.withValues(alpha: 0.28)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, f.length * 0.06));
      canvas.restore();
    }

    for (final p in pellets) {
      final bob = math.sin(p.age * 3 + p.at.dx) * 1.2;
      canvas.drawCircle(p.at + Offset(0, bob), 3.4, Paint()..color = const Color(0xFFB07A3A));
      canvas.drawCircle(p.at + Offset(-1, bob - 1), 1.2, Paint()..color = const Color(0x99FFE2B0));
    }

    for (final f in fish) {
      _drawFish(canvas, f);
    }

    // Lily pads float above the fish.
    if (lilies) _lilies(canvas, size);

    for (final r in ripples) {
      final t = r.age / 2.4;
      for (var k = 0; k < 2; k++) {
        final tt = (t - k * 0.12).clamp(0.0, 1.0);
        if (tt <= 0) continue;
        canvas.drawCircle(
            r.at,
            8 + tt * 90 * r.strength,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.0 * (1 - tt)
              ..color = Colors.white.withValues(alpha: 0.55 * (1 - tt) * r.strength));
      }
    }
  }

  // Spine-based body: a centre line that waves more toward the tail, with a
  // width profile that is blunt at the nose, fullest at the shoulder, thin at
  // the peduncle. That profile is what reads as "koi" rather than "fish".
  static const _n = 18;
  List<Offset> _spine(_Fish f) {
    final pts = <Offset>[];
    for (var i = 0; i <= _n; i++) {
      final t = i / _n;
      final x = f.length * (0.5 - t);
      final amp = f.length * 0.09 * t * t;
      pts.add(Offset(x, math.sin(f.phase - t * 3.4) * amp));
    }
    return pts;
  }

  double _width(double t, double len) {
    final w = math.sin(math.pi * math.pow(t, 0.62) * 0.98);
    return len * 0.135 * w + len * 0.012;
  }

  Path _bodyPath(_Fish f) {
    final s = _spine(f);
    final left = <Offset>[], right = <Offset>[];
    for (var i = 0; i < s.length; i++) {
      final a = s[math.max(0, i - 1)], b = s[math.min(s.length - 1, i + 1)];
      final d = b - a;
      final n = Offset(-d.dy, d.dx) / (d.distance == 0 ? 1 : d.distance);
      final w = _width(i / _n, f.length);
      left.add(s[i] + n * w);
      right.add(s[i] - n * w);
    }
    final p = Path()..moveTo(s.first.dx + f.length * 0.02, s.first.dy);
    for (final q in left) {
      p.lineTo(q.dx, q.dy);
    }
    for (final q in right.reversed) {
      p.lineTo(q.dx, q.dy);
    }
    return p..close();
  }

  void _drawFish(Canvas canvas, _Fish f) {
    final v = f.v;
    final base = v.colors.first;
    canvas.save();
    canvas.translate(f.pos.dx, f.pos.dy);
    canvas.rotate(f.heading);

    final spine = _spine(f);
    final tail = spine.last;
    final beat = math.sin(f.phase - 3.4);
    final finPaint = Paint()..color = base.withValues(alpha: 0.55);
    final longfin = v.slug == 'butterfly';

    // Tail: two lobes swinging with the last spine segment.
    final tl = f.length * (longfin ? 0.42 : 0.26);
    final tailPath = Path()
      ..moveTo(tail.dx + f.length * 0.03, tail.dy)
      ..quadraticBezierTo(tail.dx - tl * 0.5, tail.dy - tl * 0.55 + beat * 4,
          tail.dx - tl, tail.dy - tl * 0.5 + beat * tl * 0.4)
      ..quadraticBezierTo(tail.dx - tl * 0.7, tail.dy + beat * tl * 0.3,
          tail.dx - tl, tail.dy + tl * 0.5 + beat * tl * 0.4)
      ..quadraticBezierTo(tail.dx - tl * 0.5, tail.dy + tl * 0.55 + beat * 4, tail.dx, tail.dy)
      ..close();
    canvas.drawPath(tailPath, finPaint);

    // Pectoral fins, sculling slightly out of phase with the tail.
    final pf = f.length * (longfin ? 0.24 : 0.16);
    final scull = math.sin(f.phase * 0.8) * 0.25;
    for (final side in [-1.0, 1.0]) {
      canvas.save();
      final root = spine[(_n * 0.24).round()];
      canvas.translate(root.dx, root.dy + side * _width(0.24, f.length) * 0.8);
      canvas.rotate(side * (2.4 + scull));
      canvas.drawOval(Rect.fromLTWH(0, -pf * 0.22, pf, pf * 0.44), finPaint);
      canvas.restore();
    }

    final body = _bodyPath(f);
    canvas.drawPath(body, Paint()..color = base);

    // Pattern, clipped to the body so blotches never spill onto the water.
    canvas.save();
    canvas.clipPath(body);
    for (final p in f.patches) {
      final idx = (p.t * _n).round().clamp(0, _n);
      final c = spine[idx] + Offset(0, p.s * _width(p.t, f.length));
      canvas.drawOval(
          Rect.fromCenter(
              center: c, width: f.length * p.r * 0.42, height: f.length * p.r * 0.3),
          Paint()..color = p.c);
    }
    // Metallic and pale fish get a dorsal sheen; it sells the 3-D body from above.
    canvas.drawPath(
        body,
        Paint()
          ..shader = ui.Gradient.linear(Offset(0, -f.length * 0.14), Offset(0, f.length * 0.14), [
            Colors.black.withValues(alpha: 0.22),
            Colors.white.withValues(alpha: 0.18),
            Colors.black.withValues(alpha: 0.22)
          ], [0, 0.5, 1]));
    canvas.restore();

    // Eyes.
    final head = spine[1];
    for (final side in [-1.0, 1.0]) {
      canvas.drawCircle(head + Offset(-f.length * 0.01, side * f.length * 0.07), f.length * 0.014,
          Paint()..color = const Color(0xFF1A1A1A));
    }
    canvas.restore();
  }

  void _lilies(Canvas canvas, Size size) {
    _lily(canvas, Offset(size.width * 0.86, size.height * 0.18), size.shortestSide * 0.11, 0.4);
    _lily(canvas, Offset(size.width * 0.1, size.height * 0.82), size.shortestSide * 0.13, 2.2);
    _lily(canvas, Offset(size.width * 0.2, size.height * 0.7), size.shortestSide * 0.07, 4.1);
  }

  void _lily(Canvas canvas, Offset c, double r, double rot) {
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(rot);
    final pad = Path()
      ..moveTo(0, 0)
      ..arcTo(Rect.fromCircle(center: Offset.zero, radius: r), 0.35, math.pi * 2 - 0.7, false)
      ..close();
    canvas.drawPath(
        pad.shift(Offset(r * 0.08, r * 0.1)),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.25)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.08));
    canvas.drawPath(
        pad,
        Paint()
          ..shader = ui.Gradient.radial(
              Offset.zero, r, const [Color(0xFF5C9A3C), Color(0xFF2F6A28)]));
    final vein = Paint()
      ..color = const Color(0x334F8A30)
      ..strokeWidth = 1.2;
    for (var i = 0; i < 7; i++) {
      final a = 0.6 + i * 0.75;
      canvas.drawLine(Offset.zero, Offset(math.cos(a), math.sin(a)) * r * 0.92, vein);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
