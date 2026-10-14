// The B&M Aquatics tribute: the family, the place, the ethos, and how to get there.
import 'package:flutter/material.dart';

import '../main.dart';
import '../theme.dart';
import '../widgets.dart';
import 'guide.dart';

class BMScreen extends StatelessWidget {
  const BMScreen({super.key});

  static const _photos = [
    ('koi-close', 'Feeding time in the display ponds'),
    ('koi-three', 'Metallic gold, white and ghost koi rising to feed'),
    ('pond', 'A stone-edged koi pond with mature planting'),
    ('falls', 'A multi-stage waterfall over layered rock'),
    ('gardens', 'The display gardens'),
    ('aerial', 'Display ponds, greenhouses and parking from above'),
    ('nursery', 'The plant greenhouse'),
    ('koi-feed', 'Koi at the surface'),
  ];

  @override
  Widget build(BuildContext context) {
    final bm = KoiScope.of(context).data.bm;
    final t = Theme.of(context).textTheme;
    final h = MediaQuery.sizeOf(context).height;

    return Scaffold(
      body: CustomScrollView(slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: h * 0.42,
          backgroundColor: KoiColors.ink,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsetsDirectional.only(start: 56, bottom: 14),
            title: const Text('B&M Aquatics', style: TextStyle(fontWeight: FontWeight.w900)),
            background: Stack(fit: StackFit.expand, children: [
              Image.asset('assets/bm/storefront.webp', fit: BoxFit.cover),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xF0071C21)],
                      stops: [0.5, 1]),
                ),
              ),
            ]),
          ),
        ),
        SliverToBoxAdapter(
          child: Readable(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SectionLabel(bm['since']),
                const SizedBox(height: 6),
                Text(bm['tagline'], style: t.headlineMedium),
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.star_rounded, color: KoiColors.gold),
                  const SizedBox(width: 6),
                  Expanded(child: Text(bm['rating'], style: t.titleMedium?.copyWith(color: KoiColors.gold))),
                ]),
                const SizedBox(height: 16),
                for (final p in bm['story'])
                  Padding(padding: const EdgeInsets.only(bottom: 14), child: Text(p, style: t.bodyLarge)),
              ]),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 250,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _photos.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (c, i) {
                final (file, cap) = _photos[i];
                final asset = 'assets/bm/$file.webp';
                return ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: GestureDetector(
                    onTap: () => Navigator.push(c,
                        MaterialPageRoute(builder: (_) => PhotoViewer(asset: asset, title: 'B&M Aquatics', caption: cap))),
                    child: AspectRatio(aspectRatio: 4 / 3, child: Image.asset(asset, fit: BoxFit.cover)),
                  ),
                );
              },
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Readable(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 40),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // The ethos, set as a pull quote — it's the heart of the tribute.
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: KoiColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: const Border(left: BorderSide(color: KoiColors.red, width: 5)),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('“', style: TextStyle(fontSize: 56, height: 0.8, color: KoiColors.red)),
                    Text(bm['ethos'], style: t.bodyLarge?.copyWith(fontStyle: FontStyle.italic)),
                  ]),
                ),
                const SizedBox(height: 22),
                Text('What you\'ll find there', style: t.headlineSmall),
                const SizedBox(height: 10),
                for (final o in bm['offers'])
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Icon(Icons.water_drop_rounded, size: 20, color: KoiColors.red),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(o, style: t.bodyLarge)),
                    ]),
                  ),
                const SizedBox(height: 22),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Visit', style: t.headlineSmall),
                      const SizedBox(height: 10),
                      _InfoRow(Icons.place_rounded, bm['address']),
                      _InfoRow(Icons.call_rounded, bm['phone']),
                      _InfoRow(Icons.schedule_rounded, bm['hoursNote']),
                      const SizedBox(height: 14),
                      Wrap(spacing: 10, runSpacing: 10, children: [
                        FilledButton.icon(
                          onPressed: () => openLink('tel:${bm['tel']}'),
                          icon: const Icon(Icons.call_rounded),
                          label: const Text('Call'),
                          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14)),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => openLink(bm['maps']),
                          icon: const Icon(Icons.directions_rounded),
                          label: const Text('Directions'),
                          style: OutlinedButton.styleFrom(
                              foregroundColor: KoiColors.cream,
                              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14)),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => openLink(bm['web']),
                          icon: const Icon(Icons.public_rounded),
                          label: const Text('Website'),
                          style: OutlinedButton.styleFrom(
                              foregroundColor: KoiColors.cream,
                              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14)),
                        ),
                      ]),
                    ]),
                  ),
                ),
                const SizedBox(height: 26),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreditsScreen())),
                    child: const Text('Photo credits & about KoiKnife', style: TextStyle(fontSize: 17)),
                  ),
                ),
                Center(
                  child: Text('KoiKnife $appVersion · The Swiss Army Knife of Koi Knowledge',
                      style: const TextStyle(fontSize: 14, color: KoiColors.mist)),
                ),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow(this.icon, this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: KoiColors.mist),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 18))),
        ]),
      );
}
