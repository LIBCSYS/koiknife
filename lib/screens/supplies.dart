// Supplies & Care: what a pond needs, the pond year, water tests and FAQ —
// all from B&M's own guidance for zone-6 ponds.
import 'package:flutter/material.dart';

import '../data.dart';
import '../main.dart';
import '../theme.dart';
import '../widgets.dart';
import 'guide.dart';

class SuppliesScreen extends StatefulWidget {
  final int initialTab;
  const SuppliesScreen({super.key, this.initialTab = 0});
  @override
  State<SuppliesScreen> createState() => _SuppliesScreenState();
}

class _SuppliesScreenState extends State<SuppliesScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      initialIndex: widget.initialTab,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 64,
          title: const Text('Supplies & care', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            unselectedLabelStyle: TextStyle(fontSize: 18),
            indicatorColor: KoiColors.red,
            tabs: [Tab(text: 'Gear'), Tab(text: 'Pond year'), Tab(text: 'Water'), Tab(text: 'FAQ')],
          ),
        ),
        body: const TabBarView(children: [_Gear(), _Year(), _Water(), _Faq()]),
      ),
    );
  }
}

IconData _icon(String id) => switch (id) {
      'filter' => Icons.filter_alt_rounded,
      'air' => Icons.bubble_chart_rounded,
      'food' => Icons.set_meal_rounded,
      'science' => Icons.science_rounded,
      'construction' => Icons.construction_rounded,
      'shield' => Icons.shield_rounded,
      'plant' => Icons.local_florist_rounded,
      _ => Icons.circle,
    };

class _Gear extends StatelessWidget {
  const _Gear();
  @override
  Widget build(BuildContext context) {
    final s = KoiScope.of(context).data.supplies;
    final t = Theme.of(context).textTheme;
    return ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 40), children: [
      Readable(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(s['intro'], style: t.bodyMedium?.copyWith(color: KoiColors.mist)),
          const SizedBox(height: 14),
          Card(
            color: KoiColors.gold.withValues(alpha: 0.14),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              leading: const Icon(Icons.thermostat_rounded, color: KoiColors.gold, size: 32),
              title: const Text('Feeding by water temperature', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
              subtitle: const Text('What to feed today, and how much', style: TextStyle(fontSize: 16)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FeedingScreen())),
            ),
          ),
          const SizedBox(height: 14),
          for (final g in s['gear'])
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                    childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                    leading: CircleAvatar(
                      backgroundColor: KoiColors.red.withValues(alpha: 0.2),
                      child: Icon(_icon(g['icon']), color: KoiColors.red),
                    ),
                    title: Text(g['title'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                    subtitle: Text(g['lead'], style: const TextStyle(fontSize: 16, color: KoiColors.mist)),
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final item in g['items'])
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 3),
                              child: Icon(Icons.check_rounded, size: 20, color: KoiColors.gold),
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Text(item, style: const TextStyle(fontSize: 18))),
                          ]),
                        ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                            color: KoiColors.ink.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(14)),
                        child: Text('B&M tip: ${g['tip']}', style: const TextStyle(fontSize: 17, height: 1.4)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
          const VisitBMCard(lead: 'Need a part? It might be a \$12 fix.'),
        ]),
      ),
    ]);
  }
}

class _Year extends StatelessWidget {
  const _Year();
  @override
  Widget build(BuildContext context) {
    final s = KoiScope.of(context).data.supplies;
    final now = DateTime.now().month;
    // Which season card is "now" — highlights it so the screen answers
    // "what should I be doing this month?" at a glance.
    int current() => switch (now) {
          3 || 4 => 0,
          5 || 6 => 1,
          7 || 8 => 2,
          9 || 10 => 3,
          11 || 12 => 4,
          _ => 5,
        };
    final year = s['year'] as List;
    return ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 40), children: [
      Readable(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('The pond year is set by water temperature, not the calendar.',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          for (var i = 0; i < year.length; i++) _SeasonRow(year[i], isNow: i == current(), last: i == year.length - 1),
          const SizedBox(height: 10),
          Text(s['yearNote'], style: const TextStyle(fontSize: 15, color: KoiColors.mist)),
        ]),
      ),
    ]);
  }
}

class _SeasonRow extends StatelessWidget {
  final Map<String, dynamic> s;
  final bool isNow, last;
  const _SeasonRow(this.s, {required this.isNow, required this.last});
  @override
  Widget build(BuildContext context) {
    final c = hex(s['color']);
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Column(children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
                color: c, shape: BoxShape.circle, border: Border.all(color: KoiColors.cream, width: isNow ? 3 : 0)),
          ),
          if (!last) Expanded(child: Container(width: 3, color: c.withValues(alpha: 0.4))),
        ]),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 22),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(
                  child: Text(s['when'], style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: c)),
                ),
                if (isNow) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(10)),
                    child: const Text('NOW',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.black)),
                  ),
                ],
              ]),
              Text('Water: ${s['water']}', style: const TextStyle(fontSize: 16, color: KoiColors.mist)),
              const SizedBox(height: 6),
              Text(s['what'], style: const TextStyle(fontSize: 18, height: 1.45)),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _Water extends StatelessWidget {
  const _Water();
  @override
  Widget build(BuildContext context) {
    final s = KoiScope.of(context).data.supplies;
    return ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 40), children: [
      Readable(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Test the water before you treat the fish.', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          for (final w in s['water'])
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(w['test'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                    Text('Target: ${w['good']}',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: KoiColors.gold)),
                    const SizedBox(height: 6),
                    Text(w['why'], style: const TextStyle(fontSize: 17, color: KoiColors.mist, height: 1.4)),
                  ]),
                ),
              ),
            ),
          const SizedBox(height: 6),
          Text(s['waterNote'], style: const TextStyle(fontSize: 15, color: KoiColors.mist)),
          const SizedBox(height: 16),
          const VisitBMCard(lead: 'Bring a sample in a clean jar.'),
        ]),
      ),
    ]);
  }
}

class _Faq extends StatelessWidget {
  const _Faq();
  @override
  Widget build(BuildContext context) {
    final s = KoiScope.of(context).data.supplies;
    return ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 40), children: [
      Readable(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (final f in s['faq'])
            Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(f['q'], style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: KoiColors.gold)),
                const SizedBox(height: 6),
                Text(f['a'], style: const TextStyle(fontSize: 18, height: 1.5)),
              ]),
            ),
          const VisitBMCard(lead: 'Still stuck? Describe it on the phone.'),
        ]),
      ),
    ]);
  }
}
