import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/model_config.dart';

/// Card widget to display individual detection
import '../../domain/entities/detection.dart';

/// Card widget to display individual detection
class DetectionCard extends StatelessWidget {
  final Detection detection;
  final VoidCallback? onTap;

  const DetectionCard({super.key, required this.detection, this.onTap});

  @override
  Widget build(BuildContext context) {
    final className = detection.className;
    final confidenceValue = detection.confidence;
    final color = ModelConfig.classColors[className] ?? Colors.blue;
    final confidence = (confidenceValue * 100).toStringAsFixed(1);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF006D77).withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Icon Container
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF83C5BE).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    ModelConfig.classIcons[className] ?? '🐟',
                    style: const TextStyle(fontSize: 32),
                  ),
                ),

                const SizedBox(width: 20),

                // Detection details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            className.toUpperCase(),
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF006D77),
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            '$confidence%',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF006D77),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Confidence progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: confidenceValue,
                          backgroundColor: const Color(0xFFF1FAEE),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF83C5BE),
                          ),
                          minHeight: 10,
                        ),
                      ),
                    ],
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
