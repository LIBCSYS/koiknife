// Home: "The Swiss Army Knife of Koi" — every tool one tap away. The living
// pond is a small banner here (J 2026-10-14: the pond is minor; the app is
// about history, identification, pricing and supplies).
import 'package:flutter/material.dart';

import '../data.dart';
import '../main.dart';
import '../pond.dart';
import '../theme.dart';
import '../widgets.dart';
import 'bm.dart';
import 'guide.dart';
import 'quiz.dart';
import 'supplies.dart';
import 'varieties.dart';

class HomeScreen extends StatelessWidget {
  final void Function(int tab) onGo;
  const HomeScreen({super.key, required this.onGo});

  @override
  Widget build(BuildContext context) {
    final scope = KoiScope.of(context);
    final d = scope.data;
    final t = Theme.of(context).textTheme;
    final w = MediaQuery.sizeOf(context).width;
    final cols = w >= 1100 ? 4 : w >= 640 ? 3 : 2;

    // Koi of the day: stable for the whole day, different tomorrow.
    final now = DateTime.now();
    final dayIndex = DateTime(now.year, now.month, now.day).difference(DateTime(2026)).inDays;
    final withPhotos = d.varieties.where((v) => v.hasPhoto).toList();
    final kotd = withPhotos[dayIndex % withPhotos.length];

    void push(Widget page) => Navigator.push(context, MaterialPageRoute(builder: (_) => page));

    final tools = <_Tool>[
      _Tool(Icons.search_rounded, 'Identify', '${d.varieties.length} varieties', KoiColors.red, () => onGo(1)),
      _Tool(Icons.auto_stories_rounded, 'History', '10 chapters, myths busted', const Color(0xFF8E7CC3), () => onGo(2)),
      _Tool(Icons.sell_rounded, 'Prices', 'Pond grade → Show koi', KoiColors.gold, () => onGo(3)),
      _Tool(Icons.inventory_2_rounded, 'Supplies', 'Gear every pond needs', const Color(0xFF5FA3A0), () => onGo(4)),
      _Tool(Icons.thermostat_rounded, 'Feeding', 'By water temperature', const Color(0xFFE0A030),
          () => push(const FeedingScreen())),
      _Tool(Icons.calendar_month_rounded, 'Pond year', 'What to do this month', const Color(0xFF6DB56D),
          () => push(const SuppliesScreen(initialTab: 1))),
      _Tool(Icons.science_rounded, 'Water tests', 'Read your numbers', const Color(0xFF5B8DB8),
          () => push(const SuppliesScreen(initialTab: 2))),
      _Tool(Icons.checklist_rounded, 'Before you buy', '6-point checklist', const Color(0xFFE36A1E),
          () => push(const BuyingScreen())),
      _Tool(Icons.quiz_rounded, 'Name That Koi', 'Test your eye', const Color(0xFFD94F8A),
          () => push(const Scaffold(body: QuizScreen()))),
      _Tool(Icons.favorite_rounded, 'My Koi', '${scope.wish.count} saved', KoiColors.red,
          () => push(const VarietiesScreen(wishOnly: true))),
      _Tool(Icons.storefront_rounded, 'B&M Aquatics', 'Hamburg, NJ', const Color(0xFF3FA9A0), () => push(const BMScreen())),
      _Tool(Icons.water_rounded, 'Koi Pond', 'Toy: feed the fish', const Color(0xFF3FA9A0),
          () => push(PondToyScreen(varieties: d.varieties))),
      _Tool(Icons.help_rounded, 'Pond FAQ', 'Green water, winter…', const Color(0xFF9AA6B2),
          () => push(const SuppliesScreen(initialTab: 3))),
    ];

    return CustomScrollView(slivers: [
      // Pond banner with the title floating over the water.
      SliverToBoxAdapter(
        child: SizedBox(
          height: 250 + MediaQuery.paddingOf(context).top,
          child: Stack(fit: StackFit.expand, children: [
            KoiPond(varieties: d.varieties, fishCount: 6),
            IgnorePointer(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x99071C21), Colors.transparent, Color(0xEE071C21)],
                      stops: [0, 0.45, 1]),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          // J's brand logo (2026-10-14), circle-cut so it floats on the pond
                          Image.asset('assets/brand/logo_round.png', width: 56, height: 56,
                              semanticLabel: 'KoiKnife logo'),
                          const SizedBox(width: 12),
                          Text('KoiKnife', style: t.displaySmall?.copyWith(fontSize: 40)),
                          const SizedBox(width: 10),
                          const Text('鯉', style: TextStyle(fontSize: 34, color: KoiColors.red)),
                        ]),
                      ),
                      Text('The Swiss Army Knife of Koi Knowledge',
                          maxLines: 2,
                          style: t.titleMedium?.copyWith(color: KoiColors.gold, fontWeight: FontWeight.w700)),
                      const Spacer(),
                      const Text('Tap the water to feed the fish',
                          style: TextStyle(fontSize: 15, color: KoiColors.mist)),
                    ]),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),

      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: _KoiOfTheDay(kotd),
        ),
      ),

      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
          child: Text('The toolkit', style: t.headlineSmall),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.15),
          delegate: SliverChildBuilderDelegate((c, i) => _ToolTile(tools[i]), childCount: tools.length),
        ),
      ),

      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
          child: _BMBanner(onTap: () => push(const BMScreen())),
        ),
      ),
    ]);
  }
}

class _Tool {
  final IconData icon;
  final String title, sub;
  final Color color;
  final VoidCallback onTap;
  _Tool(this.icon, this.title, this.sub, this.color, this.onTap);
}

class _ToolTile extends StatelessWidget {
  final _Tool tool;
  const _ToolTile(this.tool);
  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: tool.onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: tool.color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(14)),
              child: Icon(tool.icon, color: tool.color, size: 30),
            ),
            const Spacer(),
            Text(tool.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
            Text(tool.sub,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 15, color: KoiColors.mist)),
          ]),
        ),
      ),
    );
  }
}

class _KoiOfTheDay extends StatelessWidget {
  final Variety v;
  const _KoiOfTheDay(this.v);
  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VarietyDetail(v))),
        child: SizedBox(
          height: 150,
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SizedBox(width: 140, child: KoiImage(v)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const SectionLabel('Koi of the day'),
                  const SizedBox(height: 4),
                  Text('${v.name}  ${v.kanji}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Text(v.blurb,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 16, color: KoiColors.mist, height: 1.3)),
                  ),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _BMBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _BMBanner({required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 200,
          child: Stack(fit: StackFit.expand, children: [
            Image.asset('assets/bm/storefront.webp', fit: BoxFit.cover),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xE6071C21)]),
              ),
            ),
            const Positioned(
              left: 18,
              right: 18,
              bottom: 14,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('PRESENTED WITH',
                    style: TextStyle(fontSize: 13, letterSpacing: 2, fontWeight: FontWeight.w800, color: KoiColors.gold)),
                Text('B&M Aquatics', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                Text('Family owned since 2003 · Hamburg, NJ', style: TextStyle(fontSize: 16, color: KoiColors.cream)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

/// The pond as a full-screen toy: an extra, not the main event.
class PondToyScreen extends StatelessWidget {
  final List<Variety> varieties;
  const PondToyScreen({super.key, required this.varieties});
  @override
  Widget build(BuildContext context) => Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Koi Pond'),
        ),
        body: Stack(fit: StackFit.expand, children: [
          KoiPond(varieties: varieties, fishCount: 10),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 30,
            child: IgnorePointer(
              child: Text('Tap to feed · drag to scatter',
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 17, color: KoiColors.mist)),
            ),
          ),
        ]),
      );
}
