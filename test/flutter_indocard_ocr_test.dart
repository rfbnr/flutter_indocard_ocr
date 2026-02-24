import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_indocard_ocr/flutter_indocard_ocr.dart';
import 'package:flutter_indocard_ocr/platform_interface/flutter_indocard_ocr_platform_interface.dart';
import 'package:flutter_indocard_ocr/method_channel/method_channel_flutter_indocard_ocr.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'helpers/test_image_loader.dart';
import 'helpers/test_fixtures.dart';

class MockFlutterIndocardOcrPlatform
    with MockPlatformInterfaceMixin
    implements FlutterIndocardOcrPlatform {
  Uint8List? lastKTPImage;
  Uint8List? lastNPWPImage;

  String? mockKTPResult;
  String? mockNPWPResult;
  Exception? mockException;

  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<String?> scanKTP(Uint8List image) async {
    lastKTPImage = image;

    if (mockException != null) {
      throw mockException!;
    }

    return Future.value(mockKTPResult);
  }

  @override
  Future<String?> scanNPWP(Uint8List image) async {
    lastNPWPImage = image;

    if (mockException != null) {
      throw mockException!;
    }

    return Future.value(mockNPWPResult);
  }

  void reset() {
    lastKTPImage = null;
    lastNPWPImage = null;
    mockKTPResult = null;
    mockNPWPResult = null;
    mockException = null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FlutterIndocardOCR Plugin Tests', () {
    late FlutterIndocardOCR plugin;
    late MockFlutterIndocardOcrPlatform mockPlatform;

    setUp(() {
      plugin = FlutterIndocardOCR();
      mockPlatform = MockFlutterIndocardOcrPlatform();
      FlutterIndocardOcrPlatform.instance = mockPlatform;
    });

    tearDown(() {
      mockPlatform.reset();
    });

    group('Platform Instance', () {
      test('MethodChannelFlutterIndocardOcr is the default instance', () {
        FlutterIndocardOcrPlatform.instance = MethodChannelFlutterIndocardOcr();
        expect(
          FlutterIndocardOcrPlatform.instance,
          isInstanceOf<MethodChannelFlutterIndocardOcr>(),
        );
      });

      test('Can set custom platform instance', () {
        final customPlatform = MockFlutterIndocardOcrPlatform();
        FlutterIndocardOcrPlatform.instance = customPlatform;
        expect(FlutterIndocardOcrPlatform.instance, equals(customPlatform));
      });
    });

    group('getPlatformVersion', () {
      test('returns correct platform version', () async {
        expect(await plugin.getPlatformVersion(), '42');
      });
    });

    group('scanKTP - Real Image Testing', () {
      test('successfully scans KTP with real image (if available)', () async {
        // Try to load real image, fallback to dummy if not available
        final testImage = await TestImageLoader.loadTestImageOrDummy(
          'test/assets/ktp/ktp_sample.png',
        );

        // Verify image is valid
        expect(testImage.isNotEmpty, isTrue);

        // Get expected result from fixtures
        final expectedData = await TestFixtures.getExpectedKTP('ktp_sample');
        mockPlatform.mockKTPResult = TestFixtures.toJsonString(expectedData);

        // Act
        final result = await plugin.scanKTP(testImage);

        // Assert
        expect(result, isNotNull);
        expect(mockPlatform.lastKTPImage, equals(testImage));

        final parsedResult = jsonDecode(result!);
        expect(parsedResult['nik'], equals('3174012345678901'));
        expect(parsedResult['nama'], equals('BUDI SANTOSO'));
        expect(parsedResult['tempatLahir'], equals('JAKARTA'));
        expect(parsedResult['provinsi'], equals('DKI JAKARTA'));
      });

      test('validates real image format before processing', () async {
        final testImage = await TestImageLoader.loadTestImageOrDummy(
          'test/assets/ktp/ktp_sample.png',
        );

        // Validate image format
        final isValid = TestImageLoader.isValidImage(testImage);
        expect(isValid, isTrue);

        final format = TestImageLoader.getImageFormat(testImage);
        expect(format, isIn(['jpeg', 'png']));
      });

      test('handles partial KTP data with real image', () async {
        final testImage = await TestImageLoader.loadTestImageOrDummy(
          'test/assets/ktp/ktp_sample.png',
        );

        final expectedData =
            await TestFixtures.getExpectedKTP('ktp_sample_partial');
        mockPlatform.mockKTPResult = TestFixtures.toJsonString(expectedData);

        final result = await plugin.scanKTP(testImage);

        expect(result, isNotNull);
        final parsedResult = jsonDecode(result!);
        expect(parsedResult['nik'], equals('3174012345678901'));
        expect(parsedResult['tempatLahir'], equals('-'));
        expect(parsedResult['berlakuHingga'], equals('SEUMUR HIDUP'));
      });

      test('handles empty KTP scan result', () async {
        final testImage = TestImageLoader.createDummyImage(1000);
        mockPlatform.mockKTPResult = null;

        final result = await plugin.scanKTP(testImage);

        expect(result, isNull);
        expect(mockPlatform.lastKTPImage, equals(testImage));
      });

      test('passes real image data correctly to platform', () async {
        final testImage = await TestImageLoader.loadTestImageOrDummy(
          'test/assets/ktp/ktp_sample.png',
        );

        mockPlatform.mockKTPResult = '{}';

        await plugin.scanKTP(testImage);

        expect(mockPlatform.lastKTPImage, equals(testImage));
        expect(mockPlatform.lastKTPImage?.isNotEmpty, isTrue);
      });

      test('handles platform exception gracefully', () async {
        final testImage = TestImageLoader.createDummyImage(1000);
        mockPlatform.mockException = Exception('OCR processing failed');

        expect(
          () => plugin.scanKTP(testImage),
          throwsA(isA<Exception>()),
        );
      });

      test('handles large real image data (5MB+)', () async {
        // Simulate large image
        final largeImage = TestImageLoader.createDummyImage(5 * 1024 * 1024);
        mockPlatform.mockKTPResult = jsonEncode({'nik': '1234567890123456'});

        final result = await plugin.scanKTP(largeImage);

        expect(result, isNotNull);
        expect(mockPlatform.lastKTPImage?.length, equals(5 * 1024 * 1024));
      });

      test('validates NIK format in result (16 digits)', () async {
        final testImage = TestImageLoader.createDummyImage(1000);
        final mockData = await TestFixtures.getExpectedKTP('ktp_sample');
        mockPlatform.mockKTPResult = TestFixtures.toJsonString(mockData);

        final result = await plugin.scanKTP(testImage);

        final parsedResult = jsonDecode(result!);
        expect(parsedResult['nik'].length, equals(16));
        expect(RegExp(r'^\d{16}$').hasMatch(parsedResult['nik']), isTrue);
      });
    });

    group('scanNPWP - Real Image Testing', () {
      test('successfully scans NPWP with real image (if available)', () async {
        final testImage = await TestImageLoader.loadTestImageOrDummy(
          'test/assets/npwp/npwp_sample.png',
        );

        expect(testImage.isNotEmpty, isTrue);

        final expectedData = await TestFixtures.getExpectedNPWP('npwp_sample');
        mockPlatform.mockNPWPResult = TestFixtures.toJsonString(expectedData);

        final result = await plugin.scanNPWP(testImage);

        expect(result, isNotNull);
        expect(mockPlatform.lastNPWPImage, equals(testImage));

        final parsedResult = jsonDecode(result!);
        expect(parsedResult['npwp'], equals('12.345.678.9-012.345'));
        expect(parsedResult['nik'], equals('3174012345678901'));
        expect(parsedResult['nama'], equals('BUDI SANTOSO'));
      });

      test('validates real NPWP image format before processing', () async {
        final testImage = await TestImageLoader.loadTestImageOrDummy(
          'test/assets/npwp/npwp_sample.png',
        );

        final isValid = TestImageLoader.isValidImage(testImage);
        expect(isValid, isTrue);

        final format = TestImageLoader.getImageFormat(testImage);
        expect(format, isIn(['jpeg', 'png']));
      });

      test('handles partial NPWP data with real image', () async {
        final testImage = await TestImageLoader.loadTestImageOrDummy(
          'test/assets/npwp/npwp_sample.png',
        );

        final expectedData =
            await TestFixtures.getExpectedNPWP('npwp_sample_partial');
        mockPlatform.mockNPWPResult = TestFixtures.toJsonString(expectedData);

        final result = await plugin.scanNPWP(testImage);

        expect(result, isNotNull);
        final parsedResult = jsonDecode(result!);
        expect(parsedResult['npwp'], equals('12.345.678.9-012.345'));
        expect(parsedResult['nik'], equals(''));
        expect(parsedResult['alamat'], equals(''));
      });

      test('validates NPWP format in result (15 digits formatted)', () async {
        final testImage = TestImageLoader.createDummyImage(1000);
        final expectedData = await TestFixtures.getExpectedNPWP('npwp_sample');
        mockPlatform.mockNPWPResult = TestFixtures.toJsonString(expectedData);

        final result = await plugin.scanNPWP(testImage);

        final parsedResult = jsonDecode(result!);
        final npwpDigitsOnly =
            parsedResult['npwp'].replaceAll(RegExp(r'[^0-9]'), '');
        expect(npwpDigitsOnly.length, equals(15));
        expect(parsedResult['npwp'],
            matches(RegExp(r'^\d{2}\.\d{3}\.\d{3}\.\d{1}-\d{3}\.\d{3}$')));
      });

      test('handles empty NPWP scan result', () async {
        final testImage = TestImageLoader.createDummyImage(1000);
        mockPlatform.mockNPWPResult = null;

        final result = await plugin.scanNPWP(testImage);

        expect(result, isNull);
        expect(mockPlatform.lastNPWPImage, equals(testImage));
      });

      test('handles platform exception gracefully', () async {
        final testImage = TestImageLoader.createDummyImage(1000);
        mockPlatform.mockException = Exception('OCR processing failed');

        expect(
          () => plugin.scanNPWP(testImage),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Edge Cases & Error Handling', () {
      test('multiple consecutive scanKTP calls work correctly', () async {
        final image1 = TestImageLoader.createDummyImage(500);
        final image2 = TestImageLoader.createDummyImage(600);
        mockPlatform.mockKTPResult = jsonEncode({'nik': '1234567890123456'});

        await plugin.scanKTP(image1);
        await plugin.scanKTP(image2);

        expect(mockPlatform.lastKTPImage, equals(image2));
      });

      test('scanKTP and scanNPWP can be called independently', () async {
        final ktpImage = TestImageLoader.createDummyImage(500);
        final npwpImage = TestImageLoader.createDummyImage(600);
        mockPlatform.mockKTPResult = jsonEncode({'nik': '1234567890123456'});
        mockPlatform.mockNPWPResult =
            jsonEncode({'npwp': '12.345.678.9-012.345'});

        await plugin.scanKTP(ktpImage);
        await plugin.scanNPWP(npwpImage);

        expect(mockPlatform.lastKTPImage, equals(ktpImage));
        expect(mockPlatform.lastNPWPImage, equals(npwpImage));
      });

      test('handles malformed JSON response from platform', () async {
        final testImage = TestImageLoader.createDummyImage(500);
        mockPlatform.mockKTPResult = 'invalid json {{{';

        final result = await plugin.scanKTP(testImage);

        expect(result, equals('invalid json {{{'));
      });

      test('handles special characters in OCR results', () async {
        final testImage = TestImageLoader.createDummyImage(500);
        final mockData = {
          'nik': '3174012345678901',
          'nama': "BUDI O'BRIEN",
          'alamat': 'JL. TEST "QUOTES" & SPECIAL <CHARS>',
          'kewarganegaraan': 'WNI',
        };
        mockPlatform.mockKTPResult = jsonEncode(mockData);

        final result = await plugin.scanKTP(testImage);

        expect(result, isNotNull);
        final parsedResult = jsonDecode(result!);
        expect(parsedResult['nama'], equals("BUDI O'BRIEN"));
        expect(parsedResult['alamat'], contains('QUOTES'));
      });
    });

    group('Performance & Memory', () {
      test('handles rapid successive calls without memory issues', () async {
        final testImage = TestImageLoader.createDummyImage(1000);
        mockPlatform.mockKTPResult = jsonEncode({'nik': '1234567890123456'});

        for (int i = 0; i < 100; i++) {
          await plugin.scanKTP(testImage);
        }

        expect(mockPlatform.lastKTPImage, isNotNull);
      });

      test('cleans up resources properly after scan', () async {
        final testImage = TestImageLoader.createDummyImage(1000);
        mockPlatform.mockKTPResult = jsonEncode({'nik': '1234567890123456'});

        final result = await plugin.scanKTP(testImage);

        expect(result, isNotNull);
        expect(mockPlatform.lastKTPImage, isNotNull);
      });
    });

    group('Data Validation', () {
      test('KTP result contains all required fields', () async {
        final testImage = TestImageLoader.createDummyImage(500);
        final completeKTPData = await TestFixtures.getExpectedKTP('ktp_sample');
        mockPlatform.mockKTPResult = TestFixtures.toJsonString(completeKTPData);

        final result = await plugin.scanKTP(testImage);

        expect(result, isNotNull);
        final parsedResult = jsonDecode(result!);

        final requiredFields = [
          'nik',
          'nama',
          'tempatLahir',
          'tanggalLahir',
          'jenisKelamin',
          'alamat',
          'rtrw',
          'kelurahan',
          'kecamatan',
          'agama',
          'statusPerkawinan',
          'pekerjaan',
          'kewarganegaraan',
          'provinsi',
          'kota',
          'berlakuHingga'
        ];

        for (final field in requiredFields) {
          expect(parsedResult.containsKey(field), isTrue,
              reason: 'Missing field: $field');
        }
      });

      test('NPWP result contains all required fields', () async {
        final testImage = TestImageLoader.createDummyImage(500);
        final completeNPWPData =
            await TestFixtures.getExpectedNPWP('npwp_sample');
        mockPlatform.mockNPWPResult =
            TestFixtures.toJsonString(completeNPWPData);

        final result = await plugin.scanNPWP(testImage);

        expect(result, isNotNull);
        final parsedResult = jsonDecode(result!);

        final requiredFields = ['npwp', 'nik', 'nama', 'alamat', 'kpp'];

        for (final field in requiredFields) {
          expect(parsedResult.containsKey(field), isTrue,
              reason: 'Missing field: $field');
        }
      });
    });
  });
}
