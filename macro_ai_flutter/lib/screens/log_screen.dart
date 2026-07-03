import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/app_state.dart';
import '../theme/app_theme.dart';

class LogScreen extends StatefulWidget {
  final AppState state;
  const LogScreen({super.key, required this.state});

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  int _selectedDay = 6; // Today (index 6 in the 7-day list)

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Page header ──────────────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Text('Meal Log', style: kStylePageTitle),
            ),

            // ── 7-Day calendar strip ─────────────────────────────────────────
            SizedBox(
              height: 80,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: 7,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final d = today.subtract(Duration(days: 6 - i));
                  final isToday   = i == 6;
                  final isSelected = i == _selectedDay;
                  final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

                  return GestureDetector(
                    onTap: () => setState(() => _selectedDay = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 50,
                      decoration: BoxDecoration(
                        color: isSelected ? kAccent : kBgCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? kAccent : kBorder,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            days[d.weekday % 7],
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white70 : kTextSec,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${d.day}',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: isSelected ? Colors.white : kTextPrim,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 4, height: 4,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white54
                                  : (isToday || i > 2) ? kGreen : kTextMuted,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // ── Body ─────────────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary card
                    _SummaryCard(state: widget.state),
                    const SizedBox(height: 20),

                    // Weekly chart
                    const Text('Weekly Trend', style: _subTitle),
                    const SizedBox(height: 10),
                    _WeeklyBarChart(data: widget.state.weeklyCalories, selectedIndex: _selectedDay),
                    const SizedBox(height: 20),

                    // Macro pie
                    const Text('Macro Breakdown', style: _subTitle),
                    const SizedBox(height: 10),
                    _MacroPie(state: widget.state),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _subTitle = TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kTextSec);

// ── Summary Card ──────────────────────────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  final AppState state;
  const _SummaryCard({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        children: [
          _Row('Calories consumed', '${state.eaten} kcal', kTextPrim),
          const Divider(color: kBorder, height: 1),
          _Row('Calories burned',   '${state.burned} kcal', kAccent),
          const Divider(color: kBorder, height: 1),
          _Row('Net calories',      '${state.kcalLeft} kcal', kTextPrim),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label, value;
  final Color valColor;
  const _Row(this.label, this.value, this.valColor);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: kTextSec)),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: valColor)),
        ],
      ),
    );
  }
}

// ── Weekly Bar Chart ──────────────────────────────────────────────────────────
class _WeeklyBarChart extends StatelessWidget {
  final List<double> data;
  final int selectedIndex;
  const _WeeklyBarChart({required this.data, required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      height: 180,
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kBorder),
      ),
      child: BarChart(
        BarChartData(
          maxY: 2400,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => kBgCard2,
              getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                '${rod.toY.toInt()} kcal',
                const TextStyle(color: kTextPrim, fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) => Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(labels[v.toInt()],
                    style: const TextStyle(fontSize: 10, color: kTextSec, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => const FlLine(color: kBorder, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(data.length, (i) {
            final isSelected = i == selectedIndex;
            return BarChartGroupData(x: i, barRods: [
              BarChartRodData(
                toY: data[i],
                width: 18,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                color: isSelected ? kAccent : kAccent.withOpacity(0.30),
              ),
            ]);
          }),
        ),
      ),
    );
  }
}

// ── Macro Pie ─────────────────────────────────────────────────────────────────
class _MacroPie extends StatelessWidget {
  final AppState state;
  const _MacroPie({required this.state});

  @override
  Widget build(BuildContext context) {
    final total = (state.proteinCurrent + state.carbsCurrent + state.fatCurrent).toDouble();
    if (total == 0) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 120, height: 120,
            child: PieChart(PieChartData(
              sectionsSpace: 3,
              centerSpaceRadius: 34,
              sections: [
                PieChartSectionData(value: state.proteinCurrent / total * 100,
                    color: kProtein, title: '', radius: 24),
                PieChartSectionData(value: state.carbsCurrent / total * 100,
                    color: kCarbs,   title: '', radius: 24),
                PieChartSectionData(value: state.fatCurrent / total * 100,
                    color: kFat,     title: '', radius: 24),
              ],
            )),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PieLegend(color: kProtein, label: 'Protein', value: '${(state.proteinCurrent / total * 100).round()}%'),
                const SizedBox(height: 10),
                _PieLegend(color: kCarbs,   label: 'Carbs',   value: '${(state.carbsCurrent / total * 100).round()}%'),
                const SizedBox(height: 10),
                _PieLegend(color: kFat,     label: 'Fat',     value: '${(state.fatCurrent / total * 100).round()}%'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PieLegend extends StatelessWidget {
  final Color color;
  final String label, value;
  const _PieLegend({required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 10, height: 10,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 13, color: kTextSec)),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kTextPrim)),
      ],
    );
  }
}
