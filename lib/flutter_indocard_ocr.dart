import 'dart:typed_data';

import 'flutter_indocard_ocr_platform_interface.dart';

class FlutterIndocardOcr {
  Future<String?> getPlatformVersion() {
    return FlutterIndocardOcrPlatform.instance.getPlatformVersion();
  }

  /// Scans a KTP image and returns the extracted data as a JSON string.
  /// [image] is the image data in Uint8List format.
  /// Returns a JSON string containing the extracted data or null if scanning fails.
  /// Example:
  /// ```dart
  /// Uint8List image = ...; // Load your KTP image here
  /// String? result = await FlutterIndocardOcr().scanKTP(image);
  /// ```
  Future<String?> scanKTP(Uint8List image) {
    return FlutterIndocardOcrPlatform.instance.scanKTP(image);
  }

  /// Scans an NPWP image and returns the extracted data as a JSON string.
  /// [image] is the image data in Uint8List format.
  /// Returns a JSON string containing the extracted data or null if scanning fails.
  /// Example:
  /// ```dart
  /// Uint8List image = ...; // Load your NPWP image here
  /// String? result = await FlutterIndocardOcr().scanNPWP(image);
  /// ```
  Future<String?> scanNPWP(Uint8List image) {
    return FlutterIndocardOcrPlatform.instance.scanNPWP(image);
  }
}
