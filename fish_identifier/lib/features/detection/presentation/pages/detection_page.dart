import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bloc/detection_bloc.dart';
import '../bloc/detection_event.dart';
import '../bloc/detection_state.dart';
import '../widgets/detection_painter.dart';
import '../widgets/detection_card.dart';
import '../../../image_measurement/presentation/pages/image_measure_page.dart';

/// Page displaying detection results
class DetectionPage extends StatefulWidget {
  const DetectionPage({super.key});

  @override
  State<DetectionPage> createState() => _DetectionPageState();
}

class _DetectionPageState extends State<DetectionPage> {
  ui.Image? _image;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final state = context.read<DetectionBloc>().state;
    if (state is DetectionSuccess) {
      final bytes = await state.imageFile.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      setState(() {
        _image = frame.image;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1FAEE),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Detection Results',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF006D77),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF006D77)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF006D77)),
            onPressed: () {
              context.read<DetectionBloc>().add(const ResetDetection());
              Navigator.pop(context);
            },
            tooltip: 'New Detection',
          ),
        ],
      ),
      body: BlocBuilder<DetectionBloc, DetectionState>(
        builder: (context, state) {
          if (state is! DetectionSuccess) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image with bounding boxes
                Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF006D77).withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      color: Colors.white,
                      child: _image != null
                          ? LayoutBuilder(
                              builder: (context, constraints) {
                                return Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.file(
                                      state.imageFile,
                                      fit: BoxFit.contain,
                                    ),
                                    CustomPaint(
                                      painter: DetectionPainter(
                                        detections: state.detections,
                                        image: _image,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            )
                          : Image.file(
                              state.imageFile,
                              fit: BoxFit.contain,
                            ),
                    ),
                  ),
                ),

                // Stats row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.radar_rounded,
                          label: 'Species',
                          value: '${state.detections.length}',
                          color: const Color(0xFF006D77),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.timer_outlined,
                          label: 'Inference',
                          value: '${state.inferenceTime}ms',
                          color: const Color(0xFF83C5BE),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.straighten_rounded,
                          label: 'Resolution',
                          value: '${_image?.width ?? 0}x${_image?.height ?? 0}',
                          color: const Color(0xFFE29578),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                if (state.freshnessResult != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: state.freshnessResult!.isFresh
                              ? const Color(0xFF83C5BE)
                              : Colors.red.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: state.freshnessResult!.isFresh
                                  ? const Color(0xFF83C5BE).withOpacity(0.2)
                                  : Colors.red.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              state.freshnessResult!.isFresh
                                  ? Icons.eco_rounded
                                  : Icons.warning_amber_rounded,
                              color: state.freshnessResult!.isFresh
                                  ? const Color(0xFF006D77)
                                  : Colors.red,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  state.freshnessResult!.isFresh
                                      ? 'Sustainable & Fresh'
                                      : 'Quality Warning',
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF006D77),
                                  ),
                                ),
                                Text(
                                  'Confidence Score: ${(state.freshnessResult!.confidence * 100).toStringAsFixed(1)}%',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Section header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Text(
                        'Detected Species',
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF006D77),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF006D77).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${state.detections.length}',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF006D77),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Detection cards
                if (state.detections.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          Icon(
                            Icons.eco_outlined,
                            size: 64,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No species identified',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: state.detections.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return DetectionCard(detection: state.detections[index]);
                    },
                  ),

                const SizedBox(height: 120),
              ],
            ),
          );
        },
      ),
      floatingActionButton: BlocBuilder<DetectionBloc, DetectionState>(
        builder: (context, state) {
          if (state is! DetectionSuccess) return const SizedBox();

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FloatingActionButton.extended(
                  heroTag: 'freshness',
                  onPressed: () {
                    context.read<DetectionBloc>().add(CheckFreshness(state.imageFile));
                  },
                  backgroundColor: const Color(0xFF006D77),
                  icon: const Icon(Icons.eco_rounded),
                  label: Text(
                    'Check Freshness',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 12),
                FloatingActionButton.extended(
                  heroTag: 'measure',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ImageMeasurePage(
                          imageFile: state.imageFile,
                          species: state.detections.isNotEmpty
                              ? state.detections.first.className
                              : null,
                        ),
                      ),
                    );
                  },
                  backgroundColor: const Color(0xFFE29578),
                  icon: const Icon(Icons.straighten_rounded),
                  label: Text(
                    'Measure & Weigh',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 12),
                FloatingActionButton.extended(
                  heroTag: 'new_detection',
                  onPressed: () {
                    context.read<DetectionBloc>().add(const ResetDetection());
                    Navigator.pop(context);
                  },
                  backgroundColor: const Color(0xFF83C5BE),
                  foregroundColor: const Color(0xFF006D77),
                  icon: const Icon(Icons.add_a_photo_rounded),
                  label: Text(
                    'New Detection',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF006D77),
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
