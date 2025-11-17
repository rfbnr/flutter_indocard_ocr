import 'dart:typed_data';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_indocard_ocr_method_channel.dart';

abstract class FlutterIndocardOcrPlatform extends PlatformInterface {
  /// Constructs a FlutterIndocardOcrPlatform.
  FlutterIndocardOcrPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterIndocardOcrPlatform _instance =
      MethodChannelFlutterIndocardOcr();

  /// The default instance of [FlutterIndocardOcrPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterIndocardOcr].
  static FlutterIndocardOcrPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterIndocardOcrPlatform] when
  /// they register themselves.
  static set instance(FlutterIndocardOcrPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<String?> scanKTP(Uint8List image) {
    throw UnimplementedError('scanKTP() has not been implemented.');
  }

  Future<String?> scanNPWP(Uint8List image) {
    throw UnimplementedError('scanNPWP() has not been implemented.');
  }
}
