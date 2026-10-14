// Content models for KoiKnife.
//
// All text lives in assets/data/*.json (mirrored from content/, the source of
// truth) so wording can change without touching widget code. Everything is
// bundled — the app works fully offline, which matters at a pond-side or in a
// greenhouse with one bar of signal.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

class KoiGroup {
  final String id, name, jp, about;
  KoiGroup(Map<String, dynamic> j)
      : id = j['id'],
        name = j['name'],
        jp = j['jp'],
        about = j['about'];
}

class Variety {
  final String slug, name, kanji, group, price, blurb, fact;
  final String? photo; // null → painted illustration (no free photo exists)
  final bool est; // price is our estimate, not from B&M's own guide
  final int rarity; // 1 common … 5 rare
  final List<Color> colors; // drives card gradients and the pond fish
  final List<String> confused;

  Variety(Map<String, dynamic> j)
      : slug = j['slug'],
        name = j['name'],
        kanji = j['kanji'],
        group = j['group'],
        photo = j['photo'],
        price = j['price'],
        blurb = j['blurb'],
        fact = j['fact'],
        est = j['est'] ?? false,
        rarity = j['rarity'] ?? 2,
        colors = (j['colors'] as List).map((h) => hex(h as String)).toList(),
        confused = List<String>.from(j['confused'] ?? const []);

  bool get hasPhoto => photo != null;
  String get image => 'assets/koi/$photo.jpg';
}

class GradeRow {
  final String grade;
  final List<String> bands;
  final double lo, hi;
  GradeRow(Map<String, dynamic> j)
      : grade = j['grade'],
        bands = List<String>.from(j['bands']),
        lo = (j['lo'] as num).toDouble(),
        hi = (j['hi'] as num).toDouble();
}

class Chapter {
  final int n;
  final String title, kicker, image, caption;
  final List<String> body;
  final String calloutKind, calloutText;
  Chapter(Map<String, dynamic> j)
      : n = j['n'],
        title = j['title'],
        kicker = j['kicker'],
        image = j['image'],
        caption = j['caption'],
        body = List<String>.from(j['body']),
        calloutKind = j['callout']['kind'],
        calloutText = j['callout']['text'];
  String get imagePath => 'assets/history/$image.webp';
}

class Artwork {
  final String image, title, artist, text;
  Artwork(Map<String, dynamic> j)
      : image = j['image'],
        title = j['title'],
        artist = j['artist'],
        text = j['text'];
  String get imagePath => 'assets/history/$image.webp';
}

class Credit {
  final String what, file, artist, licence, page;
  Credit(Map<String, dynamic> j)
      : what = j['what'] ?? j['slug'] ?? '',
        file = j['file'] ?? '',
        artist = j['artist'] ?? '',
        licence = j['licence'] ?? '',
        page = j['page'] ?? '';
}

/// Everything the app shows, loaded once at start-up.
class KoiData {
  late List<KoiGroup> groups;
  late List<Variety> varieties;
  late List<String> sizes;
  late List<GradeRow> grades;
  late String gradeNote;
  late Map<String, dynamic> history;
  late List<Chapter> chapters;
  late List<Artwork> art;
  late Map<String, dynamic> bm;
  late Map<String, dynamic> supplies;
  late List<Credit> credits;

  static Future<KoiData> load() async {
    final d = KoiData();
    final v = jsonDecode(await rootBundle.loadString('assets/data/varieties.json'));
    d.groups = (v['groups'] as List).map((g) => KoiGroup(g)).toList();
    d.varieties = (v['varieties'] as List).map((x) => Variety(x)).toList();
    d.sizes = List<String>.from(v['grades']['sizes']);
    d.grades = (v['grades']['rows'] as List).map((r) => GradeRow(r)).toList();
    d.gradeNote = v['grades']['note'];
    d.history = jsonDecode(await rootBundle.loadString('assets/data/history.json'));
    d.chapters = (d.history['chapters'] as List).map((c) => Chapter(c)).toList();
    d.art = (d.history['art'] as List).map((a) => Artwork(a)).toList();
    d.bm = jsonDecode(await rootBundle.loadString('assets/data/bm.json'));
    d.supplies = jsonDecode(await rootBundle.loadString('assets/data/supplies.json'));
    d.credits = (jsonDecode(await rootBundle.loadString('assets/data/credits.json')) as List)
        .map((c) => Credit(c))
        .toList();
    return d;
  }

  KoiGroup group(String id) => groups.firstWhere((g) => g.id == id);
}

/// The wishlist ("My Koi"). Stored on-device only — no account, nothing leaves
/// the phone — via shared_preferences, which maps to NSUserDefaults on Apple
/// and SharedPreferences on Android.
class Wishlist extends ChangeNotifier {
  static const _key = 'wishlist.v1';
  final Set<String> _slugs = {};
  SharedPreferences? _prefs;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    _slugs.addAll(_prefs!.getStringList(_key) ?? const []);
  }

  bool has(String slug) => _slugs.contains(slug);
  int get count => _slugs.length;
  Set<String> get slugs => Set.unmodifiable(_slugs);

  void toggle(String slug) {
    _slugs.contains(slug) ? _slugs.remove(slug) : _slugs.add(slug);
    _prefs?.setStringList(_key, _slugs.toList());
    notifyListeners();
  }
}

Color hex(String h) => Color(int.parse('FF${h.replaceFirst('#', '')}', radix: 16));
