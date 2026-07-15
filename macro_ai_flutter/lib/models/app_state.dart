import 'package:flutter/foundation.dart';

// ── Meal Model ────────────────────────────────────────────────────────────────
class Meal {
  final String name;
  final String type; // Breakfast | Lunch | Dinner | Snack
  final String time;
  final int kcal;
  final String emoji;
  final int protein;
  final int carbs;
  final int fat;

  const Meal({
    required this.name,
    required this.type,
    required this.time,
    required this.kcal,
    required this.emoji,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
  });

  factory Meal.fromSupabaseRow(Map<String, dynamic> row) {
    return Meal(
      name: row['name'] as String? ?? 'Meal',
      type: row['meal_type'] as String? ?? 'Snack',
      time: row['time_text'] as String? ?? '',
      kcal: row['kcal'] as int? ?? 0,
      emoji: row['emoji'] as String? ?? '🍴',
      protein: row['protein'] as int? ?? 0,
      carbs: row['carbs'] as int? ?? 0,
      fat: row['fat'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toSupabaseRow(String userId) {
    return {
      'user_id': userId,
      'name': name,
      'meal_type': type,
      'time_text': time,
      'kcal': kcal,
      'emoji': emoji,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }
}

// ── App State ─────────────────────────────────────────────────────────────────
class AppState extends ChangeNotifier {
  AppState();

  factory AppState.fromSupabase({
    required Map<String, dynamic> profile,
    required List<Map<String, dynamic>> meals,
    required List<Map<String, dynamic>> weeklyCalories,
    required List<Map<String, dynamic>> weightEntries,
  }) {
    final state = AppState()
      ..goal = profile['goal'] as int? ?? 2000
      ..eaten = profile['eaten'] as int? ?? 0
      ..burned = profile['burned'] as int? ?? 0
      ..proteinCurrent = profile['protein_current'] as int? ?? 0
      ..proteinTarget = profile['protein_target'] as int? ?? 150
      ..carbsCurrent = profile['carbs_current'] as int? ?? 0
      ..carbsTarget = profile['carbs_target'] as int? ?? 200
      ..fatCurrent = profile['fat_current'] as int? ?? 0
      ..fatTarget = profile['fat_target'] as int? ?? 83
      ..water = (profile['water_liters'] as num?)?.toDouble() ?? 0
      ..steps = profile['steps'] as int? ?? 0
      ..remindersEnabled = profile['reminders_enabled'] as bool? ?? true
      ..aiEnabled = profile['ai_enabled'] as bool? ?? true
      ..darkMode = profile['dark_mode'] as bool? ?? true
      ..userGoal = profile['user_goal'] as String?
      ..obstacles = List<String>.from(profile['obstacles'] as List? ?? [])
      ..desiredWeight = (profile['desired_weight'] as num?)?.toDouble() ?? 70.0
      ..hasTrainer = profile['has_trainer'] as bool?
      ..workoutFrequency = profile['workout_frequency'] as String?
      ..sex = profile['sex'] as String?
      ..birthMonth = profile['birth_month'] as int? ?? 10
      ..birthDay = profile['birth_day'] as int? ?? 16
      ..birthYear = profile['birth_year'] as int? ?? 1999
      ..source = profile['source'] as String?
      ..currentWeight = (profile['current_weight'] as num?)?.toDouble() ?? 78.0
      ..height = profile['height_cm'] as int? ?? 175;

    if (meals.isNotEmpty) {
      state.meals
        ..clear()
        ..addAll(meals.map(Meal.fromSupabaseRow));
    }

    if (weeklyCalories.isNotEmpty) {
      state.weeklyCalories
        ..clear()
        ..addAll(weeklyCalories.map(
          (row) => (row['calories'] as num?)?.toDouble() ?? 0,
        ));
    }

    if (weightEntries.isNotEmpty) {
      state.weightData
        ..clear()
        ..addAll(weightEntries.map(
          (row) => (row['weight_kg'] as num?)?.toDouble() ?? 0,
        ));
    }

    return state;
  }

  int goal = 2000;
  int eaten = 1160;
  int burned = 320;

  int proteinCurrent = 82;
  int proteinTarget = 150;
  int carbsCurrent = 145;
  int carbsTarget = 200;
  int fatCurrent = 38;
  int fatTarget = 83;

  double water = 1.2;
  int steps = 7241;

  // Settings toggles
  bool remindersEnabled = true;
  bool aiEnabled = true;
  bool darkMode = true;

  // ── Onboarding Profile Data ─────────────────────────────────────────────────
  String? userGoal; // 'Lose weight' | 'Maintain' | 'Gain weight'
  List<String> obstacles = []; // multi-select obstacles
  double desiredWeight = 70.0; // desired weight in kg
  bool? hasTrainer; // works with trainer/dietitian
  String? workoutFrequency; // '0-2' | '3-5' | '6+'

  // From existing onboarding
  String? sex;
  int birthMonth = 10;
  int birthDay = 16;
  int birthYear = 1999;
  String? source;

  // Body metrics (editable in onboarding)
  double currentWeight = 78.0;
  int height = 175;

  /// Short disclaimer — not medical advice.
  static const String disclaimer =
      'Estimates only. Consult a healthcare professional for personalised advice.';

  // ── Apply onboarding data in one call ───────────────────────────────────────
  void applyOnboardingData({
    required String? sex,
    required int birthMonth,
    required int birthDay,
    required int birthYear,
    required String? source,
    required String? userGoal,
    required List<String> obstacles,
    required double desiredWeight,
    required bool? hasTrainer,
    required String? workoutFrequency,
    required double currentWeight,
    required int height,
  }) {
    this.sex = sex;
    this.birthMonth = birthMonth;
    this.birthDay = birthDay;
    this.birthYear = birthYear;
    this.source = source;
    this.userGoal = userGoal;
    this.obstacles = List.of(obstacles);
    this.desiredWeight = desiredWeight;
    this.hasTrainer = hasTrainer;
    this.workoutFrequency = workoutFrequency;
    this.currentWeight = currentWeight;
    this.height = height;
    recalculateGoal();
  }

  // ── Calorie goal calculator based on onboarding answers ─────────────────────
  void recalculateGoal() {
    final now = DateTime.now();
    final age = now.year -
        birthYear -
        ((now.month < birthMonth ||
                (now.month == birthMonth && now.day < birthDay))
            ? 1
            : 0);

    final bool hasMetrics = currentWeight > 0 && height > 0 && age > 0;
    double base;

    if (hasMetrics && sex != null) {
      // Mifflin-St Jeor BMR
      if (sex == 'Female') {
        base = 10 * currentWeight + 6.25 * height - 5 * age - 161;
      } else {
        // Male / Other
        base = 10 * currentWeight + 6.25 * height - 5 * age + 5;
      }

      // Activity multiplier (TDEE)
      if (workoutFrequency == '6+') {
        base *= 1.55;
      } else if (workoutFrequency == '3-5') {
        base *= 1.375;
      } else {
        base *= 1.2; // sedentary / 0-2
      }
    } else {
      // Fallback when data is incomplete
      base = 2000;

      if (workoutFrequency == '3-5') {
        base += 200;
      } else if (workoutFrequency == '6+') {
        base += 400;
      }

      if (sex == 'Female') {
        base -= 200;
      }
    }

    // Adjust for goal
    if (userGoal == 'Lose weight') {
      base -= 400;
    } else if (userGoal == 'Gain weight') {
      base += 400;
    }

    // Floor: never below 1200 kcal
    goal = base.round().clamp(1200, 9999);

    // Adjust macro targets proportionally (based on 2000 kcal reference)
    final factor = goal / 2000.0;
    proteinTarget = (150 * factor).round().clamp(1, 9999);
    carbsTarget = (200 * factor).round().clamp(1, 9999);
    fatTarget = (83 * factor).round().clamp(1, 9999);

    notifyListeners();
  }

  /// Net calories = eaten − burned.
  int get netCalories => eaten - burned;

  /// Remaining calories. Negative means over-goal.
  int get kcalLeft => goal - eaten + burned;

  final List<Meal> meals = [
    const Meal(
        name: 'Oatmeal with banana',
        type: 'Breakfast',
        time: '8:15 AM',
        kcal: 380,
        emoji: '🥣',
        protein: 12,
        carbs: 68,
        fat: 6),
    const Meal(
        name: 'Black coffee',
        type: 'Breakfast',
        time: '8:30 AM',
        kcal: 5,
        emoji: '☕',
        protein: 0,
        carbs: 0,
        fat: 0),
    const Meal(
        name: 'Grilled chicken salad',
        type: 'Lunch',
        time: '1:00 PM',
        kcal: 420,
        emoji: '🥗',
        protein: 45,
        carbs: 22,
        fat: 14),
    const Meal(
        name: 'Whole grain bread',
        type: 'Lunch',
        time: '1:05 PM',
        kcal: 180,
        emoji: '🍞',
        protein: 6,
        carbs: 34,
        fat: 2),
    const Meal(
        name: 'Mixed nuts',
        type: 'Snack',
        time: '3:30 PM',
        kcal: 175,
        emoji: '🥜',
        protein: 5,
        carbs: 7,
        fat: 15),
  ];

  void addMeal(Meal meal) {
    meals.add(meal);
    eaten += meal.kcal;
    proteinCurrent += meal.protein;
    carbsCurrent += meal.carbs;
    fatCurrent += meal.fat;
    notifyListeners();
  }

  Map<String, dynamic> toProfileRow(String userId) {
    return {
      'user_id': userId,
      'goal': goal,
      'eaten': eaten,
      'burned': burned,
      'protein_current': proteinCurrent,
      'protein_target': proteinTarget,
      'carbs_current': carbsCurrent,
      'carbs_target': carbsTarget,
      'fat_current': fatCurrent,
      'fat_target': fatTarget,
      'water_liters': water,
      'steps': steps,
      'reminders_enabled': remindersEnabled,
      'ai_enabled': aiEnabled,
      'dark_mode': darkMode,
      'user_goal': userGoal,
      'obstacles': obstacles,
      'desired_weight': desiredWeight,
      'has_trainer': hasTrainer,
      'workout_frequency': workoutFrequency,
      'sex': sex,
      'birth_month': birthMonth,
      'birth_day': birthDay,
      'birth_year': birthYear,
      'source': source,
      'current_weight': currentWeight,
      'height_cm': height,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  void toggleReminders() {
    remindersEnabled = !remindersEnabled;
    notifyListeners();
  }

  void toggleAi() {
    aiEnabled = !aiEnabled;
    notifyListeners();
  }

  void toggleDarkMode() {
    darkMode = !darkMode;
    notifyListeners();
  }

  // Weekly calorie data (Mon–Sun)
  final List<double> weeklyCalories = [
    1920,
    2100,
    1750,
    1980,
    2050,
    1840,
    1160
  ];

  // Weight tracking (last 6 entries)
  final List<double> weightData = [80.2, 79.8, 79.1, 78.6, 78.2, 77.8];
}
