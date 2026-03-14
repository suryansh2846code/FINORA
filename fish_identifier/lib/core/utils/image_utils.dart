import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class PreprocessResult {
  final Float32List data;
  final double scale;
  final double padX;
  final double padY;

  PreprocessResult({
    required this.data,
    required this.scale,
    required this.padX,
    required this.padY,
  });
}

class ImageUtils {
  /// Resize and preprocess image for model input using letterboxing
  static Future<PreprocessResult> preprocessImage(
    File imageFile,
    int targetSize,
  ) async {
    // Read image bytes
    final bytes = await imageFile.readAsBytes();

    // Decode image
    img.Image? image = img.decodeImage(bytes);
    if (image == null) {
      throw Exception('Failed to decode image');
    }

    // Handle EXIF orientation
    image = img.bakeOrientation(image);

    // Calculate scaling factor and padding for letterboxing
    final double scale =
        targetSize / (image.width > image.height ? image.width : image.height);
    final int newWidth = (image.width * scale).round();
    final int newHeight = (image.height * scale).round();

    final int padX = (targetSize - newWidth) ~/ 2;
    final int padY = (targetSize - newHeight) ~/ 2;

    // Resize image maintaining aspect ratio
    img.Image resized = img.copyResize(
      image,
      width: newWidth,
      height: newHeight,
      interpolation: img.Interpolation.linear,
    );

    // Create targetSize x targetSize canvas filled with gray (114 for YOLO)
    img.Image letterboxed = img.Image(width: targetSize, height: targetSize);
    img.fill(letterboxed, color: img.ColorRgb8(114, 114, 114));

    // Draw resized image onto the center of the canvas
    img.compositeImage(
      letterboxed,
      resized,
      dstX: padX,
      dstY: padY,
    );

    // Convert to Float32List normalized to [0, 1]
    final convertedBytes = Float32List(targetSize * targetSize * 3);
    int pixelIndex = 0;

    for (int y = 0; y < targetSize; y++) {
      for (int x = 0; x < targetSize; x++) {
        final pixel = letterboxed.getPixel(x, y);
        convertedBytes[pixelIndex++] = pixel.r / 255.0;
        convertedBytes[pixelIndex++] = pixel.g / 255.0;
        convertedBytes[pixelIndex++] = pixel.b / 255.0;
      }
    }

    return PreprocessResult(
      data: convertedBytes,
      scale: scale,
      padX: padX.toDouble(),
      padY: padY.toDouble(),
    );
  }

  /// Resize and preprocess image for SAM (Standardization)
  static Future<Float32List> preprocessImageForSam(
    File imageFile,
    int targetSize,
  ) async {
    // Read image bytes
    final bytes = await imageFile.readAsBytes();

    // Decode image
    img.Image? image = img.decodeImage(bytes);
    if (image == null) {
      throw Exception('Failed to decode image');
    }

    // Resize to target size (1024) preserving aspect ratio
    final double scale =
        targetSize / (image.width > image.height ? image.width : image.height);
    final int newWidth = (image.width * scale).round();
    final int newHeight = (image.height * scale).round();

    img.Image resized = img.copyResize(
      image,
      width: newWidth,
      height: newHeight,
      interpolation: img.Interpolation.linear,
    );

    // Create 1024x1024 canvas filled with zeros (black)
    // Note: In C++ implementation, padding value is 0.
    final convertedBytes = Float32List(targetSize * targetSize * 3);

    // Fill with zeros is implicit for Float32List, but let's be sure about the layout.
    // We need to place the resized image at (0,0).

    // Mean: [123.675, 116.28, 103.53]
    // Std: [58.395, 57.12, 57.375]

    for (int y = 0; y < newHeight; y++) {
      for (int x = 0; x < newWidth; x++) {
        final pixel = resized.getPixel(x, y);

        final r = pixel.r;
        final g = pixel.g;
        final b = pixel.b;

        // Calculate index in the 1024x1024 flat buffer
        // Row-major: index = (y * targetSize + x) * 3
        final int index = (y * targetSize + x) * 3;

        convertedBytes[index] = (r - 123.675) / 58.395;
        convertedBytes[index + 1] = (g - 116.28) / 57.12;
        convertedBytes[index + 2] = (b - 103.53) / 57.375;
      }
    }
    // The rest of the buffer (padding) remains 0.0

    return convertedBytes;
  }

  /// Resize and preprocess image for model input (Uint8)
  static Future<Uint8List> preprocessImageUint8(
    File imageFile,
    int targetSize,
  ) async {
    // Read image bytes
    final bytes = await imageFile.readAsBytes();

    // Decode image
    img.Image? image = img.decodeImage(bytes);
    if (image == null) {
      throw Exception('Failed to decode image');
    }

    // Resize to target size
    img.Image resized = img.copyResize(
      image,
      width: targetSize,
      height: targetSize,
      interpolation: img.Interpolation.linear,
    );

    // Convert to Uint8List [0, 255]
    final convertedBytes = Uint8List(targetSize * targetSize * 3);
    int pixelIndex = 0;

    for (int y = 0; y < targetSize; y++) {
      for (int x = 0; x < targetSize; x++) {
        final pixel = resized.getPixel(x, y);
        convertedBytes[pixelIndex++] = pixel.r.toInt();
        convertedBytes[pixelIndex++] = pixel.g.toInt();
        convertedBytes[pixelIndex++] = pixel.b.toInt();
      }
    }

    return convertedBytes;
  }

  /// Get image dimensions with EXIF orientation handled
  static Future<img.Image?> decodeImage(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) return null;
    return img.bakeOrientation(image);
  }

  /// Compress image if it's too large
  static Future<File> compressImageIfNeeded(
    File file, {
    int maxSizeKB = 2048,
  }) async {
    final fileSize = await file.length();

    if (fileSize <= maxSizeKB * 1024) {
      return file;
    }

    final bytes = await file.readAsBytes();
    img.Image? image = img.decodeImage(bytes);

    if (image == null) return file;

    // Calculate compression quality
    final int quality = (maxSizeKB * 1024 * 100) ~/ fileSize;

    // Encode with compression
    final compressed = img.encodeJpg(image, quality: quality.clamp(20, 95));

    // Write back to file
    await file.writeAsBytes(compressed);

    return file;
  }
}
