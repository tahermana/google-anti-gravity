import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'onboarding_flow.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const Spacer(flex: 1),

                // ── Phone mockup area ─────────────────────────────────────────
                Container(
                  height: 380,
                  decoration: BoxDecoration(
                    color: kBgCard,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: kBorder),
                    boxShadow: [
                      BoxShadow(
                        color: kAccent.withOpacity(0.08),
                        blurRadius: 40,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: Container(
                      width: double.infinity,
                      color: kBgCard2,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Scan corners
                            Container(
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: kAccent.withOpacity(0.5),
                                  width: 2,
                                ),
                              ),
                              child: const Center(
                                child: Text('🍽️',
                                    style: TextStyle(fontSize: 64)),
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Bottom bar
                            Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 30),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: kBgCard3,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: kBorder),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.camera_alt,
                                      color: kTextSec, size: 16),
                                  SizedBox(width: 6),
                                  Text('Scan Food',
                                      style: TextStyle(
                                          color: kTextSec,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const Spacer(flex: 1),

                // ── Title ─────────────────────────────────────────────────────
                const Text(
                  'Calorie tracking\nmade easy',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: kTextPrim,
                    letterSpacing: -1,
                    height: 1.15,
                  ),
                ),

                const SizedBox(height: 28),

                // ── Get Started button ────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                          builder: (_) => const OnboardingFlow()),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Get Started',
                      style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Sign in link ──────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account? ',
                        style: TextStyle(fontSize: 14, color: kTextSec)),
                    GestureDetector(
                      onTap: () {},
                      child: const Text('Sign In',
                          style: TextStyle(
                              fontSize: 14,
                              color: kTextPrim,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),

                SizedBox(height: bottom + 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
