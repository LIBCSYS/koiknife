// Name That Koi — ten photo rounds.
//
// Distractors come from each variety's "often confused with" list first, so
// the quiz teaches the real distinctions (Sanke vs Showa) instead of letting
// you pass by elimination.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data.dart';
import '../main.dart';
import '../theme.dart';
import 'varieties.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});
  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  static const rounds = 10;
  final _rng = math.Random();
  List<Variety> _deck = [];
  int _round = 0, _score = 0, _best = 0;
  List<Variety> _options = [];
  Variety? _picked;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) { if (mounted) setState(() => _best = p.getInt('quiz.best') ?? 0); });
  }

  void _start(List<Variety> all) {
    final photo = all.where((v) => v.hasPhoto).toList()..shuffle(_rng);
    setState(() {
      _deck = photo.take(rounds).toList();
      _round = 0;
      _score = 0;
      _started = true;
      _deal(all);
    });
  }

  void _deal(List<Variety> all) {
    final answer = _deck[_round];
    final pool = all.where((v) => v.slug != answer.slug && v.hasPhoto).toList()..shuffle(_rng);
    // Lookalikes first: they are what people actually mix up.
    pool.sort((a, b) {
      int s(Variety v) => answer.confused.any((n) => isNamed(v, n)) ? 0 : 1;
      return s(a) - s(b);
    });
    _options = [answer, ...pool.take(3)]..shuffle(_rng);
    _picked = null;
  }

  Future<void> _pick(Variety v) async {
    if (_picked != null) return;
    setState(() {
      _picked = v;
      if (v.slug == _deck[_round].slug) _score++;
    });
  }

  Future<void> _next(List<Variety> all) async {
    if (_round + 1 >= _deck.length) {
      if (_score > _best) {
        _best = _score;
        (await SharedPreferences.getInstance()).setInt('quiz.best', _best);
      }
      setState(() => _round = _deck.length);
      return;
    }
    setState(() {
      _round++;
      _deal(all);
    });
  }

  @override
  Widget build(BuildContext context) {
    final all = KoiScope.of(context).data.varieties;
    final t = Theme.of(context).textTheme;

    if (!_started) return _intro(context, all);
    if (_round >= _deck.length) return _results(context, all);

    final answer = _deck[_round];
    final done = _picked != null;
    final right = done && _picked!.slug == answer.slug;

    return SafeArea(
      child: ListView(padding: const EdgeInsets.fromLTRB(20, 14, 20, 30), children: [
        Readable(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Text('Round ${_round + 1} of ${_deck.length}', style: t.titleMedium),
              const Spacer(),
              Text('Score $_score', style: t.titleMedium?.copyWith(color: KoiColors.gold)),
            ]),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                  value: (_round + (done ? 1 : 0)) / _deck.length, minHeight: 8, color: KoiColors.red),
            ),
            const SizedBox(height: 16),
            Text('Name that koi', style: t.headlineMedium),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: Container(
                  color: KoiColors.pond,
                  child: Image.asset(answer.image, fit: BoxFit.cover, key: ValueKey(answer.slug)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            for (final o in _options)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _OptionButton(
                  label: '${o.name}  ${o.kanji}',
                  state: !done
                      ? 0
                      : o.slug == answer.slug
                          ? 1
                          : o.slug == _picked!.slug
                              ? 2
                              : 3,
                  onTap: () => _pick(o),
                ),
              ),
            if (done) ...[
              const SizedBox(height: 8),
              Card(
                color: (right ? KoiColors.leaf : KoiColors.red).withValues(alpha: 0.18),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(right ? 'Yes! ${answer.name}.' : 'That\'s a ${answer.name}.', style: t.titleLarge),
                    const SizedBox(height: 6),
                    Text(answer.blurb, style: t.bodyLarge),
                  ]),
                ),
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: () => _next(all),
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18)),
                child: Text(_round + 1 >= _deck.length ? 'See my score' : 'Next koi',
                    style: const TextStyle(fontSize: 19)),
              ),
            ],
          ]),
        ),
      ]),
    );
  }

  Widget _intro(BuildContext context, List<Variety> all) {
    final t = Theme.of(context).textTheme;
    return SafeArea(
      child: Center(
        child: Readable(
          max: 560,
          child: Padding(
            padding: gutter,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('🎏', style: TextStyle(fontSize: 76)),
              const SizedBox(height: 12),
              Text('Name That Koi', style: t.displaySmall, textAlign: TextAlign.center),
              const SizedBox(height: 10),
              Text(
                  'Ten real photographs. The wrong answers are the fish people genuinely mix up, so a good score means you can tell a Sanke from a Showa at the pond.',
                  textAlign: TextAlign.center,
                  style: t.bodyLarge?.copyWith(color: KoiColors.mist)),
              const SizedBox(height: 22),
              if (_best > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Text('Your best: $_best / $rounds', style: t.titleMedium?.copyWith(color: KoiColors.gold)),
                ),
              FilledButton.icon(
                onPressed: () => _start(all),
                icon: const Icon(Icons.play_arrow_rounded, size: 28),
                label: const Text('Start', style: TextStyle(fontSize: 20)),
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 18)),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _results(BuildContext context, List<Variety> all) {
    final t = Theme.of(context).textTheme;
    final verdict = _score == rounds
        ? 'Perfect. You could judge at Niigata.'
        : _score >= 8
            ? 'Excellent eye. B&M would hire you.'
            : _score >= 5
                ? 'Solid. The Gosanke are coming together.'
                : 'Every expert started here. Browse the guide and try again.';
    return SafeArea(
      child: Center(
        child: Readable(
          max: 560,
          child: Padding(
            padding: gutter,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('$_score / ${_deck.length}', style: t.displaySmall?.copyWith(fontSize: 64, color: KoiColors.gold)),
              const SizedBox(height: 8),
              Text(verdict, textAlign: TextAlign.center, style: t.titleLarge),
              const SizedBox(height: 8),
              Text('Best: $_best', style: t.titleMedium?.copyWith(color: KoiColors.mist)),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => _start(all),
                icon: const Icon(Icons.replay_rounded),
                label: const Text('Play again', style: TextStyle(fontSize: 19)),
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16)),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () =>
                    Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(
                        appBar: AppBar(title: const Text('Varieties')), body: const VarietiesScreen(wishOnly: false)))),
                child: const Text('Study the varieties', style: TextStyle(fontSize: 18)),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  final String label;
  final int state; // 0 open, 1 correct, 2 wrong pick, 3 other
  final VoidCallback onTap;
  const _OptionButton({required this.label, required this.state, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bg = switch (state) {
      1 => KoiColors.leaf,
      2 => KoiColors.red,
      _ => KoiColors.surface,
    };
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: state == 0 ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            child: Row(children: [
              Expanded(
                child: Text(label,
                    style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                        color: state == 3 ? KoiColors.mist : KoiColors.cream)),
              ),
              if (state == 1) const Icon(Icons.check_circle_rounded, color: Colors.white),
              if (state == 2) const Icon(Icons.cancel_rounded, color: Colors.white),
            ]),
          ),
        ),
      ),
    );
  }
}
