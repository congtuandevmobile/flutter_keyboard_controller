import 'package:flutter/foundation.dart';
import '../models/keyboard_event_data.dart';

/// Holds the live keyboard animation state and exposes fine-grained
/// [ValueNotifier]s so individual widgets can subscribe without rebuilding
/// the entire subtree.
///
/// Mirrors the `animated` / `reanimated` shared-value objects from
/// react-native-keyboard-controller.
///
/// Typical usage through [KeyboardControllerScope]:
/// ```dart
/// final animation = KeyboardControllerScope.of(context);
///
/// // Rebuild only this widget when height changes
/// ValueListenableBuilder<double>(
///   valueListenable: animation.heightNotifier,
///   builder: (_, height, __) => SizedBox(height: height),
/// );
/// ```
class KeyboardAnimation extends ChangeNotifier {
  // ── Raw notifiers (efficient, per-field subscriptions) ──────────────────

  /// Current keyboard height in logical pixels.
  /// 0.0 when hidden, positive when visible.
  final ValueNotifier<double> heightNotifier = ValueNotifier(0.0);

  /// Animation progress in [0.0, 1.0].
  final ValueNotifier<double> progressNotifier = ValueNotifier(0.0);

  /// Whether the keyboard is currently visible.
  final ValueNotifier<bool> isVisibleNotifier = ValueNotifier(false);

  /// The last keyboard event received (null before first event).
  final ValueNotifier<KeyboardEventData?> lastEventNotifier =
      ValueNotifier(null);

  // ── Convenience getters ──────────────────────────────────────────────────

  double get height => heightNotifier.value;
  double get progress => progressNotifier.value;
  bool get isVisible => isVisibleNotifier.value;
  KeyboardEventData? get lastEvent => lastEventNotifier.value;

  // ── Internal update ──────────────────────────────────────────────────────

  void handleEvent(KeyboardEventData event) {
    heightNotifier.value = event.height;
    progressNotifier.value = event.progress;
    isVisibleNotifier.value = event.isVisible;
    lastEventNotifier.value = event;
    notifyListeners();
  }

  @override
  void dispose() {
    heightNotifier.dispose();
    progressNotifier.dispose();
    isVisibleNotifier.dispose();
    lastEventNotifier.dispose();
    super.dispose();
  }
}
