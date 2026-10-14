// Guide screens: price ladder + size calculator, feeding by water temperature,
// buying checklist, and photo credits.
import 'package:flutter/material.dart';

import '../data.dart';
import '../main.dart';
import '../theme.dart';
import '../widgets.dart';

class PriceScreen extends StatefulWidget {
  const PriceScreen({super.key});
  @override
  State<PriceScreen> createState() => _PriceScreenState();
}

class _PriceScreenState extends State<PriceScreen> {
  double _inches = 8;
  int _grade = 1; // Hobbyist

  // The calculator anchors each grade at its 6–8" band midpoint (7") and
  // scales by length squared — the rule of thumb on B&M's own koi guide.
  // It's labelled as a rule of thumb, not a quote.
  (double, double) _estimate(GradeRow r) {
    final (lo, hi) = switch (r.grade) {
      'Pond grade' => (24.0, 70.0),
      'Hobbyist (US domestic)' => (130.0, 200.0),
      'Japanese import' => (135.0, 200.0),
      'Breeder-attributed' => (175.0, 375.0),
      _ => (400.0, 1500.0),
    };
    final k = (_inches / 7) * (_inches / 7);
    return (lo * k, hi * k);
  }

  String _money(double v) {
    if (v >= 1000) return '\$${(v / 1000).toStringAsFixed(v >= 10000 ? 0 : 1)}k';
    return '\$${(v / 5).round() * 5}';
  }

  @override
  Widget build(BuildContext context) {
    final d = KoiScope.of(context).data;
    final bm = d.bm;
    final t = Theme.of(context).textTheme;
    final r = d.grades[_grade];
    final (lo, hi) = _estimate(r);

    return Scaffold(
      appBar: AppBar(title: const Text('Price guide')),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 40), children: [
        Readable(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('From pond fish to show koi', style: t.headlineMedium),
            const SizedBox(height: 8),
            Text(d.gradeNote, style: t.bodyMedium?.copyWith(color: KoiColors.mist)),
            const SizedBox(height: 18),

            // Grade ladder: one card per grade, sizes as a row of pills.
            for (var i = 0; i < d.grades.length; i++) _GradeCard(d.grades[i], d.sizes, i),

            const SizedBox(height: 22),
            Card(
              color: KoiColors.surface,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Size calculator', style: t.titleLarge),
                  const SizedBox(height: 4),
                  const Text('Price scales roughly with the square of length. Double the length, about four times the price.',
                      style: TextStyle(fontSize: 16, color: KoiColors.mist)),
                  const SizedBox(height: 14),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    for (var i = 0; i < d.grades.length; i++)
                      ChoiceChip(
                        label: Text(d.grades[i].grade.replaceAll(' (US domestic)', '')),
                        selected: _grade == i,
                        showCheckmark: false,
                        onSelected: (_) => setState(() => _grade = i),
                      ),
                  ]),
                  const SizedBox(height: 16),
                  Wrap(crossAxisAlignment: WrapCrossAlignment.end, spacing: 10, children: [
                    Text('${_inches.round()}″', style: t.displaySmall?.copyWith(color: KoiColors.cream)),
                    Text('${(_inches * 2.54).round()} cm', style: const TextStyle(fontSize: 17, color: KoiColors.mist)),
                  ]),
                  const SizedBox(height: 4),
                  Text('${_money(lo)} – ${_money(hi)}', style: t.headlineMedium?.copyWith(color: KoiColors.gold)),
                  Slider(
                    value: _inches,
                    min: 3,
                    max: 30,
                    divisions: 27,
                    label: '${_inches.round()}″',
                    onChanged: (v) => setState(() => _inches = v),
                  ),
                  Text(
                      _inches > 20
                          ? 'Past about 20″ the curve stops being about size and becomes about how few fish get that big and keep their shape. Rule of thumb only.'
                          : 'Rule of thumb only. Every fish is priced on its own body, skin and pattern.',
                      style: const TextStyle(fontSize: 15, color: KoiColors.mist)),
                ]),
              ),
            ),

            const SizedBox(height: 26),
            Text('Why two koi the same size cost wildly different money', style: t.headlineSmall),
            const SizedBox(height: 12),
            for (final w in bm['why_price']) _InfoTile(w['title'], w['text']),
            const SizedBox(height: 8),
            Text('For scale: championship koi have sold at auction for the price of a house. The record, S Legend, made ¥203 million in 2018.',
                style: t.bodyMedium?.copyWith(color: KoiColors.mist)),
            const SizedBox(height: 22),
            const VisitBMCard(lead: 'Ask what\'s actually in the greenhouse this week.'),
          ]),
        ),
      ]),
    );
  }
}

class _GradeCard extends StatelessWidget {
  final GradeRow r;
  final List<String> sizes;
  final int i;
  const _GradeCard(this.r, this.sizes, this.i);

  static const _tint = [Color(0xFF5FA3A0), Color(0xFF6DB56D), Color(0xFFE0A030), Color(0xFFE36A1E), KoiColors.red];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: Container(
          decoration: BoxDecoration(border: Border(left: BorderSide(color: _tint[i], width: 6))),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(r.grade, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700))),
              for (var k = 0; k <= i; k++) Icon(Icons.star_rounded, size: 18, color: _tint[i]),
            ]),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (var s = 0; s < sizes.length; s++)
                if (r.bands[s] != '—')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                        color: KoiColors.ink.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(10)),
                    child: RichText(
                      text: TextSpan(style: const TextStyle(fontSize: 15, color: KoiColors.mist), children: [
                        TextSpan(text: '${sizes[s]}  '),
                        TextSpan(
                            text: r.bands[s],
                            style: const TextStyle(color: KoiColors.cream, fontWeight: FontWeight.w700, fontSize: 16)),
                      ]),
                    ),
                  ),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String title, text;
  const _InfoTile(this.title, this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: KoiColors.gold)),
          const SizedBox(height: 4),
          Text(text, style: Theme.of(context).textTheme.bodyLarge),
        ]),
      );
}

/// Feeding by water temperature — the one question every owner has, every day.
class FeedingScreen extends StatefulWidget {
  const FeedingScreen({super.key});
  @override
  State<FeedingScreen> createState() => _FeedingScreenState();
}

class _FeedingScreenState extends State<FeedingScreen> {
  double _f = 66;
  bool _celsius = false;

  @override
  Widget build(BuildContext context) {
    final feed = KoiScope.of(context).data.bm['feeding'];
    final bands = feed['bands'] as List;
    final band = bands.lastWhere((b) => _f >= (b['lo'] as num), orElse: () => bands.first);
    final color = hex(band['color']);
    final t = Theme.of(context).textTheme;
    final shown = _celsius ? '${((_f - 32) * 5 / 9).round()}°C' : '${_f.round()}°F';

    return Scaffold(
      appBar: AppBar(title: const Text('Feeding by water temperature')),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 40), children: [
        Readable(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(feed['note'], style: t.bodyMedium?.copyWith(color: KoiColors.mist)),
            const SizedBox(height: 20),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: color, width: 2),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(Icons.thermostat_rounded, color: color, size: 40),
                  Expanded(child: Text(shown, style: t.displaySmall)),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('°F')),
                      ButtonSegment(value: true, label: Text('°C')),
                    ],
                    selected: {_celsius},
                    onSelectionChanged: (s) => setState(() => _celsius = s.first),
                  ),
                ]),
                Slider(
                  value: _f,
                  min: 34,
                  max: 92,
                  activeColor: color,
                  onChanged: (v) => setState(() => _f = v),
                ),
                Text(band['label'], style: t.titleLarge?.copyWith(color: color)),
                const SizedBox(height: 6),
                Text(band['advice'], style: t.bodyLarge),
              ]),
            ),
            const SizedBox(height: 18),
            Card(
              color: KoiColors.surface,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(children: [
                  const Icon(Icons.timer_rounded, color: KoiColors.gold, size: 30),
                  const SizedBox(width: 12),
                  Expanded(child: Text(feed['rule'], style: t.bodyLarge)),
                ]),
              ),
            ),
            const SizedBox(height: 22),
            Text('All bands', style: t.titleLarge),
            const SizedBox(height: 10),
            for (final b in bands)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                      width: 12,
                      height: 48,
                      decoration: BoxDecoration(color: hex(b['color']), borderRadius: BorderRadius.circular(6))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(b['label'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      Text(b['advice'], style: const TextStyle(fontSize: 16, color: KoiColors.mist)),
                    ]),
                  ),
                ]),
              ),
            const SizedBox(height: 12),
            const VisitBMCard(lead: 'Not sure about your water? Bring B&M a sample.'),
          ]),
        ),
      ]),
    );
  }
}

class BuyingScreen extends StatelessWidget {
  const BuyingScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final bm = KoiScope.of(context).data.bm;
    final t = Theme.of(context).textTheme;
    final items = bm['buying'] as List;
    return Scaffold(
      appBar: AppBar(title: const Text('Before you buy')),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 40), children: [
        Readable(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('What to look at before you buy', style: t.headlineMedium),
            const SizedBox(height: 18),
            for (var i = 0; i < items.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: KoiColors.red,
                    child: Text('${i + 1}',
                        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Colors.white)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(items[i]['title'], style: t.titleMedium),
                      const SizedBox(height: 2),
                      Text(items[i]['text'], style: t.bodyLarge?.copyWith(color: KoiColors.mist)),
                    ]),
                  ),
                ]),
              ),
            const VisitBMCard(lead: 'Bring your pond dimensions.'),
          ]),
        ),
      ]),
    );
  }
}

class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final cr = KoiScope.of(context).data.credits;
    Widget section(String title, String kind) {
      final rows = cr.where((c) => c.page.isNotEmpty && _kind(c) == kind).toList();
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(top: 18, bottom: 8),
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        for (final c in rows)
          InkWell(
            onTap: c.page.startsWith('http') ? () => openLink(c.page) : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Text.rich(TextSpan(style: const TextStyle(fontSize: 16, height: 1.35), children: [
                TextSpan(text: c.what, style: const TextStyle(fontWeight: FontWeight.w700)),
                TextSpan(text: ' · ${c.artist} · ', style: const TextStyle(color: KoiColors.mist)),
                TextSpan(text: c.licence, style: const TextStyle(color: KoiColors.gold)),
              ])),
            ),
          ),
      ]);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Credits')),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 40), children: [
        Readable(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text(
                'Variety photographs and historical artworks are freely licensed images from Wikimedia Commons, reproduced unaltered apart from resizing. Tap a variety credit to open its Commons page. CC BY-SA images remain under their licence.',
                style: TextStyle(fontSize: 17, color: KoiColors.mist)),
            section('Variety photographs', 'variety'),
            section('History pictures', 'history'),
            section('B&M Aquatics', 'bm'),
            const SizedBox(height: 20),
            Text('KoiKnife $appVersion · History research and koi guide by B&M Aquatics (aquatics.jelia.nyc). Built by LIBCSYSTEMS LLC.',
                style: const TextStyle(fontSize: 15, color: KoiColors.mist)),
          ]),
        ),
      ]),
    );
  }

  String _kind(Credit c) {
    if (c.artist.startsWith('B&M')) return 'bm';
    if (c.file.isNotEmpty) return 'variety';
    return 'history';
  }
}
