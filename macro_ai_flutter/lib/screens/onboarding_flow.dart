import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../models/app_state.dart';
import '../main.dart';
import '../services/supabase_service.dart';

/// Manages the multi-step onboarding and navigates to the main app when done.
class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow>
    with TickerProviderStateMixin {
  int _step = 0;
  static const _totalSteps = 9;

  // ── Collected data ────────────────────────────────────────────────────────
  // Original steps
  String? _sex;
  int _birthMonth = 10;
  int _birthDay = 16;
  int _birthYear = 1999;
  String? _source;

  // Body metrics (editable)
  double _currentWeight = 78.0;
  int _height = 175;

  // New steps
  String? _userGoal;
  final List<String> _obstacles = [];
  double _desiredWeight = 70.0;
  bool? _hasTrainer;
  String? _workoutFrequency;

  // Animation
  late AnimationController _transitionController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _transitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(
      parent: _transitionController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0.06, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _transitionController,
      curve: Curves.easeOutCubic,
    ));
    _transitionController.forward();
  }

  @override
  void dispose() {
    _transitionController.dispose();
    super.dispose();
  }

  void _animateStep(VoidCallback change) {
    _transitionController.reset();
    change();
    _transitionController.forward();
  }

  void _next() {
    HapticFeedback.lightImpact();
    if (_step < _totalSteps - 1) {
      _animateStep(() => setState(() => _step++));
    } else {
      // Done — create AppState with onboarding data and go to main app
      final state = AppState();
      state.applyOnboardingData(
        sex: _sex,
        birthMonth: _birthMonth,
        birthDay: _birthDay,
        birthYear: _birthYear,
        source: _source,
        userGoal: _userGoal,
        obstacles: _obstacles,
        desiredWeight: _desiredWeight,
        hasTrainer: _hasTrainer,
        workoutFrequency: _workoutFrequency,
        currentWeight: _currentWeight,
        height: _height,
      );
      unawaited(SupabaseService.saveProfile(state));
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
            builder: (_) =>
                MacroAiApp(showOnboarding: false, initialState: state)),
      );
    }
  }

  void _back() {
    if (_step > 0) {
      HapticFeedback.lightImpact();
      _animateStep(() => setState(() => _step--));
    }
  }

  bool get _canContinue {
    switch (_step) {
      case 0:
        return _sex != null;
      case 1:
        return true;
      case 2:
        return true;
      case 3:
        return _source != null;
      case 4:
        return _userGoal != null;
      case 5:
        return _obstacles.isNotEmpty;
      case 6:
        return true; // weight always valid
      case 7:
        return _hasTrainer != null;
      case 8:
        return _workoutFrequency != null;
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              // ── Top bar (back + segmented progress) ──────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 24, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _step > 0 ? _back : null,
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 20,
                        color: _step > 0 ? kTextPrim : Colors.transparent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SegmentedProgressBar(
                        totalSteps: _totalSteps,
                        currentStep: _step,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Step content ────────────────────────────────────────────
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: _buildStep(),
                  ),
                ),
              ),

              // ── Continue Button ────────────────────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(
                    24, 12, 24, MediaQuery.of(context).padding.bottom + 16),
                child: _ContinueButton(
                  enabled: _canContinue,
                  onPressed: _canContinue ? _next : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _SexStep(
          key: const ValueKey('sex'),
          selected: _sex,
          onSelect: (v) => setState(() => _sex = v),
        );
      case 1:
        return _DobStep(
          key: const ValueKey('dob'),
          month: _birthMonth,
          day: _birthDay,
          year: _birthYear,
          onChanged: (m, d, y) => setState(() {
            _birthMonth = m;
            _birthDay = d;
            _birthYear = y;
          }),
        );
      case 2:
        return _BodyStep(
          key: const ValueKey('body'),
          weight: _currentWeight,
          height: _height,
          onWeightChanged: (v) => setState(() => _currentWeight = v),
          onHeightChanged: (v) => setState(() => _height = v),
        );
      case 3:
        return _SourceStep(
          key: const ValueKey('source'),
          selected: _source,
          onSelect: (v) => setState(() => _source = v),
        );
      case 4:
        return _GoalStep(
          key: const ValueKey('goal'),
          selected: _userGoal,
          onSelect: (v) => setState(() => _userGoal = v),
        );
      case 5:
        return _ObstaclesStep(
          key: const ValueKey('obstacles'),
          selected: _obstacles,
          onToggle: (v) => setState(() {
            if (_obstacles.contains(v)) {
              _obstacles.remove(v);
            } else {
              _obstacles.add(v);
            }
          }),
        );
      case 6:
        return _DesiredWeightStep(
          key: const ValueKey('desired_weight'),
          goalLabel: _userGoal ?? 'Target',
          weight: _desiredWeight,
          onChanged: (v) => setState(() => _desiredWeight = v),
        );
      case 7:
        return _TrainerStep(
          key: const ValueKey('trainer'),
          selected: _hasTrainer,
          onSelect: (v) => setState(() => _hasTrainer = v),
        );
      case 8:
        return _WorkoutStep(
          key: const ValueKey('workout'),
          selected: _workoutFrequency,
          onSelect: (v) => setState(() => _workoutFrequency = v),
        );
      default:
        return const SizedBox();
    }
  }
}

// ═════════════════════════════════════════════════════════════════════════════════
// SHARED WIDGETS
// ═════════════════════════════════════════════════════════════════════════════════

/// Segmented progress bar — each step is a small bar segment
class _SegmentedProgressBar extends StatelessWidget {
  final int totalSteps;
  final int currentStep;
  const _SegmentedProgressBar(
      {required this.totalSteps, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps, (i) {
        final isCompleted = i <= currentStep;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            height: 4,
            margin: EdgeInsets.only(right: i < totalSteps - 1 ? 3 : 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: isCompleted ? kAccent : kBgCard2,
            ),
          ),
        );
      }),
    );
  }
}

/// Animated continue button with glow when enabled
class _ContinueButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback? onPressed;
  const _ContinueButton({required this.enabled, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: kAccent.withOpacity(0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ]
            : [],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: enabled ? kAccent : kBgCard2,
            disabledBackgroundColor: kBgCard2,
            foregroundColor: Colors.white,
            disabledForegroundColor: kTextMuted,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            elevation: 0,
          ),
          child: const Text('Continue',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════════
// STEP 1 — Choose your sex (original)
// ═════════════════════════════════════════════════════════════════════════════════
class _SexStep extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onSelect;

  const _SexStep({super.key, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Text('Choose your sex', style: kStyleOnboardTitle),
          const SizedBox(height: 8),
          const Text('This helps personalize your experience.',
              style: kStyleOnboardSub),
          const Spacer(),
          for (final option in ['Male', 'Female', 'Other']) ...[
            _OptionPill(
              label: option,
              isSelected: selected == option,
              onTap: () => onSelect(option),
            ),
            const SizedBox(height: 12),
          ],
          const Spacer(),
        ],
      ),
    );
  }
}

class _OptionPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;
  final String? subtitle;

  const _OptionPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? kAccent : kBgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? kAccent : kBorder,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: kAccent.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withOpacity(0.15) : kBgCard2,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon,
                    size: 18, color: isSelected ? Colors.white : kTextPrim),
              ),
              const SizedBox(width: 14),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : kTextPrim,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: isSelected
                            ? Colors.white.withOpacity(0.7)
                            : kTextSec,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (icon == null)
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.white : kTextMuted,
                    width: 2,
                  ),
                  color: isSelected
                      ? Colors.white.withOpacity(0.2)
                      : Colors.transparent,
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════════
// STEP 2 — When were you born? (original)
// ═════════════════════════════════════════════════════════════════════════════════
class _DobStep extends StatelessWidget {
  final int month, day, year;
  final void Function(int month, int day, int year) onChanged;

  const _DobStep({
    super.key,
    required this.month,
    required this.day,
    required this.year,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Text('When were you born?', style: kStyleOnboardTitle),
          const SizedBox(height: 8),
          const Text('This will be used to calibrate your\ncustom plan.',
              style: kStyleOnboardSub),
          const Spacer(),
          SizedBox(
            height: 200,
            child: Row(
              children: [
                Expanded(
                  child: _ScrollPicker(
                    items: const [
                      'January',
                      'February',
                      'March',
                      'April',
                      'May',
                      'June',
                      'July',
                      'August',
                      'September',
                      'October',
                      'November',
                      'December',
                    ],
                    selectedIndex: month,
                    onChanged: (i) => onChanged(i, day, year),
                  ),
                ),
                Expanded(
                  child: _ScrollPicker(
                    items: List.generate(31, (i) => '${i + 1}'),
                    selectedIndex: day - 1,
                    onChanged: (i) => onChanged(month, i + 1, year),
                  ),
                ),
                Expanded(
                  child: _ScrollPicker(
                    items: List.generate(60, (i) => '${1970 + i}'),
                    selectedIndex: year - 1970,
                    onChanged: (i) => onChanged(month, day, 1970 + i),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _ScrollPicker extends StatefulWidget {
  final List<String> items;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _ScrollPicker({
    required this.items,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  State<_ScrollPicker> createState() => _ScrollPickerState();
}

class _ScrollPickerState extends State<_ScrollPicker> {
  late FixedExtentScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        FixedExtentScrollController(initialItem: widget.selectedIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListWheelScrollView.useDelegate(
      controller: _controller,
      itemExtent: 40,
      perspective: 0.003,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: widget.onChanged,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: widget.items.length,
        builder: (context, index) {
          final isSelected = index == widget.selectedIndex;
          return Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: isSelected ? 18 : 15,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w400,
                color: isSelected ? kTextPrim : kTextMuted,
              ),
              child: Text(widget.items[index]),
            ),
          );
        },
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════════
// STEP 3 — Body metrics (original)
// ═════════════════════════════════════════════════════════════════════════════════
class _BodyStep extends StatelessWidget {
  final double weight;
  final int height;
  final ValueChanged<double> onWeightChanged;
  final ValueChanged<int> onHeightChanged;

  const _BodyStep({
    super.key,
    required this.weight,
    required this.height,
    required this.onWeightChanged,
    required this.onHeightChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Text('Your body metrics', style: kStyleOnboardTitle),
          const SizedBox(height: 8),
          const Text('Enter your current weight and height.',
              style: kStyleOnboardSub),
          const Spacer(),
          _MetricInput(
            label: 'Weight',
            unit: 'kg',
            initial: weight.toStringAsFixed(0),
            onChanged: (v) {
              final parsed = double.tryParse(v);
              if (parsed != null && parsed > 0) onWeightChanged(parsed);
            },
          ),
          const SizedBox(height: 16),
          _MetricInput(
            label: 'Height',
            unit: 'cm',
            initial: height.toString(),
            onChanged: (v) {
              final parsed = int.tryParse(v);
              if (parsed != null && parsed > 0) onHeightChanged(parsed);
            },
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _MetricInput extends StatefulWidget {
  final String label, unit, initial;
  final ValueChanged<String>? onChanged;
  const _MetricInput(
      {required this.label,
      required this.unit,
      required this.initial,
      this.onChanged});

  @override
  State<_MetricInput> createState() => _MetricInputState();
}

class _MetricInputState extends State<_MetricInput> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        children: [
          Text(widget.label,
              style: const TextStyle(
                  fontSize: 16, color: kTextSec, fontWeight: FontWeight.w500)),
          const Spacer(),
          SizedBox(
            width: 70,
            child: TextField(
              controller: _ctrl,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
              ],
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontSize: 22, color: kTextPrim, fontWeight: FontWeight.w800),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: widget.onChanged,
            ),
          ),
          const SizedBox(width: 4),
          Text(widget.unit,
              style: const TextStyle(
                  fontSize: 14, color: kTextSec, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════════
// STEP 4 — Where did you hear about us? (original)
// ═════════════════════════════════════════════════════════════════════════════════
class _SourceStep extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onSelect;

  const _SourceStep(
      {super.key, required this.selected, required this.onSelect});

  static const _sources = [
    {'icon': Icons.store, 'label': 'App Store'},
    {'icon': Icons.close, 'label': 'X'},
    {'icon': Icons.group, 'label': 'Friend or family'},
    {'icon': Icons.play_circle_fill, 'label': 'Youtube'},
    {'icon': Icons.search, 'label': 'Google'},
    {'icon': Icons.camera_alt, 'label': 'Instagram'},
    {'icon': Icons.tv, 'label': 'TV'},
    {'icon': Icons.more_horiz, 'label': 'Other'},
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Text('Where did you\nhear about us?',
              style: kStyleOnboardTitle),
          const SizedBox(height: 24),
          for (final src in _sources) ...[
            _SourceTile(
              icon: src['icon'] as IconData,
              label: src['label'] as String,
              isSelected: selected == src['label'],
              onTap: () => onSelect(src['label'] as String),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SourceTile({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: isSelected ? kAccent : kBgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? kAccent : kBorder,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: isSelected ? Colors.white : kTextPrim),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : kTextPrim,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════════
// STEP 5 — What is your goal? (NEW)
// ═════════════════════════════════════════════════════════════════════════════════
class _GoalStep extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onSelect;

  const _GoalStep({super.key, required this.selected, required this.onSelect});

  static const _goals = [
    {'icon': Icons.trending_down_rounded, 'label': 'Lose weight'},
    {'icon': Icons.balance_rounded, 'label': 'Maintain'},
    {'icon': Icons.trending_up_rounded, 'label': 'Gain weight'},
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Text('What is your goal?', style: kStyleOnboardTitle),
          const SizedBox(height: 8),
          const Text('This helps us generate a plan for your\ncalorie intake.',
              style: kStyleOnboardSub),
          const Spacer(),
          for (final goal in _goals) ...[
            _OptionPill(
              icon: goal['icon'] as IconData,
              label: goal['label'] as String,
              isSelected: selected == goal['label'],
              onTap: () => onSelect(goal['label'] as String),
            ),
            const SizedBox(height: 12),
          ],
          const Spacer(),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════════
// STEP 6 — What's stopping you? (NEW — multi-select)
// ═════════════════════════════════════════════════════════════════════════════════
class _ObstaclesStep extends StatelessWidget {
  final List<String> selected;
  final ValueChanged<String> onToggle;

  const _ObstaclesStep(
      {super.key, required this.selected, required this.onToggle});

  static const _obstacles = [
    {'icon': Icons.insights_rounded, 'label': 'Lack of consistency'},
    {'icon': Icons.fastfood_rounded, 'label': 'Unhealthy eating habits'},
    {'icon': Icons.group_off_rounded, 'label': 'Lack of support'},
    {'icon': Icons.calendar_month_rounded, 'label': 'Busy schedule'},
    {
      'icon': Icons.restaurant_menu_rounded,
      'label': 'Lack of meal inspiration'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Text("What's stopping you\nfrom reaching your\ngoals?",
              style: kStyleOnboardTitle),
          const SizedBox(height: 8),
          Text(
            'Select all that apply.',
            style: kStyleOnboardSub.copyWith(
              color: kAccent.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          for (final obs in _obstacles) ...[
            _MultiSelectTile(
              icon: obs['icon'] as IconData,
              label: obs['label'] as String,
              isSelected: selected.contains(obs['label']),
              onTap: () => onToggle(obs['label'] as String),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _MultiSelectTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _MultiSelectTile({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? kAccent : kBgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? kAccent : kBorder,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: kAccent.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.15) : kBgCard2,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon,
                  size: 18, color: isSelected ? Colors.white : kTextPrim),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : kTextPrim,
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected ? Colors.white : kTextMuted,
                  width: 2,
                ),
                color: isSelected
                    ? Colors.white.withOpacity(0.2)
                    : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded,
                      size: 16, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════════
// STEP 7 — Desired weight (NEW — horizontal ruler picker)
// ═════════════════════════════════════════════════════════════════════════════════
class _DesiredWeightStep extends StatefulWidget {
  final String goalLabel;
  final double weight;
  final ValueChanged<double> onChanged;

  const _DesiredWeightStep({
    super.key,
    required this.goalLabel,
    required this.weight,
    required this.onChanged,
  });

  @override
  State<_DesiredWeightStep> createState() => _DesiredWeightStepState();
}

class _DesiredWeightStepState extends State<_DesiredWeightStep> {
  late ScrollController _scrollController;
  static const double _minWeight = 40.0;
  static const double _maxWeight = 150.0;
  static const double _pixelsPerKg = 16.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(
      initialScrollOffset: (widget.weight - _minWeight) * _pixelsPerKg,
    );
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    final newWeight = _minWeight + offset / _pixelsPerKg;
    final clamped = newWeight.clamp(_minWeight, _maxWeight);
    final rounded = (clamped * 2).roundToDouble() / 2; // snap to 0.5
    if (rounded != widget.weight) {
      HapticFeedback.selectionClick();
      widget.onChanged(rounded);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Text('What is your\ndesired weight?',
              style: kStyleOnboardTitle),
          const Spacer(),

          // Goal label
          Center(
            child: Text(
              widget.goalLabel,
              style: kStyleOnboardSub.copyWith(fontSize: 14),
            ),
          ),
          const SizedBox(height: 8),

          // Weight display
          Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: widget.weight, end: widget.weight),
              duration: const Duration(milliseconds: 100),
              builder: (_, val, __) => RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: val.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: kTextPrim,
                        letterSpacing: -1,
                      ),
                    ),
                    const TextSpan(
                      text: ' kg',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: kTextSec,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Ruler
          SizedBox(
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Ruler scroll
                NotificationListener<ScrollNotification>(
                  onNotification: (_) => false,
                  child: ListView.builder(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.of(context).size.width / 2 - 24,
                    ),
                    itemCount: ((_maxWeight - _minWeight) * 2).toInt() + 1,
                    itemBuilder: (context, index) {
                      final value = _minWeight + index * 0.5;
                      final isMajor = value % 5 == 0;
                      final isMinor = value % 1 == 0;

                      return SizedBox(
                        width: _pixelsPerKg / 2,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isMajor)
                                Text(
                                  value.toInt().toString(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: kTextMuted.withOpacity(0.7),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              if (isMajor) const SizedBox(height: 4),
                              Container(
                                width: isMajor ? 2 : (isMinor ? 1.5 : 1),
                                height: isMajor ? 36 : (isMinor ? 24 : 14),
                                decoration: BoxDecoration(
                                  color: isMajor
                                      ? kTextSec.withOpacity(0.6)
                                      : kTextMuted.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Center indicator
                IgnorePointer(
                  child: Container(
                    width: 3,
                    height: 60,
                    decoration: BoxDecoration(
                      color: kAccent,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: kAccent.withOpacity(0.5),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),

                // Gradient fades
                IgnorePointer(
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [kBgBase, kBgBase.withOpacity(0)],
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [kBgBase.withOpacity(0), kBgBase],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════════
// STEP 8 — Personal trainer / dietitian? (NEW — Yes/No)
// ═════════════════════════════════════════════════════════════════════════════════
class _TrainerStep extends StatelessWidget {
  final bool? selected;
  final ValueChanged<bool> onSelect;

  const _TrainerStep(
      {super.key, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Text(
              'Do you currently work\nwith a personal trainer\nor registered dietitian?',
              style: kStyleOnboardTitle),
          const Spacer(),
          _YesNoTile(
            label: 'Yes',
            icon: Icons.check_circle_rounded,
            isSelected: selected == true,
            onTap: () => onSelect(true),
          ),
          const SizedBox(height: 12),
          _YesNoTile(
            label: 'No',
            icon: Icons.cancel_rounded,
            isSelected: selected == false,
            onTap: () => onSelect(false),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _YesNoTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _YesNoTile({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? kAccent : kBgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? kAccent : kBorder,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: kAccent.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.15) : kBgCard2,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : kTextPrim,
              ),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : kTextPrim,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════════
// STEP 9 — How many workouts per week? (NEW)
// ═════════════════════════════════════════════════════════════════════════════════
class _WorkoutStep extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onSelect;

  const _WorkoutStep(
      {super.key, required this.selected, required this.onSelect});

  static const _options = [
    {
      'icon': Icons.fiber_manual_record,
      'value': '0-2',
      'label': '0-2',
      'subtitle': 'Workouts now and then'
    },
    {
      'icon': Icons.grid_view_rounded,
      'value': '3-5',
      'label': '3-5',
      'subtitle': 'A few workouts per week'
    },
    {
      'icon': Icons.apps_rounded,
      'value': '6+',
      'label': '6+',
      'subtitle': 'Dedicated athlete'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Text('How many workouts\ndo you do per week?',
              style: kStyleOnboardTitle),
          const SizedBox(height: 8),
          const Text('This will be used to calibrate your\ncustom plan.',
              style: kStyleOnboardSub),
          const Spacer(),
          for (final opt in _options) ...[
            _OptionPill(
              icon: opt['icon'] as IconData,
              label: opt['label'] as String,
              subtitle: opt['subtitle'] as String,
              isSelected: selected == opt['value'],
              onTap: () => onSelect(opt['value'] as String),
            ),
            const SizedBox(height: 12),
          ],
          const Spacer(),
        ],
      ),
    );
  }
}
