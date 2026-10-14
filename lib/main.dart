// KoiKnife 1.0.0 — the koi guide, presented with B&M Aquatics (Hamburg, NJ).
//
// One Flutter codebase → iPhone, iPad, Mac and Android. iPhone is the primary
// target (J's own device), so layouts are designed phone-first and widen into a
// side rail on iPad/Mac rather than the other way round.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data.dart';
import 'screens/guide.dart';
import 'screens/history.dart';
import 'screens/home.dart';
import 'screens/supplies.dart';
import 'screens/varieties.dart';
import 'theme.dart';

const appVersion = '1.0.0';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final data = await KoiData.load();
  final wish = Wishlist();
  await wish.load();
  runApp(KoiKnifeApp(data: data, wish: wish));
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
      child: MaterialApp(
        title: 'KoiKnife',
        debugShowCheckedModeBanner: false,
        theme: koiTheme(),
        home: const Shell(),
      ),
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

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(onGo: go),
      const VarietiesScreen(),
      const HistoryScreen(),
      const PriceScreen(),
      const SuppliesScreen(),
    ];
    final body = IndexedStack(index: _tab, children: pages);
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
