import 'dart:io';
import 'package:flutter/services.dart';

/// Helper class for loading test images in different testing contexts
class TestImageLoader {
  /// Load image from file system (for unit tests)
  /// Used when running tests without Flutter's asset system
  static Future<Uint8List> loadFromFile(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw Exception('Test image not found: $path');
    }
    return await file.readAsBytes();
  }

  /// Load image from assets (for integration tests)
  /// Used when running tests with Flutter's asset system
  static Future<Uint8List> loadFromAssets(String assetPath) async {
    try {
      final ByteData data = await rootBundle.load(assetPath);
      return data.buffer.asUint8List();
    } catch (e) {
      throw Exception('Failed to load asset: $assetPath - $e');
    }
  }

  /// Validate if bytes represent a valid image
  /// Checks for JPEG, PNG, and other common image formats
  static bool isValidImage(Uint8List bytes) {
    if (bytes.isEmpty) return false;

    // Check for JPEG magic number (FF D8 FF)
    if (bytes.length > 2 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return true;
    }

    // Check for PNG magic number (89 50 4E 47)
    if (bytes.length > 3 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return true;
    }

    return false;
  }

  /// Get image format from bytes
  static String getImageFormat(Uint8List bytes) {
    if (bytes.isEmpty) return 'unknown';

    // JPEG
    if (bytes.length > 2 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return 'jpeg';
    }

    // PNG
    if (bytes.length > 3 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'png';
    }

    return 'unknown';
  }

  /// Try to load image from file first, fallback to creating dummy data
  /// Useful for tests that can run with or without real images
  static Future<Uint8List> loadTestImageOrDummy(String filePath) async {
    try {
      return await loadFromFile(filePath);
    } catch (e) {
      // Return dummy JPEG-like data if file not found
      return Uint8List.fromList([
        0xFF, 0xD8, 0xFF, 0xE0, // JPEG header
        ...List.generate(100, (i) => i % 256),
        0xFF, 0xD9, // JPEG footer
      ]);
    }
  }

  /// Create a dummy image with specific size (for performance testing)
  static Uint8List createDummyImage(int sizeInBytes) {
    return Uint8List.fromList([
      0xFF, 0xD8, 0xFF, 0xE0, // JPEG header
      ...List.generate(sizeInBytes - 6, (i) => i % 256),
      0xFF, 0xD9, // JPEG footer
    ]);
  }
}
