// The on-screen version (Credits page, B&M footer) must be the version the stores receive.
// 1.0.1 (3) shipped saying "1.0.0" because the constant was never bumped; this test stops a repeat.
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:koiknife/main.dart' show appVersion;

void main() {
  test('appVersion matches pubspec.yaml', () {
    final line = File('pubspec.yaml').readAsLinesSync().firstWhere((l) => l.startsWith('version:'));
    final pubspecVersion = line.split(':')[1].trim().split('+').first;
    expect(appVersion, pubspecVersion);
  });
}
