import 'package:flutter/material.dart';
import '../models/app_state.dart';
import '../theme/app_theme.dart';

/// Grouped meal list (Breakfast / Lunch / Dinner / Snack).
class MealList extends StatelessWidget {
  final List<Meal> meals;
  const MealList({super.key, required this.meals});

  static const _order = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];
  static const _emoji = {
    'Breakfast': '🌅',
    'Lunch':     '☀️',
    'Dinner':    '🌙',
    'Snack':     '🍎',
  };
  static const _bg = {
    'Breakfast': Color(0xFF1A3A6B),
    'Lunch':     Color(0xFF1A3A1A),
    'Dinner':    Color(0xFF2A1A3A),
    'Snack':     Color(0xFF3A2A1A),
  };

  @override
  Widget build(BuildContext context) {
    // Group meals by type
    final Map<String, List<Meal>> grouped = {};
    for (final m in meals) {
      grouped.putIfAbsent(m.type, () => []).add(m);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final type in _order)
          if (grouped.containsKey(type)) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '${_emoji[type]} $type',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: kTextMuted,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            ...grouped[type]!.map((m) => _MealItem(meal: m, bg: _bg[type]!)),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}

class _MealItem extends StatelessWidget {
  final Meal meal;
  final Color bg;
  const _MealItem({required this.meal, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Emoji icon
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(meal.emoji, style: const TextStyle(fontSize: 20)),
                  ),
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meal.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: kTextPrim,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${meal.type} · ${meal.time}',
                        style: const TextStyle(fontSize: 11, color: kTextSec),
                      ),
                    ],
                  ),
                ),
                // Kcal
                Text(
                  '${meal.kcal} kcal',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: kAccent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
