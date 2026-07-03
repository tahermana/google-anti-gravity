import 'package:flutter/material.dart';

// ── Colour Tokens (Dark theme — restored) ─────────────────────────────────────
const kBgBase    = Color(0xFF0D0D0F);
const kBgCard    = Color(0xFF161619);
const kBgCard2   = Color(0xFF1C1C21);
const kBgCard3   = Color(0xFF222228);
const kAccent    = Color(0xFFE63946);
const kAccentDark= Color(0xFF9B1D23);
const kTextPrim  = Color(0xFFF0F0F5);
const kTextSec   = Color(0xFF8E8E9A);
const kTextMuted = Color(0xFF55555F);
const kBorder    = Color(0xFF1E1E26);
const kProtein   = Color(0xFFE63946);
const kCarbs     = Color(0xFFF4A261);
const kFat       = Color(0xFFE9C46A);
const kWater     = Color(0xFF3A86FF);
const kGreen     = Color(0xFF2ECC71);

// ── Radius ────────────────────────────────────────────────────────────────────
const kRadiusLg = Radius.circular(18);
const kRadiusMd = Radius.circular(12);
const kRadiusSm = Radius.circular(8);
const kRadiusXl = Radius.circular(28);

// ── Text Styles ───────────────────────────────────────────────────────────────
const kStyleGreeting    = TextStyle(fontSize: 13, color: kTextSec, fontWeight: FontWeight.w400);
const kStyleUserName    = TextStyle(fontSize: 26, color: kTextPrim, fontWeight: FontWeight.w800, letterSpacing: -0.5);
const kStyleSectionTitle = TextStyle(fontSize: 11, color: kTextSec, fontWeight: FontWeight.w700, letterSpacing: 1.5);
const kStylePageTitle   = TextStyle(fontSize: 22, color: kTextPrim, fontWeight: FontWeight.w800, letterSpacing: -0.5);
const kStyleOnboardTitle = TextStyle(fontSize: 28, color: kTextPrim, fontWeight: FontWeight.w900, letterSpacing: -0.5, height: 1.2);
const kStyleOnboardSub  = TextStyle(fontSize: 15, color: kTextSec, fontWeight: FontWeight.w400, height: 1.4);

// ── Theme ─────────────────────────────────────────────────────────────────────
ThemeData buildAppTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: kBgBase,
    fontFamily: 'Roboto',
    colorScheme: const ColorScheme.dark(
      primary: kAccent,
      surface: kBgCard,
    ),
    useMaterial3: true,
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
    dividerColor: kBorder,
  );
}

// ── Shared Background Widget ──────────────────────────────────────────────────
class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-0.8, -1.0),
          radius: 1.5,
          colors: [
            Color(0xFF2E0C0F), // Dark burgundy glow (restored top-left glow)
            Color(0xFF0D0D0F), // Dark charcoal/black base color
          ],
        ),
      ),
      child: child,
    );
  }
}
