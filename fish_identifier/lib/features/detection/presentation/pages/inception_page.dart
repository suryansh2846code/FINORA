import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/datasources/inception_service.dart';
import '../widgets/detection_painter.dart';
import '../widgets/detection_card.dart';
import '../../domain/entities/detection.dart';

class InceptionPage extends StatefulWidget {
  const InceptionPage({super.key});

  @override
  State<InceptionPage> createState() => _InceptionPageState();
}

class _InceptionPageState extends State<InceptionPage> {
  final InceptionService _inceptionService = InceptionService();
  final ImagePicker _picker = ImagePicker();

  File? _imageFile;
  ui.Image? _uiImage;
  List<Detection> _detections = [];
  int _inferenceTime = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initModel();
  }

  Future<void> _initModel() async {
    setState(() => _isLoading = true);
    await _inceptionService.initialize();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _detections = [];
        _uiImage = null;
      });
      _loadImageForDisplay();
      _runInference();
    }
  }

  Future<void> _loadImageForDisplay() async {
    if (_imageFile == null) return;
    final bytes = await _imageFile!.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    setState(() {
      _uiImage = frame.image;
    });
  }

  Future<void> _runInference() async {
    if (_imageFile == null) return;

    setState(() => _isLoading = true);
    final stopwatch = Stopwatch()..start();

    try {
      final detections = await _inceptionService.runInference(_imageFile!);
      stopwatch.stop();

      setState(() {
        _detections = detections;
        _inferenceTime = stopwatch.elapsedMilliseconds;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error running inference: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _inceptionService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Inception V2 Detection',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Area
            Container(
              width: double.infinity,
              height: 400,
              color: Colors.black,
              child: _isLoading && _imageFile == null
                  ? const Center(child: CircularProgressIndicator())
                  : _imageFile != null
                      ? LayoutBuilder(
                          builder: (context, constraints) {
                            if (_uiImage == null) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }
                            return Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.file(
                                  _imageFile!,
                                  fit: BoxFit.contain,
                                ),
                                CustomPaint(
                                  painter: DetectionPainter(
                                    detections: _detections,
                                    image: _uiImage,
                                  ),
                                ),
                                if (_isLoading)
                                  const Center(
                                      child: CircularProgressIndicator()),
                              ],
                            );
                          },
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image,
                                  size: 64, color: Colors.grey[700]),
                              const SizedBox(height: 16),
                              Text(
                                'Pick an image to detect fish',
                                style: GoogleFonts.poppins(
                                    color: Colors.grey[400]),
                              ),
                            ],
                          ),
                        ),
            ),

            // Stats
            if (_imageFile != null)
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(
                      icon: Icons.radar,
                      label: 'Detections',
                      value: '${_detections.length}',
                      color: Colors.blue,
                    ),
                    _StatItem(
                      icon: Icons.speed,
                      label: 'Time',
                      value: '${_inferenceTime}ms',
                      color: Colors.green,
                    ),
                  ],
                ),
              ),

            // Results List
            if (_detections.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Results',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _detections.length,
                itemBuilder: (context, index) {
                  return DetectionCard(detection: _detections[index]);
                },
              ),
            ],

            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'gallery',
            onPressed: () => _pickImage(ImageSource.gallery),
            child: const Icon(Icons.photo_library),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'camera',
            onPressed: () => _pickImage(ImageSource.camera),
            child: const Icon(Icons.camera_alt),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }
}
