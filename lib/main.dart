// KoiKnife 1.0.2 — the koi guide, presented with B&M Aquatics (Hamburg, NJ).
//
// One Flutter codebase → iPhone, iPad, Mac and Android. iPhone is the primary
// target (J's own device), so layouts are designed phone-first and widen into a
// side rail on iPad/Mac rather than the other way round.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'data.dart';
import 'screens/bm.dart';
import 'screens/guide.dart';
import 'screens/history.dart';
import 'screens/home.dart';
import 'screens/quiz.dart';
import 'screens/supplies.dart';
import 'screens/varieties.dart';
import 'theme.dart';

// Must match pubspec.yaml's version (test/version_test.dart fails the build if they drift).
const appVersion = '1.0.2';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final data = await KoiData.load();
  final wish = Wishlist();
  await wish.load();
  runApp(KoiKnifeApp(data: data, wish: wish));
  if (_shot.isNotEmpty) _captureAndQuit();
}

// Store-screenshot hook (tools/mac_store_shots.sh): --dart-define=KOI_SHOT=<name> makes the app
// photograph its own window at 2x after the pond settles, save <name>.png in its temp folder and
// quit. Needs no Screen Recording permission. Empty (the default) in every store build.
const _shot = String.fromEnvironment('KOI_SHOT');
final _shotKey = GlobalKey();

Future<void> _captureAndQuit() async {
  await Future<void>.delayed(const Duration(seconds: 10));   // images decode, fish spread out
  final boundary = _shotKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = await boundary.toImage(pixelRatio: 2);
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  File('${Directory.systemTemp.path}/$_shot.png').writeAsBytesSync(png!.buffer.asUint8List());
  exit(0);
}

/// Makes data + wishlist reachable from any screen without a state-management package.
class KoiScope extends InheritedNotifier<Wishlist> {
  final KoiData data;
  const KoiScope({super.key, required this.data, required Wishlist wish, required super.child})
      : super(notifier: wish);

  static KoiScope of(BuildContext c) => c.dependOnInheritedWidgetOfExactType<KoiScope>()!;
  Wishlist get wish => notifier!;
}

class KoiKnifeApp extends StatelessWidget {
  final KoiData data;
  final Wishlist wish;
  const KoiKnifeApp({super.key, required this.data, required this.wish});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    return KoiScope(
      data: data,
      wish: wish,
      child: RepaintBoundary(key: _shotKey, child: MaterialApp(
        title: 'KoiKnife',
        debugShowCheckedModeBanner: false,
        theme: koiTheme(),
        home: const Shell(),
      )),
    );
  }
}

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  // Debug/screenshot hook: --dart-define=KOI_TAB=n opens on a given tab.
  int _tab = const int.fromEnvironment('KOI_TAB');

  static const _dests = [
    (Icons.home_rounded, 'Home'),
    (Icons.search_rounded, 'Identify'),
    (Icons.auto_stories_rounded, 'History'),
    (Icons.sell_rounded, 'Prices'),
    (Icons.inventory_2_rounded, 'Supplies'),
  ];

  void go(int i) => setState(() => _tab = i);

  // Screenshot hook: --dart-define=KOI_ROUTE=variety:kohaku | chapter:3 | bm | feeding | quiz
  // opens that screen on top of the shell. Empty in normal builds.
  static const _route = String.fromEnvironment('KOI_ROUTE');

  @override
  void initState() {
    super.initState();
    if (_route.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final d = KoiScope.of(context).data;
      final parts = _route.split(':');
      final Widget? page = switch (parts.first) {
        'variety' => VarietyDetail(d.varieties.firstWhere((v) => v.slug == parts.last)),
        'chapter' => ChapterReader(start: int.parse(parts.last) - 1),
        'bm' => const BMScreen(),
        'feeding' => const FeedingScreen(),
        'quiz' => const Scaffold(body: QuizScreen()),
        _ => null,
      };
      if (page != null) Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(onGo: go),
      const VarietiesScreen(),
      const HistoryScreen(),
      const PriceScreen(),
      const SuppliesScreen(),
    ];
    // IndexedStack keeps every tab alive; TickerMode stops the ponds on the hidden ones (battery).
    final body = IndexedStack(index: _tab, children: [
      for (var i = 0; i < pages.length; i++) TickerMode(enabled: i == _tab, child: pages[i]),
    ]);
    final wide = MediaQuery.sizeOf(context).width >= 840;

    if (wide) {
      // iPad landscape / Mac: side rail keeps the full width for photos.
      return Scaffold(
        body: Row(children: [
          NavigationRail(
            selectedIndex: _tab,
            onDestinationSelected: go,
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text('鯉', style: TextStyle(fontSize: 34, color: KoiColors.red)),
            ),
            destinations: [
              for (final d in _dests)
                NavigationRailDestination(icon: Icon(d.$1), label: Text(d.$2)),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: body),
        ]),
      );
    }
    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: go,
        destinations: [
          for (final d in _dests) NavigationDestination(icon: Icon(d.$1), label: d.$2),
        ],
      ),
    );
  }
}
