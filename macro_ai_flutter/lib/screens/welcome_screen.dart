import 'dart:async';

import 'package:flutter/material.dart';

import '../main.dart';
import '../models/app_state.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import 'onboarding_flow.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  StreamSubscription<dynamic>? _authSubscription;
  bool _isSigningIn = false;
  bool _isLoadingProfile = false;

  @override
  void initState() {
    super.initState();
    final client = SupabaseService.client;
    if (client == null) return;

    _authSubscription = client.auth.onAuthStateChange.listen((_) {
      if (SupabaseService.currentUser != null) {
        _openSignedInApp();
      }
    });

    if (SupabaseService.currentUser != null) {
      Future.microtask(_openSignedInApp);
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    if (!SupabaseService.isConfigured) {
      _showMessage(
        'Add SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY to enable Google sign-in.',
      );
      return;
    }

    setState(() => _isSigningIn = true);
    try {
      await SupabaseService.signInWithGoogle();
    } catch (_) {
      if (mounted) {
        _showMessage('Google sign-in could not start. Check your Supabase setup.');
      }
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  Future<void> _openSignedInApp() async {
    if (_isLoadingProfile) return;
    _isLoadingProfile = true;

    final AppState? state = await SupabaseService.loadStateForCurrentUser();
    if (!mounted) return;

    if (state == null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingFlow()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => MacroAiApp(
            showOnboarding: false,
            initialState: state,
          ),
        ),
      );
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

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
                                child: Text('🍽️', style: TextStyle(fontSize: 64)),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 30),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
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
                                  Text(
                                    'Scan Food',
                                    style: TextStyle(
                                      color: kTextSec,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
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
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isSigningIn ? null : _signInWithGoogle,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      disabledBackgroundColor: kBgCard3,
                      foregroundColor: const Color(0xFF202124),
                      disabledForegroundColor: kTextMuted,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      elevation: 0,
                    ),
                    child: _isSigningIn
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'G',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Continue with Google',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const OnboardingFlow()),
                  ),
                  child: const Text(
                    'Preview without signing in',
                    style: TextStyle(
                      fontSize: 14,
                      color: kTextSec,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account? ',
                      style: TextStyle(fontSize: 14, color: kTextSec),
                    ),
                    GestureDetector(
                      onTap: _isSigningIn ? null : _signInWithGoogle,
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          fontSize: 14,
                          color: kTextPrim,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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
