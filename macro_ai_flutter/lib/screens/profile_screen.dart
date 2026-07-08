import 'package:flutter/material.dart';
import '../models/app_state.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  final AppState state;
  const ProfileScreen({super.key, required this.state});

  /// Format an integer with comma thousands-separator (e.g. 2400 → '2,400').
  static String _formatNumber(int n) {
    return n.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Text('Profile', style: kStylePageTitle),
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: state,
                builder: (context, _) => SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Hero ─────────────────────────────────────────────
                      Center(
                        child: Column(
                          children: [
                            const SizedBox(height: 16),
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: kAccent,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                      color: kAccent.withOpacity(0.4),
                                      blurRadius: 20),
                                  BoxShadow(
                                      color: kAccent.withOpacity(0.15),
                                      blurRadius: 40),
                                ],
                              ),
                              child: const Center(
                                child: Text('AM',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 26,
                                        fontWeight: FontWeight.w800)),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text('Ahmed M.',
                                style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: kTextPrim)),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 5),
                              decoration: BoxDecoration(
                                color: kAccent.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(99),
                                border:
                                    Border.all(color: kAccent.withOpacity(0.3)),
                              ),
                              child: Text('🎯 ${state.userGoal ?? 'Not set'}',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: kAccent,
                                      fontWeight: FontWeight.w600)),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),

                      // ── Body stats row ───────────────────────────────────
                      Row(
                        children: [
                          Expanded(
                              child: _BodyStat(
                            value:
                                '${state.currentWeight.toStringAsFixed(state.currentWeight.truncateToDouble() == state.currentWeight ? 0 : 1)} kg',
                            label: 'Weight',
                          )),
                          const SizedBox(width: 10),
                          Expanded(
                              child: _BodyStat(
                            value: '${state.height} cm',
                            label: 'Height',
                          )),
                          const SizedBox(width: 10),
                          Expanded(
                              child: _BodyStat(
                            value: state.height > 0
                                ? (state.currentWeight /
                                        ((state.height / 100) *
                                            (state.height / 100)))
                                    .toStringAsFixed(1)
                                : '--',
                            label: 'BMI',
                          )),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── Daily Targets ─────────────────────────────────────
                      const _SectionTitle('DAILY TARGETS'),
                      const SizedBox(height: 10),
                      _ProfileField(
                          label: 'Calorie Goal',
                          value: '${_formatNumber(state.goal)} kcal'),
                      _ProfileField(
                          label: 'Protein', value: '${state.proteinTarget}g'),
                      _ProfileField(
                          label: 'Carbs', value: '${state.carbsTarget}g'),
                      _ProfileField(label: 'Fat', value: '${state.fatTarget}g'),
                      const SizedBox(height: 20),

                      // ── Settings ──────────────────────────────────────────
                      const _SectionTitle('SETTINGS'),
                      const SizedBox(height: 10),
                      _ToggleRow(
                        label: 'Meal reminders',
                        value: state.remindersEnabled,
                        onChanged: (_) {
                          state.toggleReminders();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                state.remindersEnabled
                                    ? 'Meal reminders preference enabled'
                                    : 'Meal reminders preference disabled',
                              ),
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                      _ToggleRow(
                        label: 'AI suggestions',
                        value: state.aiEnabled,
                        onChanged: (_) => state.toggleAi(),
                      ),
                      const _ToggleRow(
                        label: 'Dark mode',
                        value: true,
                        onChanged: null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: kStyleSectionTitle);
  }
}

class _BodyStat extends StatelessWidget {
  final String value, label;
  const _BodyStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800, color: kTextPrim)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: kTextSec)),
        ],
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  final String label, value;
  const _ProfileField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: kTextSec)),
          Text(value,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700, color: kTextPrim)),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;
  const _ToggleRow(
      {required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: kTextSec)),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: kAccent,
            trackOutlineColor: MaterialStateProperty.all(Colors.transparent),
          ),
        ],
      ),
    );
  }
}
