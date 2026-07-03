import 'package:flutter/material.dart';
import '../models/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/add_meal_sheet.dart';

class ScanScreen extends StatefulWidget {
  final AppState state;
  const ScanScreen({super.key, required this.state});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _scanCtrl;
  late Animation<double> _scanLine;
  bool _scanning  = false;
  bool _showResult = false;

  @override
  void initState() {
    super.initState();
    _scanCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _scanLine = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _scanCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scanCtrl.dispose();
    super.dispose();
  }

  void _fakeScan() async {
    if (_scanning) return;
    setState(() { _scanning = true; _showResult = false; });
    await Future.delayed(const Duration(milliseconds: 1800));
    if (mounted) setState(() { _scanning = false; _showResult = true; });
  }

  void _addScanned() {
    widget.state.addMeal(const Meal(
      name: 'Grilled Chicken Breast',
      type: 'Dinner',
      time: '7:00 PM',
      kcal: 165,
      emoji: '🍗',
      protein: 31,
      carbs: 0,
      fat: 4,
    ));
    setState(() => _showResult = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✓ Grilled Chicken Breast added'),
        backgroundColor: kBgCard2,
        behavior: SnackBarBehavior.floating,
        shape: StadiumBorder(),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Scan Food', style: kStylePageTitle),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // ── Viewfinder ───────────────────────────────────────────
                    Center(
                      child: SizedBox(
                        width: 240, height: 240,
                        child: Stack(
                          children: [
                            // Background
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black38,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white10),
                              ),
                            ),
                            // Corners
                            ..._buildCorners(),
                            // Sweeping scan line
                            AnimatedBuilder(
                              animation: _scanLine,
                              builder: (_, __) => Positioned(
                                left: 14, right: 14,
                                top: 14 + (_scanLine.value * (240 - 28)),
                                child: Container(
                                  height: 2,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(colors: [
                                      Colors.transparent, kAccent, Colors.transparent,
                                    ]),
                                    boxShadow: [BoxShadow(color: kAccent.withOpacity(0.5), blurRadius: 6)],
                                  ),
                                ),
                              ),
                            ),
                            // Hint text
                            const Positioned(
                              bottom: 14, left: 0, right: 0,
                              child: Text(
                                'Point camera at food or barcode',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12, color: kTextSec),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Buttons ──────────────────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => showAddMealSheet(context, widget.state),
                            icon: const Icon(Icons.search, size: 16),
                            label: const Text('Search manually'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: kTextPrim,
                              side: const BorderSide(color: kBorder),
                              backgroundColor: kBgCard,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _scanning ? null : _fakeScan,
                            icon: _scanning
                                ? const SizedBox(width: 16, height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.camera_alt, size: 16),
                            label: Text(_scanning ? 'Scanning…' : 'Scan now'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── Scan result ──────────────────────────────────────────
                    if (_showResult)
                      AnimatedOpacity(
                        opacity: _showResult ? 1 : 0,
                        duration: const Duration(milliseconds: 400),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: kBgCard,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: kBorder),
                          ),
                          child: Column(
                            children: [
                              const Row(
                                children: [
                                  Text('🍗', style: TextStyle(fontSize: 32)),
                                  SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Grilled Chicken Breast',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kTextPrim)),
                                      SizedBox(height: 2),
                                      Text('100g serving',
                                        style: TextStyle(fontSize: 12, color: kTextSec)),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Row(
                                children: [
                                  Expanded(child: _MacroBox(value: '165', label: 'kcal')),
                                  SizedBox(width: 8),
                                  Expanded(child: _MacroBox(value: '31g', label: 'protein')),
                                  SizedBox(width: 8),
                                  Expanded(child: _MacroBox(value: '0g',  label: 'carbs')),
                                  SizedBox(width: 8),
                                  Expanded(child: _MacroBox(value: '3.6g', label: 'fat')),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: _addScanned,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: kAccent,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                    elevation: 0,
                                  ),
                                  child: const Text('Add to Log',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                                ),
                              ),
                            ],
                          ),
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

  List<Widget> _buildCorners() {
    const size = 28.0;
    const thickness = 3.0;
    const pad = 14.0;
    const r = 4.0;

    Widget corner({required Alignment align, required BorderRadius br}) =>
        Positioned(
          left:   align == Alignment.topLeft || align == Alignment.bottomLeft ? pad : null,
          right:  align == Alignment.topRight || align == Alignment.bottomRight ? pad : null,
          top:    align == Alignment.topLeft || align == Alignment.topRight ? pad : null,
          bottom: align == Alignment.bottomLeft || align == Alignment.bottomRight ? pad : null,
          child: Container(
            width: size, height: size,
            decoration: BoxDecoration(
              border: Border(
                top:    align == Alignment.topLeft || align == Alignment.topRight
                    ? const BorderSide(color: kAccent, width: thickness) : BorderSide.none,
                bottom: align == Alignment.bottomLeft || align == Alignment.bottomRight
                    ? const BorderSide(color: kAccent, width: thickness) : BorderSide.none,
                left:   align == Alignment.topLeft || align == Alignment.bottomLeft
                    ? const BorderSide(color: kAccent, width: thickness) : BorderSide.none,
                right:  align == Alignment.topRight || align == Alignment.bottomRight
                    ? const BorderSide(color: kAccent, width: thickness) : BorderSide.none,
              ),
              borderRadius: br,
            ),
          ),
        );

    return [
      corner(align: Alignment.topLeft,     br: const BorderRadius.only(topLeft: Radius.circular(r))),
      corner(align: Alignment.topRight,    br: const BorderRadius.only(topRight: Radius.circular(r))),
      corner(align: Alignment.bottomLeft,  br: const BorderRadius.only(bottomLeft: Radius.circular(r))),
      corner(align: Alignment.bottomRight, br: const BorderRadius.only(bottomRight: Radius.circular(r))),
    ];
  }
}

class _MacroBox extends StatelessWidget {
  final String value, label;
  const _MacroBox({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: kBgCard2,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kTextPrim)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10, color: kTextSec)),
        ],
      ),
    );
  }
}
