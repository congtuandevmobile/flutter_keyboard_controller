import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_keyboard_controller_platform_interface.dart';

/// An implementation of [FlutterKeyboardControllerPlatform] that uses method channels.
class MethodChannelFlutterKeyboardController extends FlutterKeyboardControllerPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_keyboard_controller');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }
}
