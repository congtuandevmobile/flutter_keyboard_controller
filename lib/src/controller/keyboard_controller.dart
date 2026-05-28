import 'package:flutter/services.dart';
import '../models/keyboard_state.dart';

/// Imperative API for controlling the keyboard.
/// Mirrors KeyboardController module from react-native-keyboard-controller.
///
/// Usage:
/// ```dart
/// // Dismiss keyboard
/// await KeyboardController.dismiss();
///
/// // Check state
/// final state = await KeyboardController.state();
/// print(state.height);
/// ```
class KeyboardController {
  KeyboardController._();

  static const _channel =
      MethodChannel('flutter_keyboard_controller');

  /// Dismisses the on-screen keyboard.
  ///
  /// [keepFocus] — if true the focused input keeps focus (cursor stays) after dismissal.
  /// [animated] — if false the keyboard hides without animation (iOS only).
  static Future<void> dismiss({
    bool keepFocus = false,
    bool animated = true,
  }) async {
    await _channel.invokeMethod<void>('dismiss', {
      'keepFocus': keepFocus,
      'animated': animated,
    });
  }

  /// Returns whether the keyboard is currently visible.
  static Future<bool> isVisible() async {
    final result = await _channel.invokeMethod<bool>('isVisible');
    return result ?? false;
  }

  /// Returns a snapshot of the current keyboard state.
  static Future<KeyboardState> state() async {
    final result =
        await _channel.invokeMethod<Map<dynamic, dynamic>>('state');
    if (result == null) return const KeyboardState.hidden();
    return KeyboardState.fromMap(result);
  }

  // ── Android-only ──────────────────────────────────────────────────────────

  /// Sets Android soft-input mode.
  ///
  /// Call this to switch between ADJUST_RESIZE, ADJUST_PAN, ADJUST_NOTHING.
  /// Has no effect on iOS.
  static Future<void> setInputMode(AndroidSoftInputMode mode) async {
    await _channel.invokeMethod<void>('setInputMode', {'mode': mode.value});
  }

  /// Restores Android soft-input mode to the app default.
  static Future<void> setDefaultMode() async {
    await _channel.invokeMethod<void>('setDefaultMode');
  }

  // ── iOS-only ──────────────────────────────────────────────────────────────

  /// Preloads the keyboard to reduce first-appearance latency.
  /// No-op on Android.
  static Future<void> preload() async {
    await _channel.invokeMethod<void>('preload');
  }

  /// Moves focus to the next focusable input (i.e. toolbar "Next" button).
  /// No-op if there is no next field.
  static Future<void> focusNext() async {
    await _channel.invokeMethod<void>('focusNext');
  }

  /// Moves focus to the previous focusable input.
  static Future<void> focusPrev() async {
    await _channel.invokeMethod<void>('focusPrev');
  }
}
