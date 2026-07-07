import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:macro_ai/main.dart';
import 'package:macro_ai/models/app_state.dart';

void main() {
  // ── AppState unit tests ────────────────────────────────────────────────────

  group('AppState.recalculateGoal', () {
    test('produces >= 1200 kcal goal (floor clamp)', () {
      final s = AppState()
        ..userGoal = 'Lose weight'
        ..workoutFrequency = '0-2'
        ..sex = 'Female';
      s.recalculateGoal();
      expect(s.goal, greaterThanOrEqualTo(1200));
    });

    test('gain-weight goal is higher than lose-weight goal', () {
      final sLose = AppState()
        ..userGoal = 'Lose weight'
        ..sex = 'Male'
        ..currentWeight = 80
        ..height = 175
        ..birthYear = 1990
        ..birthMonth = 1
        ..birthDay = 1;
      sLose.recalculateGoal();

      final sGain = AppState()
        ..userGoal = 'Gain weight'
        ..sex = 'Male'
        ..currentWeight = 80
        ..height = 175
        ..birthYear = 1990
        ..birthMonth = 1
        ..birthDay = 1;
      sGain.recalculateGoal();

      expect(sGain.goal, greaterThan(sLose.goal));
    });

    test('macro targets are non-zero after recalculate', () {
      final s = AppState();
      s.recalculateGoal();
      expect(s.proteinTarget, greaterThan(0));
      expect(s.carbsTarget, greaterThan(0));
      expect(s.fatTarget, greaterThan(0));
    });
  });

  group('AppState.applyOnboardingData', () {
    test('applies data and calls recalculateGoal', () {
      final s = AppState();
      s.applyOnboardingData(
        sex: 'Male',
        birthMonth: 6,
        birthDay: 15,
        birthYear: 1992,
        source: 'Google',
        userGoal: 'Maintain',
        obstacles: ['Stress', 'Time'],
        desiredWeight: 78.0,
        hasTrainer: false,
        workoutFrequency: '3-5',
        currentWeight: 80.0,
        height: 180,
      );
      expect(s.sex, 'Male');
      expect(s.userGoal, 'Maintain');
      expect(s.currentWeight, 80.0);
      expect(s.height, 180);
      expect(s.obstacles, containsAll(['Stress', 'Time']));
      // recalculate should have run
      expect(s.goal, greaterThan(0));
    });
  });

  group('AppState calorie getters', () {
    test('netCalories = eaten - burned', () {
      final s = AppState()
        ..eaten = 1500
        ..burned = 300;
      expect(s.netCalories, equals(1200));
    });

    test('kcalLeft = goal - eaten + burned', () {
      final s = AppState()
        ..goal = 2000
        ..eaten = 1500
        ..burned = 300;
      expect(s.kcalLeft, equals(800));
    });

    test('kcalLeft is negative when over goal', () {
      final s = AppState()
        ..goal = 2000
        ..eaten = 2500
        ..burned = 0;
      expect(s.kcalLeft, equals(-500));
    });
  });

  group('AppState.addMeal', () {
    test('addMeal updates eaten and macro totals', () {
      final s = AppState();
      final initialEaten = s.eaten;
      s.addMeal(const Meal(
        name: 'Test Chicken',
        type: 'Lunch',
        time: '12:00 PM',
        kcal: 400,
        emoji: '🍗',
        protein: 40,
        carbs: 10,
        fat: 15,
      ));
      expect(s.eaten, equals(initialEaten + 400));
      expect(s.proteinCurrent, equals(82 + 40)); // default is 82
      expect(s.carbsCurrent, equals(145 + 10));
      expect(s.fatCurrent, equals(38 + 15));
    });
  });

  // ── Widget smoke tests ─────────────────────────────────────────────────────

  group('MacroAiApp widget', () {
    testWidgets('renders without crashing when showOnboarding=true',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MacroAiApp());
      // Only pump one frame — do NOT pumpAndSettle because SplashScreen has a
      // 2.8 s Future.delayed that would leave a pending timer and fail the test.
      await tester.pump(Duration.zero);
      expect(find.byType(Scaffold), findsWidgets);
      // Advance past the splash timer so no pending timers remain at teardown.
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('renders main shell without crashing when showOnboarding=false',
        (WidgetTester tester) async {
      final state = AppState();
      await tester.pumpWidget(
        MacroAiApp(showOnboarding: false, initialState: state),
      );
      await tester.pump(); // allow first frame
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('initialState with zero goal does not crash CalorieRing',
        (WidgetTester tester) async {
      final state = AppState()
        ..goal = 0
        ..eaten = 0
        ..burned = 0;
      await tester.pumpWidget(
        MacroAiApp(showOnboarding: false, initialState: state),
      );
      await tester.pump();
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('initialState with zero macro targets does not crash MacroCard',
        (WidgetTester tester) async {
      final state = AppState()
        ..proteinTarget = 0
        ..carbsTarget = 0
        ..fatTarget = 0;
      await tester.pumpWidget(
        MacroAiApp(showOnboarding: false, initialState: state),
      );
      await tester.pump();
      expect(find.byType(Scaffold), findsWidgets);
    });
  });
}
