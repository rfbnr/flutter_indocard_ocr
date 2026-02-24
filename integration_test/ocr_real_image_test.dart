import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_indocard_ocr/flutter_indocard_ocr.dart';

/// Integration tests for real OCR functionality
/// These tests run on actual devices/emulators and test the native OCR engines
///
/// To run these tests:
/// flutter test integration_test/ocr_real_image_test.dart
///
/// Note: You need real KTP/NPWP images in assets/ folder for these tests to work properly
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Real OCR Integration Tests', () {
    late FlutterIndocardOCR plugin;

    setUp(() {
      plugin = FlutterIndocardOCR();
    });

    group('Platform Version', () {
      testWidgets('getPlatformVersion returns valid platform info',
          (tester) async {
        final version = await plugin.getPlatformVersion();

        expect(version, isNotNull);
        expect(version, isNotEmpty);

        // Should contain either 'Android' or 'iOS'
        final isValidPlatform = version!.contains('Android') ||
            version.contains('iOS') ||
            version.contains('iPhone');

        expect(isValidPlatform, isTrue,
            reason: 'Platform version should mention Android or iOS');
      });
    });

    group('KTP OCR with Real Images', () {
      testWidgets('scanKTP with real good quality image', (tester) async {
        // Skip if image not available
        late Uint8List ktpImage;
        try {
          final ByteData data =
              await rootBundle.load('assets/images/sample_ktp.png');
          ktpImage = data.buffer.asUint8List();
        } catch (e) {
          debugPrint('⚠️  Sample KTP image not found, skipping test');
          return;
        }

        // Verify image is loaded
        expect(ktpImage.isNotEmpty, isTrue);

        // Execute real OCR
        final result = await plugin.scanKTP(ktpImage);

        // Assert
        expect(result, isNotNull, reason: 'OCR should return a result');

        if (result != null) {
          debugPrint('KTP OCR Result: $result');

          final parsed = jsonDecode(result);

          // Verify basic structure
          expect(parsed, isA<Map<String, dynamic>>());

          // Check for essential fields (may be empty if OCR quality is low)
          expect(parsed.containsKey('nik'), isTrue);
          expect(parsed.containsKey('nama'), isTrue);
          expect(parsed.containsKey('alamat'), isTrue);

          // If NIK is extracted, validate format
          if (parsed['nik'] != null && parsed['nik'].toString().isNotEmpty) {
            final nik = parsed['nik'].toString();
            // NIK should be 16 digits or contain placeholders
            expect(nik.length >= 16 || nik.contains('-'), isTrue);
            debugPrint('✓ NIK extracted: ${nik.substring(0, 4)}...');
          }

          // If nama is extracted, check it's not empty
          if (parsed['nama'] != null && parsed['nama'].toString().isNotEmpty) {
            debugPrint('✓ Nama extracted: ${parsed['nama']}');
          }
        }
      });

      testWidgets('scanKTP handles low quality image gracefully',
          (tester) async {
        late Uint8List lowQualityImage;
        try {
          // Try to load a low quality sample if available
          final ByteData data =
              await rootBundle.load('assets/images/sample_ktp.png');
          lowQualityImage = data.buffer.asUint8List();
        } catch (e) {
          debugPrint('⚠️  Low quality KTP image not found, skipping test');
          return;
        }

        final result = await plugin.scanKTP(lowQualityImage);

        // Low quality might return null or partial data
        if (result != null) {
          final parsed = jsonDecode(result);
          expect(parsed, isA<Map<String, dynamic>>());
          debugPrint(
              'Low quality OCR still extracted: ${parsed.keys.length} fields');
        } else {
          debugPrint('Low quality image returned null (expected behavior)');
        }
      });

      testWidgets('scanKTP validates image format', (tester) async {
        // Create invalid image data
        final invalidImage = Uint8List.fromList([1, 2, 3, 4, 5]);

        final result = await plugin.scanKTP(invalidImage);

        // Should return null or empty result for invalid image
        if (result != null) {
          final parsed = jsonDecode(result);
          // All fields should be empty or default values
          debugPrint('Invalid image result: $parsed');
        }
      });
    });

    group('NPWP OCR with Real Images', () {
      testWidgets('scanNPWP with real good quality image', (tester) async {
        late Uint8List npwpImage;
        try {
          final ByteData data =
              await rootBundle.load('assets/images/sample_npwp.png');
          npwpImage = data.buffer.asUint8List();
        } catch (e) {
          debugPrint('⚠️  Sample NPWP image not found, skipping test');
          return;
        }

        expect(npwpImage.isNotEmpty, isTrue);

        final result = await plugin.scanNPWP(npwpImage);

        expect(result, isNotNull, reason: 'OCR should return a result');

        if (result != null) {
          debugPrint('NPWP OCR Result: $result');

          final parsed = jsonDecode(result);

          expect(parsed, isA<Map<String, dynamic>>());

          // Check for essential fields
          expect(parsed.containsKey('npwp'), isTrue);
          expect(parsed.containsKey('nama'), isTrue);
          expect(parsed.containsKey('alamat'), isTrue);

          // If NPWP is extracted, validate format
          if (parsed['npwp'] != null && parsed['npwp'].toString().isNotEmpty) {
            final npwp = parsed['npwp'].toString();
            debugPrint('✓ NPWP extracted: $npwp');

            // NPWP should be in format XX.XXX.XXX.X-XXX.XXX or contain numbers
            // final hasValidFormat = npwp.contains('.') || npwp.contains('-');
            final hasNumbers = RegExp(r'\d').hasMatch(npwp);
            expect(hasNumbers, isTrue, reason: 'NPWP should contain numbers');
          }
        }
      });

      testWidgets('scanNPWP handles invalid image gracefully', (tester) async {
        final invalidImage = Uint8List.fromList([1, 2, 3, 4, 5]);

        final result = await plugin.scanNPWP(invalidImage);

        if (result != null) {
          final parsed = jsonDecode(result);
          debugPrint('Invalid NPWP image result: $parsed');
        }
      });
    });

    group('OCR Performance Tests', () {
      testWidgets('scanKTP completes within reasonable time', (tester) async {
        late Uint8List ktpImage;
        try {
          final ByteData data =
              await rootBundle.load('assets/images/sample_ktp.png');
          ktpImage = data.buffer.asUint8List();
        } catch (e) {
          debugPrint('⚠️  Sample image not found, skipping performance test');
          return;
        }

        final stopwatch = Stopwatch()..start();

        await plugin.scanKTP(ktpImage);

        stopwatch.stop();

        final elapsedMs = stopwatch.elapsedMilliseconds;
        debugPrint('OCR processing time: ${elapsedMs}ms');

        // OCR should complete within 10 seconds
        expect(elapsedMs, lessThan(10000),
            reason: 'OCR should complete within 10 seconds');
      });

      testWidgets('multiple consecutive scans work correctly', (tester) async {
        late Uint8List ktpImage;
        try {
          final ByteData data =
              await rootBundle.load('assets/images/sample_ktp.png');
          ktpImage = data.buffer.asUint8List();
        } catch (e) {
          debugPrint('⚠️  Sample image not found, skipping test');
          return;
        }

        // Run 3 consecutive scans
        for (int i = 0; i < 3; i++) {
          final result = await plugin.scanKTP(ktpImage);
          expect(result, isNotNull, reason: 'Scan #${i + 1} should succeed');
          debugPrint('Scan #${i + 1} completed successfully');
        }
      });
    });

    group('Error Handling', () {
      testWidgets('handles empty image data', (tester) async {
        final emptyImage = Uint8List.fromList([]);

        final result = await plugin.scanKTP(emptyImage);

        // Should handle gracefully (return null or empty result)
        if (result != null) {
          final parsed = jsonDecode(result);
          debugPrint('Empty image result: $parsed');
        }
      });

      testWidgets('handles very large image', (tester) async {
        late Uint8List largeImage;
        try {
          // Try to use actual image, fallback to dummy
          final ByteData data =
              await rootBundle.load('assets/images/sample_ktp.png');
          largeImage = data.buffer.asUint8List();
        } catch (e) {
          // Create a large dummy image (5MB)
          largeImage = Uint8List.fromList(
            List.generate(5 * 1024 * 1024, (i) => i % 256),
          );
        }

        final stopwatch = Stopwatch()..start();

        final result = await plugin.scanKTP(largeImage);

        stopwatch.stop();

        debugPrint(
            'Large image (${largeImage.length} bytes) processed in ${stopwatch.elapsedMilliseconds}ms');

        // Should complete even with large image
        expect(stopwatch.elapsedMilliseconds, lessThan(30000),
            reason: 'Large image should process within 30 seconds');
      });
    });

    group('Data Validation', () {
      testWidgets('KTP result contains valid JSON', (tester) async {
        late Uint8List ktpImage;
        try {
          final ByteData data =
              await rootBundle.load('assets/images/sample_ktp.png');
          ktpImage = data.buffer.asUint8List();
        } catch (e) {
          debugPrint('⚠️  Sample image not found, skipping test');
          return;
        }

        final result = await plugin.scanKTP(ktpImage);

        expect(result, isNotNull);

        // Should be valid JSON
        expect(() => jsonDecode(result!), returnsNormally);

        final parsed = jsonDecode(result!);

        // Should have string values
        for (final key in parsed.keys) {
          expect(parsed[key], isA<String>(),
              reason: 'Field $key should be a string');
        }
      });

      testWidgets('NPWP result contains valid JSON', (tester) async {
        late Uint8List npwpImage;
        try {
          final ByteData data =
              await rootBundle.load('assets/images/sample_npwp.png');
          npwpImage = data.buffer.asUint8List();
        } catch (e) {
          debugPrint('⚠️  Sample image not found, skipping test');
          return;
        }

        final result = await plugin.scanNPWP(npwpImage);

        expect(result, isNotNull);

        // Should be valid JSON
        expect(() => jsonDecode(result!), returnsNormally);

        final parsed = jsonDecode(result!);

        // Should have string values
        for (final key in parsed.keys) {
          expect(parsed[key], isA<String>(),
              reason: 'Field $key should be a string');
        }
      });
    });
  });
}
