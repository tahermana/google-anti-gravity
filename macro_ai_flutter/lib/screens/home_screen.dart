import 'package:flutter/material.dart';
import '../models/app_state.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/calorie_ring.dart';
import '../widgets/macro_card.dart';
import '../widgets/stat_chip.dart';
import '../widgets/ai_tip_card.dart';
import '../widgets/meal_list.dart';
import '../widgets/add_meal_sheet.dart';

class HomeScreen extends StatelessWidget {
  final AppState state;
  final VoidCallback? onOpenProfile;
  const HomeScreen({super.key, required this.state, this.onOpenProfile});

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning,';
    if (h < 18) return 'Good afternoon,';
    return 'Good evening,';
  }

  String get _aiTipMessage {
    final remainingProtein = state.proteinTarget - state.proteinCurrent;
    if (remainingProtein <= 0) {
      return 'Protein target reached — keep the rest of your meals balanced today.';
    }
    return '${remainingProtein}g short on protein — add chicken or Greek yogurt to hit your goal.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ───────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_greeting, style: kStyleGreeting),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              SupabaseService.currentUser != null
                                  ? SupabaseService.displayName.split(' ').first
                                  : 'User',
                              style: kStyleUserName,
                            ),
                            const SizedBox(width: 6),
                            const _WaveEmoji(),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Avatar
                  GestureDetector(
                    onTap: onOpenProfile,
                    child: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: kAccent,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: kAccent.withOpacity(0.35), blurRadius: 10)],
                      ),
                      child: Center(
                        child: Text(
                          SupabaseService.currentUser != null
                              ? SupabaseService.initials
                              : 'AM',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Scrollable body ───────────────────────────────────────────────
            Expanded(
              child: ListenableBuilder(
                listenable: state,
                builder: (context, _) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Calorie card
                        _Card(
                          child: CalorieRing(
                            eaten:    state.eaten,
                            burned:   state.burned,
                            goal:     state.goal,
                            kcalLeft: state.kcalLeft,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Macros row
                        Row(
                          children: [
                            Expanded(child: MacroCard(
                              label: 'PROTEIN',
                              value: '${state.proteinCurrent}g',
                              barColor: kProtein,
                              progress: state.proteinTarget > 0
                                  ? (state.proteinCurrent / state.proteinTarget).clamp(0.0, 1.0)
                                  : 0.0,
                            )),
                            const SizedBox(width: 10),
                            Expanded(child: MacroCard(
                              label: 'CARBS',
                              value: '${state.carbsCurrent}g',
                              barColor: kCarbs,
                              progress: state.carbsTarget > 0
                                  ? (state.carbsCurrent / state.carbsTarget).clamp(0.0, 1.0)
                                  : 0.0,
                            )),
                            const SizedBox(width: 10),
                            Expanded(child: MacroCard(
                              label: 'FAT',
                              value: '${state.fatCurrent}g',
                              barColor: kFat,
                              progress: state.fatTarget > 0
                                  ? (state.fatCurrent / state.fatTarget).clamp(0.0, 1.0)
                                  : 0.0,
                            )),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Stats row
                        Row(
                          children: [
                            Expanded(child: StatChip(icon: '💧', value: '${state.water}L',  label: 'WATER')),
                            const SizedBox(width: 10),
                            Expanded(child: StatChip(icon: '⚡', value: state.burned.toString(), label: 'BURNED')),
                            const SizedBox(width: 10),
                            Expanded(child: StatChip(icon: '🔥', value: state.steps.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},'), label: 'STEPS')),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // AI tip
                        if (state.aiEnabled) AiTipCard(message: _aiTipMessage),

                        // Meals header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("TODAY'S MEALS", style: kStyleSectionTitle),
                            GestureDetector(
                              onTap: () => showAddMealSheet(context, state),
                              child: const Text('+ Scan food',
                                style: TextStyle(fontSize: 13, color: kAccent, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Meal list
                        MealList(meals: state.meals),

                        // Add meal button
                        GestureDetector(
                          onTap: () => showAddMealSheet(context, state),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: kAccent.withOpacity(0.35),
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('+  Log a meal',
                                  style: TextStyle(color: kAccent, fontSize: 14, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Card wrapper ───────────────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kBorder),
      ),
      child: child,
    );
  }
}

// ── Wave emoji ─────────────────────────────────────────────────────────────────
class _WaveEmoji extends StatefulWidget {
  const _WaveEmoji();
  @override
  State<_WaveEmoji> createState() => _WaveEmojiState();
}

class _WaveEmojiState extends State<_WaveEmoji> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _rot;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500))
      ..repeat();
    _rot = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.24),  weight: 10),
      TweenSequenceItem(tween: Tween(begin: 0.24, end: -0.14), weight: 10),
      TweenSequenceItem(tween: Tween(begin: -0.14, end: 0.24), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 0.24, end: -0.07), weight: 10),
      TweenSequenceItem(tween: Tween(begin: -0.07, end: 0.17), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 0.17, end: 0.0),  weight: 10),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.0),   weight: 40),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.linear));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _rot,
      builder: (_, child) => Transform.rotate(
        angle: _rot.value,
        alignment: Alignment.bottomCenter,
        child: child,
      ),
      child: const Text('👋', style: TextStyle(fontSize: 24)),
    );
  }
}
