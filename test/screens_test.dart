// Smoke test: open every screen at iPhone and iPad sizes and fail on any
// exception — layout overflows surface as FlutterErrors here, which is what
// low-vision large type tends to cause first.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koiknife/data.dart';
import 'package:koiknife/main.dart';
import 'package:koiknife/screens/bm.dart';
import 'package:koiknife/screens/guide.dart';
import 'package:koiknife/screens/history.dart';
import 'package:koiknife/screens/home.dart';
import 'package:koiknife/screens/quiz.dart';
import 'package:koiknife/screens/supplies.dart';
import 'package:koiknife/screens/varieties.dart';
import 'package:koiknife/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late KoiData data;
  late Wishlist wish;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    data = await KoiData.load();
    wish = Wishlist();
    await wish.load();
  });

  Future<void> show(WidgetTester t, Size size, Widget page) async {
    t.view.physicalSize = size * 3;
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(KoiScope(
      data: data,
      wish: wish,
      child: MaterialApp(theme: koiTheme(), home: page),
    ));
    await t.pump(const Duration(milliseconds: 500));
  }

  final sizes = {'iPhone': const Size(402, 874), 'iPad': const Size(1032, 1376)};
  for (final e in sizes.entries) {
    final pages = <String, Widget Function()>{
      'shell': () => const Shell(),
      'home': () => Scaffold(body: HomeScreen(onGo: (_) {})),
      'varieties': () => const VarietiesScreen(),
      'wishlist': () => const VarietiesScreen(wishOnly: true),
      'history': () => const Scaffold(body: HistoryScreen()),
      'chapter': () => const ChapterReader(start: 0),
      'quiz': () => const Scaffold(body: QuizScreen()),
      'prices': () => const PriceScreen(),
      'feeding': () => const FeedingScreen(),
      'buying': () => const BuyingScreen(),
      'supplies': () => const SuppliesScreen(),
      'year': () => const SuppliesScreen(initialTab: 1),
      'water': () => const SuppliesScreen(initialTab: 2),
      'faq': () => const SuppliesScreen(initialTab: 3),
      'bm': () => const BMScreen(),
      'credits': () => const CreditsScreen(),
    };
    for (final p in pages.entries) {
      testWidgets('${p.key} renders on ${e.key}', (t) async => show(t, e.value, p.value()));
    }
    testWidgets('every variety detail renders on ${e.key}', (t) async {
      for (final v in data.varieties) {
        await show(t, e.value, VarietyDetail(v));
      }
    });
    testWidgets('every chapter renders on ${e.key}', (t) async {
      for (var i = 0; i < data.chapters.length; i++) {
        await show(t, e.value, ChapterReader(start: i));
      }
    });
  }
}
