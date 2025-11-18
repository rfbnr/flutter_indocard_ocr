import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../platform_interface/flutter_indocard_ocr_platform_interface.dart';

/// An implementation of [FlutterIndocardOcrPlatform] that uses method channels.
class MethodChannelFlutterIndocardOcr extends FlutterIndocardOcrPlatform {
  static const String channelName = 'flutter_indocard_ocr';

  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel(channelName);

  @override
  Future<String?> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<String?> scanKTP(Uint8List image) async {
    final jsonString = await methodChannel.invokeMethod<String>('scanKTP', {
      'image': image,
    });
    return jsonString;
  }

  @override
  Future<String?> scanNPWP(Uint8List image) async {
    final jsonString = await methodChannel.invokeMethod<String>('scanNPWP', {
      'image': image,
    });
    return jsonString;
  }
}
