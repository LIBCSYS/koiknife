// Visual language: night-pond water, koi red, rice-paper cream.
//
// Type is deliberately large (20px body) — J reads with low vision and pond
// owners skew older; the system text-size setting still scales on top of this.
import 'package:flutter/material.dart';

class KoiColors {
  static const ink = Color(0xFF071C21); // deep water
  static const pond = Color(0xFF0E3238);
  static const surface = Color(0xFF123B42);
  static const card = Color(0xFF17464E);
  static const red = Color(0xFFE2412F); // hi — koi scarlet
  static const gold = Color(0xFFF2C230);
  static const cream = Color(0xFFF5EFE2); // rice paper
  static const mist = Color(0xFFB9CFCC);
  static const leaf = Color(0xFF5C9A3C);
}

ThemeData koiTheme() {
  const scheme = ColorScheme.dark(
    primary: KoiColors.red,
    secondary: KoiColors.gold,
    surface: KoiColors.pond,
    onSurface: KoiColors.cream,
    onPrimary: Colors.white,
  );
  final base = ThemeData(useMaterial3: true, colorScheme: scheme, brightness: Brightness.dark);
  final t = base.textTheme.apply(bodyColor: KoiColors.cream, displayColor: KoiColors.cream);
  return base.copyWith(
    scaffoldBackgroundColor: KoiColors.ink,
    textTheme: t.copyWith(
      displaySmall: t.displaySmall?.copyWith(fontWeight: FontWeight.w800, height: 1.08, fontSize: 38),
      headlineMedium: t.headlineMedium?.copyWith(fontWeight: FontWeight.w800, height: 1.12, fontSize: 30),
      headlineSmall: t.headlineSmall?.copyWith(fontWeight: FontWeight.w700, height: 1.15, fontSize: 25),
      titleLarge: t.titleLarge?.copyWith(fontWeight: FontWeight.w700, fontSize: 23),
      titleMedium: t.titleMedium?.copyWith(fontWeight: FontWeight.w600, fontSize: 20),
      bodyLarge: t.bodyLarge?.copyWith(fontSize: 20, height: 1.5),
      bodyMedium: t.bodyMedium?.copyWith(fontSize: 18, height: 1.45),
      labelLarge: t.labelLarge?.copyWith(fontSize: 17, fontWeight: FontWeight.w700),
    ),
    cardTheme: const CardThemeData(
      color: KoiColors.card,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
      clipBehavior: Clip.antiAlias,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: KoiColors.pond,
      indicatorColor: KoiColors.red.withValues(alpha: 0.25),
      height: 74,
      labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: KoiColors.cream)),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: KoiColors.pond,
      indicatorColor: KoiColors.red.withValues(alpha: 0.25),
      selectedLabelTextStyle: const TextStyle(fontSize: 15, color: KoiColors.cream),
      unselectedLabelTextStyle: const TextStyle(fontSize: 15, color: KoiColors.mist),
    ),
    chipTheme: base.chipTheme.copyWith(
      labelStyle: const TextStyle(fontSize: 16, color: KoiColors.cream),
      backgroundColor: KoiColors.surface,
      selectedColor: KoiColors.red,
      side: BorderSide.none,
      shape: const StadiumBorder(),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: KoiColors.ink,
      foregroundColor: KoiColors.cream,
      elevation: 0,
      titleTextStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: KoiColors.cream),
    ),
  );
}

/// Standard page gutter — J's rule: content never touches the screen edge.
const gutter = EdgeInsets.symmetric(horizontal: 20);

/// Caps reading width on iPad/Mac so lines stay comfortable.
class Readable extends StatelessWidget {
  final Widget child;
  final double max;
  const Readable({super.key, required this.child, this.max = 760});
  @override
  Widget build(BuildContext context) =>
      Center(child: ConstrainedBox(constraints: BoxConstraints(maxWidth: max), child: child));
}

class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(),
      style: const TextStyle(
          fontSize: 14, letterSpacing: 2, fontWeight: FontWeight.w800, color: KoiColors.red));
}
