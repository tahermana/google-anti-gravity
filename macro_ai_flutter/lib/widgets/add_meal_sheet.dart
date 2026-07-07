import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/app_state.dart';
import '../theme/app_theme.dart';

/// Bottom sheet for logging a new meal.
void showAddMealSheet(BuildContext context, AppState state) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: kBgCard2,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _AddMealSheet(state: state),
  );
}

class _AddMealSheet extends StatefulWidget {
  final AppState state;
  const _AddMealSheet({required this.state});

  @override
  State<_AddMealSheet> createState() => _AddMealSheetState();
}

class _AddMealSheetState extends State<_AddMealSheet> {
  final _nameCtrl    = TextEditingController();
  final _kcalCtrl    = TextEditingController();
  final _proteinCtrl = TextEditingController();
  final _carbsCtrl   = TextEditingController();
  final _fatCtrl     = TextEditingController();
  String _type = 'Breakfast';

  static const _typeEmoji = {
    'Breakfast': '🍳', 'Lunch': '🥙', 'Dinner': '🍽️', 'Snack': '🍎',
  };

  @override
  void dispose() {
    for (final c in [_nameCtrl, _kcalCtrl, _proteinCtrl, _carbsCtrl, _fatCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    final kcal = int.tryParse(_kcalCtrl.text) ?? 0;
    if (kcal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter calories greater than 0'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final now = TimeOfDay.now();
    final hour = now.hourOfPeriod == 0 ? 12 : now.hourOfPeriod;
    final min  = now.minute.toString().padLeft(2, '0');
    final amPm = now.period == DayPeriod.am ? 'AM' : 'PM';

    widget.state.addMeal(Meal(
      name:    name,
      type:    _type,
      time:    '$hour:$min $amPm',
      kcal:    kcal.clamp(1, 9999),
      emoji:   _typeEmoji[_type] ?? '🍴',
      protein: (int.tryParse(_proteinCtrl.text) ?? 0).clamp(0, 1000),
      carbs:   (int.tryParse(_carbsCtrl.text)   ?? 0).clamp(0, 1000),
      fat:     (int.tryParse(_fatCtrl.text)     ?? 0).clamp(0, 1000),
    ));

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✓ $name added'),
        backgroundColor: kBgCard2,
        behavior: SnackBarBehavior.floating,
        shape: const StadiumBorder(),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Log a Meal',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kTextPrim)),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 32, height: 32,
                  decoration: const BoxDecoration(color: kBgCard3, shape: BoxShape.circle),
                  child: const Icon(Icons.close, size: 16, color: kTextSec),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Name
          _Input(controller: _nameCtrl, hint: 'Food name (e.g. Grilled chicken)'),
          const SizedBox(height: 10),

          // Kcal + Type row
          Row(
            children: [
              Expanded(child: _Input(controller: _kcalCtrl, hint: 'Calories', numeric: true)),
              const SizedBox(width: 10),
              Expanded(child: _TypeDropdown(value: _type, onChanged: (v) => setState(() => _type = v!))),
            ],
          ),
          const SizedBox(height: 10),

          // Macros row
          Row(
            children: [
              Expanded(child: _Input(controller: _proteinCtrl, hint: 'Protein g', numeric: true)),
              const SizedBox(width: 8),
              Expanded(child: _Input(controller: _carbsCtrl, hint: 'Carbs g', numeric: true)),
              const SizedBox(width: 8),
              Expanded(child: _Input(controller: _fatCtrl, hint: 'Fat g', numeric: true)),
            ],
          ),
          const SizedBox(height: 16),

          // Submit
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: kAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('Add Meal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Input extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool numeric;
  const _Input({required this.controller, required this.hint, this.numeric = false});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: numeric ? TextInputType.number : TextInputType.text,
      inputFormatters: numeric ? [FilteringTextInputFormatter.digitsOnly] : null,
      style: const TextStyle(color: kTextPrim, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: kTextMuted, fontSize: 13),
        filled: true,
        fillColor: kBgCard3,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: kBorder),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: kAccent),
        ),
      ),
    );
  }
}

class _TypeDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String?> onChanged;
  const _TypeDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: kBgCard3,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kBorder),
      ),
      child: DropdownButton<String>(
        value: value,
        onChanged: onChanged,
        isExpanded: true,
        underline: const SizedBox(),
        dropdownColor: kBgCard2,
        style: const TextStyle(color: kTextPrim, fontSize: 14),
        items: const ['Breakfast', 'Lunch', 'Dinner', 'Snack']
            .map((t) => DropdownMenuItem(value: t, child: Text(t)))
            .toList(),
      ),
    );
  }
}
