import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../ar_measurement/domain/usecases/calculate_weight.dart';

class ImageMeasurePage extends StatefulWidget {
  final File imageFile;
  final String? species;

  const ImageMeasurePage({
    super.key,
    required this.imageFile,
    this.species,
  });

  @override
  State<ImageMeasurePage> createState() => _ImageMeasurePageState();
}

class _ImageMeasurePageState extends State<ImageMeasurePage> {
  // Line 1: Reference Object
  Offset? _refStart;
  Offset? _refEnd;
  double _refRealLengthCm = 8.56; // Default to Credit Card width

  // Line 2: Fish
  Offset? _fishStart;
  Offset? _fishEnd;

  // Active dragging point
  String? _activePoint; // 'refStart', 'refEnd', 'fishStart', 'fishEnd'

  double? _calculatedLengthCm;
  double? _calculatedWeightGrams;

  @override
  void initState() {
    super.initState();
    // Initialize points to center-ish
    // We'll set them in build after getting layout info if needed,
    // or just default to some relative coordinates.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Measure on Image'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelp,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Initialize points if null
                if (_refStart == null) {
                  final cx = constraints.maxWidth / 2;
                  final cy = constraints.maxHeight / 2;
                  _refStart = Offset(cx - 50, cy - 100);
                  _refEnd = Offset(cx + 50, cy - 100);
                  _fishStart = Offset(cx - 100, cy + 50);
                  _fishEnd = Offset(cx + 100, cy + 50);
                }

                return GestureDetector(
                  onPanStart: (details) =>
                      _handlePanStart(details.localPosition),
                  onPanUpdate: (details) =>
                      _handlePanUpdate(details.localPosition),
                  onPanEnd: (_) => setState(() => _activePoint = null),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(
                        widget.imageFile,
                        fit: BoxFit.contain,
                      ),
                      CustomPaint(
                        painter: _MeasurementPainter(
                          refStart: _refStart!,
                          refEnd: _refEnd!,
                          fishStart: _fishStart!,
                          fishEnd: _fishEnd!,
                        ),
                      ),
                      // Instructions overlay
                      Positioned(
                        top: 10,
                        left: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '1. Align Blue Line to Reference Object (e.g. Card)\n2. Align Red Line to Fish (Head to Tail)',
                            style: GoogleFonts.poppins(
                                color: Colors.white, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF006D77).withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1FAEE),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.straighten_rounded, color: const Color(0xFF006D77)),
                      const SizedBox(width: 12),
                      Text(
                        'Ref. Object Size:',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF006D77),
                        ),
                      ),
                      const Spacer(),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<double>(
                          value: _refRealLengthCm,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF006D77),
                            fontWeight: FontWeight.bold,
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: 8.56, child: Text('Credit Card (8.56cm)')),
                            DropdownMenuItem(
                                value: 2.50, child: Text('Coin (2.5cm)')),
                            DropdownMenuItem(
                                value: 15.0, child: Text('Ruler (15cm)')),
                            DropdownMenuItem(
                                value: 30.0, child: Text('Ruler (30cm)')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _refRealLengthCm = val;
                                _calculate();
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _calculate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF006D77),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Calculate Results',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                if (_calculatedLengthCm != null) ...[
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _ResultItem(
                        label: 'Estimated Length',
                        value: '${_calculatedLengthCm!.toStringAsFixed(1)} cm',
                      ),
                      _ResultItem(
                        label: 'Estimated Weight',
                        value: '${_calculatedWeightGrams!.toStringAsFixed(0)} g',
                        isHighlight: true,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handlePanStart(Offset pos) {
    // Find closest point
    final points = {
      'refStart': _refStart!,
      'refEnd': _refEnd!,
      'fishStart': _fishStart!,
      'fishEnd': _fishEnd!,
    };

    String? closest;
    double minDist = 40.0; // Touch radius

    points.forEach((key, point) {
      final dist = (point - pos).distance;
      if (dist < minDist) {
        minDist = dist;
        closest = key;
      }
    });

    setState(() {
      _activePoint = closest;
    });
  }

  void _handlePanUpdate(Offset pos) {
    if (_activePoint == null) return;

    setState(() {
      switch (_activePoint) {
        case 'refStart':
          _refStart = pos;
          break;
        case 'refEnd':
          _refEnd = pos;
          break;
        case 'fishStart':
          _fishStart = pos;
          break;
        case 'fishEnd':
          _fishEnd = pos;
          break;
      }
      _calculate(); // Live update
    });
  }

  void _calculate() {
    if (_refStart == null ||
        _refEnd == null ||
        _fishStart == null ||
        _fishEnd == null) return;

    final refPixelLen = (_refStart! - _refEnd!).distance;
    final fishPixelLen = (_fishStart! - _fishEnd!).distance;

    if (refPixelLen == 0) return;

    final pixelsPerCm = refPixelLen / _refRealLengthCm;
    final fishLenCm = fishPixelLen / pixelsPerCm;

    final weight = CalculateWeight()(
      lengthCm: fishLenCm,
      species: widget.species,
    );

    setState(() {
      _calculatedLengthCm = fishLenCm;
      _calculatedWeightGrams = weight;
    });
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How to Measure'),
        content: const Text(
          '1. Ensure your photo has a reference object (like a credit card or coin) next to the fish.\n'
          '2. Drag the BLUE line endpoints to match the reference object.\n'
          '3. Drag the RED line endpoints to match the fish (Head to Tail).\n'
          '4. Select the correct reference size from the dropdown.\n'
          '5. The app will calculate the length and weight.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

class _MeasurementPainter extends CustomPainter {
  final Offset refStart;
  final Offset refEnd;
  final Offset fishStart;
  final Offset fishEnd;

  _MeasurementPainter({
    required this.refStart,
    required this.refEnd,
    required this.fishStart,
    required this.fishEnd,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    // Draw Reference Line (Blue)
    paint.color = Colors.blue;
    canvas.drawLine(refStart, refEnd, paint);
    _drawHandle(canvas, refStart, Colors.blue);
    _drawHandle(canvas, refEnd, Colors.blue);

    // Draw Fish Line (Red)
    paint.color = Colors.red;
    canvas.drawLine(fishStart, fishEnd, paint);
    _drawHandle(canvas, fishStart, Colors.red);
    _drawHandle(canvas, fishEnd, Colors.red);
  }

  void _drawHandle(Canvas canvas, Offset center, Color color) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 8, paint);

    paint.color = color;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;
    canvas.drawCircle(center, 8, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _ResultItem extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlight;

  const _ResultItem({
    required this.label,
    required this.value,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isHighlight ? Colors.teal : Colors.black,
          ),
        ),
      ],
    );
  }
}
