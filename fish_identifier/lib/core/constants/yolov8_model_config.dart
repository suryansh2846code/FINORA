import 'dart:ui';

class YoloV8ModelConfig {
  // Model paths
  static const String modelPath = 'assets/models/fish_yolov8n.tflite';

  // Model parameters
  static const int inputSize = 640;
  static const double confidenceThreshold = 0.25;
  static const double iouThreshold = 0.45;
  static const int numChannels = 3;

  // Class labels - From Fish-Detection-1 dataset
  static const List<String> labels = [
    'Gilt-Head Bream',
    'Red sea bream',
    'Striped Red Mullet',
    'black sea sprat',
    'house mackerel',
    'red mullet',
    'sea bass',
    'shrimp',
    'trout',
  ];

  // Colors for each class
  static const Map<String, Color> classColors = {
    'Gilt-Head Bream': Color(0xFF4CAF50), // Green
    'Red sea bream': Color(0xFFF44336), // Red
    'Striped Red Mullet': Color(0xFFFF9800), // Orange
    'black sea sprat': Color(0xFF2196F3), // Blue
    'house mackerel': Color(0xFF9C27B0), // Purple
    'red mullet': Color(0xFFFFEB3B), // Yellow
    'sea bass': Color(0xFF00BCD4), // Cyan
    'shrimp': Color(0xFFE91E63), // Pink
    'trout': Color(0xFF795548), // Brown
  };

  // Emoji icons for each class
  static const Map<String, String> classIcons = {
    'Gilt-Head Bream': '🐟',
    'Red sea bream': '🐠',
    'Striped Red Mullet': '🐟',
    'black sea sprat': '🐟',
    'house mackerel': '🐟',
    'red mullet': '🐟',
    'sea bass': '🐟',
    'shrimp': '🦐',
    'trout': '🐟',
  };

  // Model output configuration
  static const int maxDetections = 300;
  static const int stride = 32;
}
