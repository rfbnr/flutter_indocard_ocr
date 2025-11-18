import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_indocard_ocr/flutter_indocard_ocr.dart';
import 'package:flutter_indocard_ocr/platform_interface/flutter_indocard_ocr_platform_interface.dart';
import 'package:flutter_indocard_ocr/method_channel/method_channel_flutter_indocard_ocr.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterIndocardOcrPlatform
    with MockPlatformInterfaceMixin
    implements FlutterIndocardOcrPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<String?> scanKTP(Uint8List image) {
    // TODO: implement scanKTP
    throw UnimplementedError();
  }

  @override
  Future<String?> scanNPWP(Uint8List image) {
    // TODO: implement scanNPWP
    throw UnimplementedError();
  }
}

void main() {
  final FlutterIndocardOcrPlatform initialPlatform =
      FlutterIndocardOcrPlatform.instance;

  test('$MethodChannelFlutterIndocardOcr is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlutterIndocardOcr>());
  });

  test('getPlatformVersion', () async {
    FlutterIndocardOCR flutterIndocardOcrPlugin = FlutterIndocardOCR();
    MockFlutterIndocardOcrPlatform fakePlatform =
        MockFlutterIndocardOcrPlatform();
    FlutterIndocardOcrPlatform.instance = fakePlatform;

    expect(await flutterIndocardOcrPlugin.getPlatformVersion(), '42');
  });
}
