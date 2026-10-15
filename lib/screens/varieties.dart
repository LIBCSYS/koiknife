// Varieties: the field guide. Grid → detail, with search, group filters and the
// "My Koi" wishlist filter.
import 'package:flutter/material.dart';

import '../data.dart';
import '../main.dart';
import '../theme.dart';
import '../widgets.dart';
import 'guide.dart';

class VarietiesScreen extends StatefulWidget {
  final bool wishOnly;
  const VarietiesScreen({super.key, this.wishOnly = false});
  @override
  State<VarietiesScreen> createState() => _VarietiesScreenState();
}

class _VarietiesScreenState extends State<VarietiesScreen> {
  String _group = 'all';
  String _q = '';

  @override
  void initState() {
    super.initState();
    if (widget.wishOnly) _group = 'wish';
  }

  @override
  Widget build(BuildContext context) {
    final scope = KoiScope.of(context);
    final d = scope.data;
    final q = _q.toLowerCase();
    final list = d.varieties.where((v) {
      if (_group == 'wish' && !scope.wish.has(v.slug)) return false;
      if (_group != 'all' && _group != 'wish' && v.group != _group) return false;
      if (q.isEmpty) return true;
      return v.name.toLowerCase().contains(q) || v.kanji.contains(_q) || v.blurb.toLowerCase().contains(q);
    }).toList();

    final width = MediaQuery.sizeOf(context).width;
    final cols = width >= 1200 ? 4 : width >= 760 ? 3 : 2;

    return Scaffold(
      appBar: widget.wishOnly ? AppBar(title: const Text('My Koi')) : null,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(slivers: [
          if (!widget.wishOnly)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const SectionLabel('Koi guide · 品種'),
                  const SizedBox(height: 6),
                  Text('Know what you\'re looking at.', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text(
                      'More than 150 named varieties exist. Here are the ${d.varieties.length} you will actually meet, and why one costs \$40 and the one beside it \$400.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: KoiColors.mist)),
                  const SizedBox(height: 14),
                  TextField(
                    onChanged: (s) => setState(() => _q = s),
                    style: const TextStyle(fontSize: 19),
                    decoration: InputDecoration(
                      hintText: 'Search Kohaku, 紅白, metallic…',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: KoiColors.surface,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                        context, MaterialPageRoute(builder: (_) => const PriceScreen())),
                    icon: const Icon(Icons.sell_rounded),
                    label: const Text('Price guide: Pond grade → Show koi'),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: KoiColors.gold,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                  ),
                ]),
              ),
            ),
          if (!widget.wishOnly)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 58,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  children: [
                    _chip('all', 'All ${d.varieties.length}'),
                    _chip('wish', '♥ My Koi ${scope.wish.count}'),
                    for (final g in d.groups) _chip(g.id, g.name),
                  ],
                ),
              ),
            ),
          if (_group != 'all' && _group != 'wish' && !widget.wishOnly)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Text('${d.group(_group).jp}  ${d.group(_group).about}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: KoiColors.mist)),
              ),
            ),
          if (list.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    _group == 'wish'
                        ? 'No koi saved yet.\nTap the ♥ on any variety to start your list, then show it to B&M on your next visit.'
                        : 'No koi match "$_q".',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: KoiColors.mist),
                  ),
                ),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols, mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: 0.68),
              delegate: SliverChildBuilderDelegate((c, i) => VarietyCard(list[i]), childCount: list.length),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _chip(String id, String label) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: _group == id,
          showCheckmark: false,
          onSelected: (_) => setState(() => _group = id),
        ),
      );
}

class VarietyCard extends StatelessWidget {
  final Variety v;
  const VarietyCard(this.v, {super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VarietyDetail(v))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(
            child: Stack(fit: StackFit.expand, children: [
              Container(color: KoiColors.pond, child: KoiImage(v)),
              Positioned(
                top: 2,
                right: 2,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(30)),
                  child: WishButton(v.slug, size: 24),
                ),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(v.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
              Text(v.kanji, style: const TextStyle(fontSize: 16, color: KoiColors.mist)),
              const SizedBox(height: 6),
              Text(v.price + (v.est ? ' est.' : ''),
                  style: const TextStyle(fontSize: 16, color: KoiColors.gold, fontWeight: FontWeight.w700)),
            ]),
          ),
        ]),
      ),
    );
  }
}

class VarietyDetail extends StatelessWidget {
  final Variety v;
  const VarietyDetail(this.v, {super.key});

  @override
  Widget build(BuildContext context) {
    final d = KoiScope.of(context).data;
    final g = d.group(v.group);
    final t = Theme.of(context).textTheme;
    final h = MediaQuery.sizeOf(context).height;
    final related = {
      for (final name in v.confused)
        ...d.varieties.where((x) => isNamed(x, name))
    }.where((x) => x.slug != v.slug).toList();

    return Scaffold(
      body: CustomScrollView(slivers: [
        SliverAppBar(
          expandedHeight: h * 0.5,
          pinned: true,
          backgroundColor: KoiColors.ink,
          actions: [WishButton(v.slug)],
          flexibleSpace: FlexibleSpaceBar(
            background: GestureDetector(
              onTap: v.hasPhoto
                  ? () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => PhotoViewer(
                              asset: v.image, title: v.name, heroTag: 'koi-${v.slug}')))
                  : null,
              child: Container(color: KoiColors.pond, child: KoiImage(v, fit: BoxFit.cover)),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Readable(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SectionLabel('${g.name} · ${g.jp}'),
                const SizedBox(height: 6),
                Text(v.name, style: t.displaySmall),
                Text(v.kanji, style: t.headlineSmall?.copyWith(color: KoiColors.mist, fontWeight: FontWeight.w400)),
                const SizedBox(height: 14),
                Wrap(spacing: 10, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center,
                    children: [ColorSwatches(v.colors), RarityDots(v.rarity)]),
                const SizedBox(height: 18),
                Text(v.blurb, style: t.bodyLarge),
                const SizedBox(height: 22),
                _PriceCard(v),
                const SizedBox(height: 18),
                Card(
                  color: KoiColors.gold.withValues(alpha: 0.12),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Icon(Icons.lightbulb_rounded, color: KoiColors.gold, size: 28),
                      const SizedBox(width: 12),
                      Expanded(child: Text(v.fact, style: t.bodyLarge)),
                    ]),
                  ),
                ),
                if (v.confused.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  Text('Often confused with', style: t.titleMedium),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final r in related)
                      ActionChip(
                        label: Text(r.name),
                        onPressed: () => Navigator.pushReplacement(
                            context, MaterialPageRoute(builder: (_) => VarietyDetail(r))),
                      ),
                    for (final name in v.confused.where(
                        (n) => !related.any((r) => isNamed(r, n))))
                      Chip(label: Text(name)),
                  ]),
                ],
                const SizedBox(height: 22),
                Text(g.about, style: t.bodyMedium?.copyWith(color: KoiColors.mist)),
                const SizedBox(height: 22),
                const VisitBMCard(),
                const SizedBox(height: 16),
                Text(
                    v.hasPhoto
                        ? 'Reference photograph, not B&M stock. Freely licensed from Wikimedia Commons. See Credits.'
                        : 'No freely-licensed photograph of a ${v.name} exists, so this is a painted illustration in the variety\'s colours.',
                    style: const TextStyle(fontSize: 14, color: KoiColors.mist)),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}

/// Price for this variety plus the grade ladder, so a reader sees at a glance
/// that grade and size matter far more than variety below 12".
class _PriceCard extends StatelessWidget {
  final Variety v;
  const _PriceCard(this.v);

  @override
  Widget build(BuildContext context) {
    final d = KoiScope.of(context).data;
    final t = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.sell_rounded, color: KoiColors.gold),
            const SizedBox(width: 10),
            Text('Typical 6–8″', style: t.titleMedium),
          ]),
          const SizedBox(height: 4),
          Text(v.price, style: t.headlineSmall?.copyWith(color: KoiColors.gold)),
          if (v.est)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text('Estimate. Ask B&M for actual pricing.',
                  style: TextStyle(fontSize: 14, color: KoiColors.mist)),
            ),
          const Divider(height: 26),
          Text('By grade, at 6–8″', style: t.titleMedium),
          const SizedBox(height: 10),
          for (final r in d.grades)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(children: [
                Expanded(child: Text(r.grade, style: const TextStyle(fontSize: 17))),
                const SizedBox(width: 8),
                Text(r.bands[1],
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: KoiColors.cream)),
              ]),
            ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PriceScreen())),
            child: const Text('Why two koi the same size cost wildly different money →'),
          ),
        ]),
      ),
    );
  }
}
