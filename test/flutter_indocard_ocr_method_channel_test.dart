import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_indocard_ocr/method_channel/method_channel_flutter_indocard_ocr.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MethodChannelFlutterIndocardOcr Tests', () {
    late MethodChannelFlutterIndocardOcr platform;
    const MethodChannel channel = MethodChannel('flutter_indocard_ocr');

    // Track method calls
    final List<MethodCall> methodCallLog = [];

    setUp(() {
      platform = MethodChannelFlutterIndocardOcr();
      methodCallLog.clear();
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    group('Channel Configuration', () {
      test('uses correct channel name', () {
        expect(
          MethodChannelFlutterIndocardOcr.channelName,
          equals('flutter_indocard_ocr'),
        );
      });

      test('methodChannel is properly initialized', () {
        expect(platform.methodChannel, isNotNull);
        expect(platform.methodChannel.name, equals('flutter_indocard_ocr'));
      });
    });

    group('getPlatformVersion', () {
      test('invokes correct method and returns platform version', () async {
        // Arrange
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          methodCallLog.add(methodCall);
          return 'Android 13';
        });

        // Act
        final result = await platform.getPlatformVersion();

        // Assert
        expect(result, equals('Android 13'));
        expect(methodCallLog.length, equals(1));
        expect(methodCallLog[0].method, equals('getPlatformVersion'));
        expect(methodCallLog[0].arguments, isNull);
      });

      test('returns iOS version string', () async {
        // Arrange
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          return 'iOS 16.0';
        });

        // Act
        final result = await platform.getPlatformVersion();

        // Assert
        expect(result, equals('iOS 16.0'));
      });

      test('handles null response', () async {
        // Arrange
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          return null;
        });

        // Act
        final result = await platform.getPlatformVersion();

        // Assert
        expect(result, isNull);
      });

      test('throws exception when platform method fails', () async {
        // Arrange
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          throw PlatformException(
            code: 'ERROR',
            message: 'Platform error occurred',
          );
        });

        // Act & Assert
        expect(
          () => platform.getPlatformVersion(),
          throwsA(isA<PlatformException>()),
        );
      });
    });

    group('scanKTP', () {
      test('invokes correct method with image data', () async {
        // Arrange
        final testImage = Uint8List.fromList([1, 2, 3, 4, 5]);
        final mockResponse = jsonEncode({
          'nik': '3174012345678901',
          'nama': 'BUDI SANTOSO',
          'tempatLahir': 'JAKARTA',
          'tanggalLahir': '12-05-1990',
          'jenisKelamin': 'LAKI-LAKI',
          'alamat': 'JL. SUDIRMAN NO. 123',
          'rtrw': '001/002',
          'kelurahan': 'SENAYAN',
          'kecamatan': 'KEBAYORAN BARU',
          'agama': 'ISLAM',
          'statusPerkawinan': 'BELUM KAWIN',
          'pekerjaan': 'KARYAWAN SWASTA',
          'kewarganegaraan': 'WNI',
          'provinsi': 'DKI JAKARTA',
          'kota': 'JAKARTA SELATAN',
          'berlakuHingga': 'SEUMUR HIDUP',
        });

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          methodCallLog.add(methodCall);
          return mockResponse;
        });

        // Act
        final result = await platform.scanKTP(testImage);

        // Assert
        expect(result, isNotNull);
        expect(result, equals(mockResponse));
        expect(methodCallLog.length, equals(1));
        expect(methodCallLog[0].method, equals('scanKTP'));
        expect(methodCallLog[0].arguments, isNotNull);
        expect(methodCallLog[0].arguments['image'], equals(testImage));
      });

      test('passes correct arguments structure', () async {
        // Arrange
        final testImage = Uint8List.fromList([10, 20, 30]);

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          methodCallLog.add(methodCall);
          return '{}';
        });

        // Act
        await platform.scanKTP(testImage);

        // Assert
        final args = methodCallLog[0].arguments as Map;
        expect(args.containsKey('image'), isTrue);
        expect(args['image'], isA<Uint8List>());
        expect(args['image'], equals(testImage));
      });

      test('handles null response from platform', () async {
        // Arrange
        final testImage = Uint8List.fromList([1, 2, 3]);

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          return null;
        });

        // Act
        final result = await platform.scanKTP(testImage);

        // Assert
        expect(result, isNull);
      });

      test('handles empty image data', () async {
        // Arrange
        final emptyImage = Uint8List.fromList([]);

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          methodCallLog.add(methodCall);
          return null;
        });

        // Act
        final result = await platform.scanKTP(emptyImage);

        // Assert
        expect(result, isNull);
        expect(methodCallLog[0].arguments['image'], equals(emptyImage));
      });

      test('handles large image data', () async {
        // Arrange - 10MB image
        final largeImage =
            Uint8List.fromList(List.generate(10 * 1024 * 1024, (i) => i % 256));

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          methodCallLog.add(methodCall);
          return jsonEncode({'nik': '1234567890123456'});
        });

        // Act
        final result = await platform.scanKTP(largeImage);

        // Assert
        expect(result, isNotNull);
        expect(methodCallLog[0].arguments['image'], equals(largeImage));
      });

      test('throws PlatformException when OCR fails', () async {
        // Arrange
        final testImage = Uint8List.fromList([1, 2, 3]);

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          throw PlatformException(
            code: 'OCR_ERROR',
            message: 'Failed to process KTP image',
            details: 'Image quality too low',
          );
        });

        // Act & Assert
        try {
          await platform.scanKTP(testImage);
          fail('Should have thrown PlatformException');
        } catch (e) {
          expect(e, isA<PlatformException>());
          final platformError = e as PlatformException;
          expect(platformError.code, equals('OCR_ERROR'));
          expect(platformError.message, equals('Failed to process KTP image'));
          expect(platformError.details, equals('Image quality too low'));
        }
      });

      test('handles partial KTP data response', () async {
        // Arrange
        final testImage = Uint8List.fromList([1, 2, 3]);
        final partialResponse = jsonEncode({
          'nik': '3174012345678901',
          'nama': 'BUDI SANTOSO',
          'tempatLahir': '-',
          'tanggalLahir': '-',
          'jenisKelamin': '-',
          'alamat': '-',
          'rtrw': '000/000',
          'kelurahan': '-',
          'kecamatan': '-',
          'agama': '-',
          'statusPerkawinan': '-',
          'pekerjaan': '-',
          'kewarganegaraan': 'WNI',
          'provinsi': '-',
          'kota': '-',
          'berlakuHingga': 'SEUMUR HIDUP',
        });

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          return partialResponse;
        });

        // Act
        final result = await platform.scanKTP(testImage);

        // Assert
        expect(result, equals(partialResponse));
        final parsed = jsonDecode(result!);
        expect(parsed['nik'], equals('3174012345678901'));
        expect(parsed['tempatLahir'], equals('-'));
      });
    });

    group('scanNPWP', () {
      test('invokes correct method with image data', () async {
        // Arrange
        final testImage = Uint8List.fromList([1, 2, 3, 4, 5]);
        final mockResponse = jsonEncode({
          'npwp': '12.345.678.9-012.345',
          'nik': '3174012345678901',
          'nama': 'BUDI SANTOSO',
          'alamat': 'JL. SUDIRMAN NO. 123, JAKARTA SELATAN',
          'kpp': 'KPP PRATAMA JAKARTA KEBAYORAN BARU',
        });

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          methodCallLog.add(methodCall);
          return mockResponse;
        });

        // Act
        final result = await platform.scanNPWP(testImage);

        // Assert
        expect(result, isNotNull);
        expect(result, equals(mockResponse));
        expect(methodCallLog.length, equals(1));
        expect(methodCallLog[0].method, equals('scanNPWP'));
        expect(methodCallLog[0].arguments, isNotNull);
        expect(methodCallLog[0].arguments['image'], equals(testImage));
      });

      test('passes correct arguments structure', () async {
        // Arrange
        final testImage = Uint8List.fromList([10, 20, 30]);

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          methodCallLog.add(methodCall);
          return '{}';
        });

        // Act
        await platform.scanNPWP(testImage);

        // Assert
        final args = methodCallLog[0].arguments as Map;
        expect(args.containsKey('image'), isTrue);
        expect(args['image'], isA<Uint8List>());
        expect(args['image'], equals(testImage));
      });

      test('handles null response from platform', () async {
        // Arrange
        final testImage = Uint8List.fromList([1, 2, 3]);

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          return null;
        });

        // Act
        final result = await platform.scanNPWP(testImage);

        // Assert
        expect(result, isNull);
      });

      test('handles empty image data', () async {
        // Arrange
        final emptyImage = Uint8List.fromList([]);

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          methodCallLog.add(methodCall);
          return null;
        });

        // Act
        final result = await platform.scanNPWP(emptyImage);

        // Assert
        expect(result, isNull);
        expect(methodCallLog[0].arguments['image'], equals(emptyImage));
      });

      test('throws PlatformException when OCR fails', () async {
        // Arrange
        final testImage = Uint8List.fromList([1, 2, 3]);

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          throw PlatformException(
            code: 'OCR_ERROR',
            message: 'Failed to process NPWP image',
            details: 'Invalid image format',
          );
        });

        // Act & Assert
        try {
          await platform.scanNPWP(testImage);
          fail('Should have thrown PlatformException');
        } catch (e) {
          expect(e, isA<PlatformException>());
          final platformError = e as PlatformException;
          expect(platformError.code, equals('OCR_ERROR'));
          expect(platformError.message, equals('Failed to process NPWP image'));
          expect(platformError.details, equals('Invalid image format'));
        }
      });

      test('handles partial NPWP data response', () async {
        // Arrange
        final testImage = Uint8List.fromList([1, 2, 3]);
        final partialResponse = jsonEncode({
          'npwp': '12.345.678.9-012.345',
          'nik': '',
          'nama': 'BUDI SANTOSO',
          'alamat': '',
          'kpp': '',
        });

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          return partialResponse;
        });

        // Act
        final result = await platform.scanNPWP(testImage);

        // Assert
        expect(result, equals(partialResponse));
        final parsed = jsonDecode(result!);
        expect(parsed['npwp'], equals('12.345.678.9-012.345'));
        expect(parsed['nik'], equals(''));
      });

      test('validates NPWP format in response', () async {
        // Arrange
        final testImage = Uint8List.fromList([1, 2, 3]);
        final formattedNPWP = '12.345.678.9-012.345';
        final mockResponse = jsonEncode({
          'npwp': formattedNPWP,
          'nik': '3174012345678901',
          'nama': 'TEST USER',
          'alamat': 'TEST ADDRESS',
          'kpp': 'KPP TEST',
        });

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          return mockResponse;
        });

        // Act
        final result = await platform.scanNPWP(testImage);

        // Assert
        final parsed = jsonDecode(result!);
        expect(parsed['npwp'], equals(formattedNPWP));
        // Validate format: XX.XXX.XXX.X-XXX.XXX
        expect(
          parsed['npwp'],
          matches(RegExp(r'^\d{2}\.\d{3}\.\d{3}\.\d{1}-\d{3}\.\d{3}$')),
        );
      });
    });

    group('Multiple Method Calls', () {
      test('handles alternating scanKTP and scanNPWP calls', () async {
        // Arrange
        final ktpImage = Uint8List.fromList([1, 2, 3]);
        final npwpImage = Uint8List.fromList([4, 5, 6]);

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          methodCallLog.add(methodCall);
          if (methodCall.method == 'scanKTP') {
            return jsonEncode({'nik': '1234567890123456'});
          } else if (methodCall.method == 'scanNPWP') {
            return jsonEncode({'npwp': '12.345.678.9-012.345'});
          }
          return null;
        });

        // Act
        await platform.scanKTP(ktpImage);
        await platform.scanNPWP(npwpImage);
        await platform.scanKTP(ktpImage);

        // Assert
        expect(methodCallLog.length, equals(3));
        expect(methodCallLog[0].method, equals('scanKTP'));
        expect(methodCallLog[1].method, equals('scanNPWP'));
        expect(methodCallLog[2].method, equals('scanKTP'));
      });

      test('handles rapid consecutive calls', () async {
        // Arrange
        final testImage = Uint8List.fromList([1, 2, 3]);

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          methodCallLog.add(methodCall);
          return jsonEncode({'nik': '1234567890123456'});
        });

        // Act - 50 rapid calls
        for (int i = 0; i < 50; i++) {
          await platform.scanKTP(testImage);
        }

        // Assert
        expect(methodCallLog.length, equals(50));
        expect(
          methodCallLog.every((call) => call.method == 'scanKTP'),
          isTrue,
        );
      });
    });

    group('Error Handling', () {
      test('handles timeout exception', () async {
        // Arrange
        final testImage = Uint8List.fromList([1, 2, 3]);

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          throw PlatformException(
            code: 'TIMEOUT',
            message: 'Method call timed out',
          );
        });

        // Act & Assert
        expect(
          () => platform.scanKTP(testImage),
          throwsA(isA<PlatformException>()),
        );
      });

      test('handles different PlatformException codes', () async {
        // Arrange
        final testImage = Uint8List.fromList([1, 2, 3]);
        final errorCodes = [
          'NO_ACTIVITY',
          'INVALID_IMAGE',
          'OCR_FAILED',
          'PERMISSION_DENIED',
        ];

        for (final code in errorCodes) {
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
            throw PlatformException(code: code, message: 'Test error');
          });

          // Act & Assert
          try {
            await platform.scanKTP(testImage);
            fail('Should have thrown PlatformException with code: $code');
          } catch (e) {
            expect(e, isA<PlatformException>());
            expect((e as PlatformException).code, equals(code));
          }
        }
      });

      test('handles MissingPluginException', () async {
        // Arrange
        final testImage = Uint8List.fromList([1, 2, 3]);

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          throw MissingPluginException('Platform implementation not found');
        });

        // Act & Assert
        expect(
          () => platform.scanKTP(testImage),
          throwsA(isA<MissingPluginException>()),
        );
      });

      test('handles generic exceptions', () async {
        // Arrange
        final testImage = Uint8List.fromList([1, 2, 3]);

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          throw Exception('Unexpected error occurred');
        });

        // Act & Assert
        expect(
          () => platform.scanKTP(testImage),
          throwsException,
        );
      });
    });

    group('Data Integrity', () {
      test('preserves image data across channel boundary', () async {
        // Arrange
        final originalImage = Uint8List.fromList(List.generate(256, (i) => i));
        Uint8List? receivedImage;

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          receivedImage = methodCall.arguments['image'] as Uint8List;
          return '{}';
        });

        // Act
        await platform.scanKTP(originalImage);

        // Assert
        expect(receivedImage, isNotNull);
        expect(receivedImage, equals(originalImage));
        expect(receivedImage!.length, equals(256));
        for (int i = 0; i < 256; i++) {
          expect(receivedImage![i], equals(i));
        }
      });

      test('handles response with special characters', () async {
        // Arrange
        final testImage = Uint8List.fromList([1, 2, 3]);
        final responseWithSpecialChars = jsonEncode({
          'nama': "O'BRIEN & CO.",
          'alamat': 'JL. TEST "STREET" <TAG>',
        });

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          return responseWithSpecialChars;
        });

        // Act
        final result = await platform.scanKTP(testImage);

        // Assert
        expect(result, equals(responseWithSpecialChars));
        final parsed = jsonDecode(result!);
        expect(parsed['nama'], equals("O'BRIEN & CO."));
        expect(parsed['alamat'], contains('STREET'));
      });

      test('handles Unicode characters in response', () async {
        // Arrange
        final testImage = Uint8List.fromList([1, 2, 3]);
        final unicodeResponse = jsonEncode({
          'nama': 'José GARCÍA 日本',
          'alamat': 'JL. TEST ñ é ü',
        });

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          return unicodeResponse;
        });

        // Act
        final result = await platform.scanKTP(testImage);

        // Assert
        expect(result, equals(unicodeResponse));
        final parsed = jsonDecode(result!);
        expect(parsed['nama'], contains('José'));
        expect(parsed['alamat'], contains('ñ'));
      });
    });
  });
}
