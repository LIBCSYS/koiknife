// Small shared pieces used across screens.
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'data.dart';
import 'main.dart';
import 'pond.dart';
import 'theme.dart';

/// A variety's picture: the real photograph when a freely-licensed one exists,
/// otherwise a living painted portrait in the variety's true colours. We never
/// substitute a lookalike photo — a wrong fish in a field guide is worse than none.
class KoiImage extends StatelessWidget {
  final Variety v;
  final BoxFit fit;
  final bool hero;
  const KoiImage(this.v, {super.key, this.fit = BoxFit.cover, this.hero = true});

  @override
  Widget build(BuildContext context) {
    final Widget img = v.hasPhoto
        ? Image.asset(v.image, fit: fit, width: double.infinity, height: double.infinity)
        : Stack(fit: StackFit.expand, children: [
            KoiPond(varieties: [v], fishCount: 1, lilies: false),
            const Positioned(
              left: 10,
              bottom: 8,
              child: Text('Illustration',
                  style: TextStyle(fontSize: 13, color: KoiColors.mist, fontStyle: FontStyle.italic)),
            ),
          ]);
    return hero ? Hero(tag: 'koi-${v.slug}', child: img) : img;
  }
}

class WishButton extends StatelessWidget {
  final String slug;
  final double size;
  const WishButton(this.slug, {super.key, this.size = 28});

  @override
  Widget build(BuildContext context) {
    final wish = KoiScope.of(context).wish;
    final on = wish.has(slug);
    return IconButton(
      tooltip: on ? 'Remove from My Koi' : 'Add to My Koi',
      iconSize: size,
      onPressed: () {
        wish.toggle(slug);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text(on ? 'Removed from My Koi' : 'Added to My Koi ♥',
                style: const TextStyle(fontSize: 18)),
            duration: const Duration(milliseconds: 1400),
          ));
      },
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
        child: Icon(on ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            key: ValueKey(on), color: on ? KoiColors.red : KoiColors.cream),
      ),
    );
  }
}

class RarityDots extends StatelessWidget {
  final int rarity;
  const RarityDots(this.rarity, {super.key});
  static const labels = ['', 'Common', 'Easy to find', 'Uncommon', 'Scarce', 'Rare'];
  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Rarity: ${labels[rarity]}',
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          for (var i = 1; i <= 5; i++)
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i <= rarity ? KoiColors.gold : KoiColors.mist.withValues(alpha: 0.25)),
            ),
          const SizedBox(width: 6),
          Text(labels[rarity], style: const TextStyle(fontSize: 15, color: KoiColors.mist)),
        ]),
      );
}

class ColorSwatches extends StatelessWidget {
  final List<Color> colors;
  const ColorSwatches(this.colors, {super.key});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        for (final c in colors)
          Container(
            width: 22,
            height: 22,
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24, width: 1.5)),
          ),
      ]);
}

Future<void> openLink(String url) async {
  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}

/// The B&M call-to-action that ends most screens: the app's job is to send
/// people to look at real fish, because you can't judge a koi from a screen.
class VisitBMCard extends StatelessWidget {
  final String lead;
  const VisitBMCard({super.key, this.lead = 'You cannot judge body shape from a photograph.'});

  @override
  Widget build(BuildContext context) {
    final bm = KoiScope.of(context).data.bm;
    return Card(
      color: KoiColors.red.withValues(alpha: 0.16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(lead, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text('Come and look at the fish at ${bm['name']} in Hamburg, NJ.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: KoiColors.mist)),
          const SizedBox(height: 14),
          Wrap(spacing: 10, runSpacing: 10, children: [
            FilledButton.icon(
              onPressed: () => openLink('tel:${bm['tel']}'),
              icon: const Icon(Icons.call_rounded),
              label: Text('Call ${bm['phone']}'),
              style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14)),
            ),
            OutlinedButton.icon(
              onPressed: () => openLink(bm['maps']),
              icon: const Icon(Icons.directions_rounded),
              label: const Text('Directions'),
              style: OutlinedButton.styleFrom(
                  foregroundColor: KoiColors.cream,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14)),
            ),
          ]),
        ]),
      ),
    );
  }
}

/// Full-screen pinch-to-zoom viewer for a photo or artwork.
class PhotoViewer extends StatelessWidget {
  final String asset, title, caption;
  final String? heroTag;
  const PhotoViewer({super.key, required this.asset, required this.title, this.caption = '', this.heroTag});

  @override
  Widget build(BuildContext context) {
    final img = Image.asset(asset, fit: BoxFit.contain);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, title: Text(title)),
      body: Column(children: [
        Expanded(
          child: InteractiveViewer(
            maxScale: 5,
            child: Center(child: heroTag != null ? Hero(tag: heroTag!, child: img) : img),
          ),
        ),
        if (caption.isNotEmpty)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(caption, style: const TextStyle(fontSize: 18, color: KoiColors.mist)),
            ),
          ),
      ]),
    );
  }
}
