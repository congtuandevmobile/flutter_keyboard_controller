import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_keyboard_controller_method_channel.dart';

abstract class FlutterKeyboardControllerPlatform extends PlatformInterface {
  /// Constructs a FlutterKeyboardControllerPlatform.
  FlutterKeyboardControllerPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterKeyboardControllerPlatform _instance = MethodChannelFlutterKeyboardController();

  /// The default instance of [FlutterKeyboardControllerPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterKeyboardController].
  static FlutterKeyboardControllerPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterKeyboardControllerPlatform] when
  /// they register themselves.
  static set instance(FlutterKeyboardControllerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
