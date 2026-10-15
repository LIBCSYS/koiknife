// History: B&M's researched koi history (aquatics.jelia.nyc/koihistory) as ten
// swipeable chapters, plus the woodblock-print gallery.
import 'package:flutter/material.dart';

import '../data.dart';
import '../main.dart';
import '../theme.dart';
import '../widgets.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final d = KoiScope.of(context).data;
    final intro = d.history['intro'];
    final t = Theme.of(context).textTheme;
    final h = MediaQuery.sizeOf(context).height;

    return CustomScrollView(slivers: [
      SliverToBoxAdapter(
        child: SizedBox(
          height: h * 0.52,
          child: Stack(fit: StackFit.expand, children: [
            Image.asset('assets/history/${intro['image']}.webp', fit: BoxFit.cover),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xCC071C21), KoiColors.ink],
                    stops: [0.3, 0.8, 1]),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 18,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SectionLabel('A history of koi · 錦鯉'),
                const SizedBox(height: 8),
                Text(intro['title'], style: t.displaySmall),
              ]),
            ),
          ]),
        ),
      ),
      SliverToBoxAdapter(
        child: Readable(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Text(intro['body'], style: t.bodyLarge?.copyWith(color: KoiColors.mist)),
          ),
        ),
      ),
      SliverList.builder(
        itemCount: d.chapters.length,
        itemBuilder: (c, i) => Readable(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
            child: _ChapterCard(d.chapters[i], i),
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
          child: Readable(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SectionLabel('The carp before the koi'),
              const SizedBox(height: 6),
              Text('Three centuries of printmakers got there first', style: t.headlineSmall),
            ]),
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: SizedBox(
          height: 330,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: d.art.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (c, i) => _ArtCard(d.art[i]),
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: Readable(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 26, 20, 40),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('What survives all this', style: t.headlineSmall),
              const SizedBox(height: 10),
              Text(
                  'A food fish, kept in heating basins by snowed-in rice farmers, in a district so unstable the hillsides periodically slide into the valley. Somebody noticed a coloured one and did not eat it. A hundred years of patient selection later, those fish became the most valuable ornamental animal on earth, and then the mountain fell on the village and they started again.',
                  style: t.bodyLarge),
              const SizedBox(height: 10),
              Text('Nobody needed to embroider that.',
                  style: t.titleMedium?.copyWith(color: KoiColors.gold, fontStyle: FontStyle.italic)),
              const SizedBox(height: 18),
              const Text(
                  'Researched by B&M Aquatics: 107 claims checked against Japanese prefectural records, Chinese dynastic texts, peer-reviewed genetics and the koi associations\' own chronologies.',
                  style: TextStyle(fontSize: 15, color: KoiColors.mist)),
            ]),
          ),
        ),
      ),
    ]);
  }
}

class _ChapterCard extends StatelessWidget {
  final Chapter c;
  final int index;
  const _ChapterCard(this.c, this.index);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChapterReader(start: index))),
        child: SizedBox(
          height: 170,
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SizedBox(
              width: 130,
              child: Hero(tag: 'ch-${c.n}', child: Image.asset(c.imagePath, fit: BoxFit.cover)),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('CHAPTER ${c.n}',
                      style: const TextStyle(
                          fontSize: 13, letterSpacing: 1.8, fontWeight: FontWeight.w800, color: KoiColors.red)),
                  const SizedBox(height: 6),
                  Expanded(
                    child: Text(c.title,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, height: 1.2)),
                  ),
                  Row(children: [
                    _Badge(c.calloutKind),
                    const Spacer(),
                    const Icon(Icons.chevron_right_rounded, color: KoiColors.mist),
                  ]),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String kind;
  const _Badge(this.kind);
  @override
  Widget build(BuildContext context) {
    final myth = kind == 'myth';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: (myth ? KoiColors.red : KoiColors.gold).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(myth ? 'MYTH BUSTED' : 'TRUE STORY',
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
              color: myth ? KoiColors.red : KoiColors.gold)),
    );
  }
}

/// Swipe left/right between chapters, like turning pages.
class ChapterReader extends StatefulWidget {
  final int start;
  const ChapterReader({super.key, required this.start});
  @override
  State<ChapterReader> createState() => _ChapterReaderState();
}

class _ChapterReaderState extends State<ChapterReader> {
  late final PageController _pc = PageController(initialPage: widget.start);
  late int _page = widget.start;

  @override
  void dispose() {
    _pc.dispose();   // the reader is opened and closed many times; don't leak controllers
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chapters = KoiScope.of(context).data.chapters;
    return Scaffold(
      appBar: AppBar(
        title: Text('Chapter ${_page + 1} of ${chapters.length}'),
        backgroundColor: KoiColors.ink,
      ),
      body: PageView.builder(
        controller: _pc,
        itemCount: chapters.length,
        onPageChanged: (p) => setState(() => _page = p),
        itemBuilder: (c, i) => _ChapterPage(chapters[i], isLast: i == chapters.length - 1, onNext: () {
          _pc.nextPage(duration: const Duration(milliseconds: 380), curve: Curves.easeOutCubic);
        }),
      ),
    );
  }
}

class _ChapterPage extends StatelessWidget {
  final Chapter c;
  final bool isLast;
  final VoidCallback onNext;
  const _ChapterPage(this.c, {required this.isLast, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final myth = c.calloutKind == 'myth';
    final accent = myth ? KoiColors.red : KoiColors.gold;
    return ListView(children: [
      GestureDetector(
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => PhotoViewer(asset: c.imagePath, title: 'Chapter ${c.n}', caption: c.caption))),
        child: AspectRatio(
          aspectRatio: 16 / 10,
          child: Hero(tag: 'ch-${c.n}', child: Image.asset(c.imagePath, fit: BoxFit.cover)),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        child: Text(c.caption, style: const TextStyle(fontSize: 15, color: KoiColors.mist, fontStyle: FontStyle.italic)),
      ),
      Readable(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 40),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SectionLabel('Chapter ${c.n} · ${c.kicker}'),
            const SizedBox(height: 8),
            Text(c.title, style: t.headlineMedium),
            const SizedBox(height: 16),
            for (final p in c.body)
              Padding(padding: const EdgeInsets.only(bottom: 14), child: Text(p, style: t.bodyLarge)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(18),
                border: Border(left: BorderSide(color: accent, width: 5)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _Badge(c.calloutKind),
                const SizedBox(height: 10),
                Text(c.calloutText, style: t.bodyLarge),
              ]),
            ),
            const SizedBox(height: 24),
            if (!isLast)
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: onNext,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('Next chapter'),
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
                ),
              )
            else
              const VisitBMCard(lead: 'The story ends at a pond. See one in person.'),
          ]),
        ),
      ),
    ]);
  }
}

class _ArtCard extends StatelessWidget {
  final Artwork a;
  const _ArtCard(this.a);
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 230,
      child: Card(
        child: InkWell(
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      PhotoViewer(asset: a.imagePath, title: a.title, caption: '${a.artist}. ${a.text}'))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Expanded(child: Image.asset(a.imagePath, fit: BoxFit.cover)),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(a.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                Text(a.artist,
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, color: KoiColors.mist)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
