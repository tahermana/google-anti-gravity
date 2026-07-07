import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/app_state.dart';
import '../theme/app_theme.dart';

class StatsScreen extends StatelessWidget {
  final AppState state;
  const StatsScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final avgDailyCalories = state.weeklyCalories.isEmpty
        ? 0
        : (state.weeklyCalories.reduce((a, b) => a + b) /
                state.weeklyCalories.length)
            .round();
    final calorieDelta = state.goal - avgDailyCalories;
    final avgSub = calorieDelta >= 0
        ? '$calorieDelta under goal'
        : '${calorieDelta.abs()} over goal';
    final streakDays = state.weeklyCalories.where((v) => v > 0).length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Text('Stats', style: kStylePageTitle),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Big stat cards ──────────────────────────────────────
                    Row(
                      children: [
                        Expanded(child: _BigStatCard(
                          label: 'Avg. daily calories',
                          value: _formatNumber(avgDailyCalories),
                          sub: avgSub,
                          accent: false,
                        )),
                        const SizedBox(width: 10),
                        Expanded(child: _BigStatCard(
                          label: 'Streak',
                          value: '🔥 $streakDays',
                          sub: 'days logged',
                          accent: true,
                        )),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ── Weight chart ─────────────────────────────────────────
                    const Text('Body Weight', style: _subTitle),
                    const SizedBox(height: 10),
                    _WeightChart(data: state.weightData),
                    const SizedBox(height: 20),

                    // ── Nutrient goals ───────────────────────────────────────
                    const Text('Nutrient Goals', style: _subTitle),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: kBgCard,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: kBorder),
                      ),
                      child: Column(
                        children: [
                          _NutrientRow(label: 'Protein', current: state.proteinCurrent, target: state.proteinTarget, unit: 'g', color: kProtein),
                          _NutrientRow(label: 'Carbs',   current: state.carbsCurrent,   target: state.carbsTarget,   unit: 'g', color: kCarbs),
                          _NutrientRow(label: 'Fat',     current: state.fatCurrent,     target: state.fatTarget,     unit: 'g', color: kFat),
                          const _NutrientRow(label: 'Fiber', current: 18, target: 30, unit: 'g', color: Color(0xFF2A9D8F)),
                          const _NutrientRow(label: 'Water', current: 1,  target: 3,  unit: 'L', color: kWater, isLast: true),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatNumber(int n) {
    return n.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }
}

const _subTitle = TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kTextSec);

// ── Big Stat Card ─────────────────────────────────────────────────────────────
class _BigStatCard extends StatelessWidget {
  final String label, value, sub;
  final bool accent;
  const _BigStatCard({required this.label, required this.value, required this.sub, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: accent ? null : kBgCard,
        gradient: accent
            ? const LinearGradient(colors: [Color(0xFF1E0A0B), Color(0xFF2A0D0F)],
                begin: Alignment.topLeft, end: Alignment.bottomRight)
            : null,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent ? kAccent.withOpacity(0.25) : kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: kTextSec, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: kTextPrim, letterSpacing: -1, height: 1)),
          const SizedBox(height: 4),
          Text(sub,   style: const TextStyle(fontSize: 11, color: kTextSec)),
        ],
      ),
    );
  }
}

// ── Weight Line Chart ─────────────────────────────────────────────────────────
class _WeightChart extends StatelessWidget {
  final List<double> data;
  const _WeightChart({required this.data});

  @override
  Widget build(BuildContext context) {
    // Guard: need at least 2 points to draw a chart.
    if (data.length < 2) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: kBgCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: kBorder),
        ),
        child: const Center(
          child: Text('Not enough data yet',
              style: TextStyle(color: kTextSec, fontSize: 13)),
        ),
      );
    }
    final spots = List.generate(data.length, (i) => FlSpot(i.toDouble(), data[i]));
    final labels = ['May 1', 'May 8', 'May 15', 'May 22', 'May 29', 'Today'];

    return Container(
      height: 180,
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kBorder),
      ),
      child: LineChart(
        LineChartData(
          minY: data.reduce((a, b) => a < b ? a : b) - 1,
          maxY: data.reduce((a, b) => a > b ? a : b) + 1,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => const FlLine(color: kBorder, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (v, _) {
                  final idx = v.toInt();
                  if (idx < 0 || idx >= labels.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(labels[idx],
                      style: const TextStyle(fontSize: 9, color: kTextSec, fontWeight: FontWeight.w600)),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => kBgCard2,
              getTooltipItems: (spots) => spots.map((s) => LineTooltipItem(
                '${s.y} kg',
                const TextStyle(color: kTextPrim, fontWeight: FontWeight.w600, fontSize: 12),
              )).toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: kAccent,
              barWidth: 2.5,
              dotData: FlDotData(
                getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                  radius: 4, color: kAccent, strokeWidth: 0,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [kAccent.withOpacity(0.25), kAccent.withOpacity(0)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Nutrient Row ──────────────────────────────────────────────────────────────
class _NutrientRow extends StatelessWidget {
  final String label, unit;
  final num current, target;
  final Color color;
  final bool isLast;

  const _NutrientRow({
    required this.label,
    required this.current,
    required this.target,
    required this.unit,
    required this.color,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    // Guard: avoid division by zero when target is 0.
    final pct = target == 0 ? 0.0 : (current / target).clamp(0.0, 1.0).toDouble();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              SizedBox(
                width: 60,
                child: Text(label, style: const TextStyle(fontSize: 13, color: kTextSec)),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: pct),
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeOut,
                    builder: (_, val, __) => LinearProgressIndicator(
                      value: val,
                      minHeight: 5,
                      backgroundColor: const Color(0xFF2A2A35),
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 60,
                child: Text(
                  '$current/$target$unit',
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 11, color: kTextSec),
                ),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(color: kBorder, height: 1),
      ],
    );
  }
}
