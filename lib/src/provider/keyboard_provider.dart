import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../controller/keyboard_controller.dart';
import '../models/keyboard_event_data.dart';
import 'keyboard_animation.dart';

enum KeyboardDismissBehavior {
  /// Keyboard is never dismissed automatically.
  manual,

  /// Keyboard dismisses when the user taps anywhere outside a focused input.
  onTap,

  /// Keyboard dismisses when the user starts scrolling inside a [ScrollView].
  onDrag,

  /// Keyboard dismisses on both tap-outside and scroll.
  onTapAndDrag,
}

/// Root widget that initialises keyboard tracking.
/// Wrap your app (or at least the portion that needs keyboard awareness)
/// with this widget — exactly as you wrap with `KeyboardProvider` in
/// react-native-keyboard-controller.
///
/// ```dart
/// void main() {
///   runApp(
///     KeyboardProvider(
///       dismissBehavior: KeyboardDismissBehavior.onTapAndDrag,
///       child: MaterialApp(home: MyHome()),
///     ),
///   );
/// }
/// ```
class KeyboardProvider extends StatefulWidget {
  const KeyboardProvider({
    super.key,
    required this.child,

    /// Set to false to temporarily disable keyboard tracking without
    /// removing the provider from the tree.
    this.enabled = true,

    /// Controls when the keyboard is automatically dismissed.
    /// Defaults to [KeyboardDismissBehavior.manual] (never auto-dismissed).
    this.dismissBehavior = KeyboardDismissBehavior.manual,
  });

  final Widget child;
  final bool enabled;
  final KeyboardDismissBehavior dismissBehavior;

  @override
  State<KeyboardProvider> createState() => _KeyboardProviderState();
}

class _KeyboardProviderState extends State<KeyboardProvider> {
  late final KeyboardAnimation _animation;
  StreamSubscription<dynamic>? _eventSub;

  static const _eventChannel =
      EventChannel('flutter_keyboard_controller/keyboard_events');

  @override
  void initState() {
    super.initState();
    _animation = KeyboardAnimation();
    if (widget.enabled) {
      _startListening();
    }
  }

  @override
  void didUpdateWidget(KeyboardProvider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled != oldWidget.enabled) {
      if (widget.enabled) {
        _startListening();
      } else {
        _stopListening();
      }
    }
  }

  void _startListening() {
    _eventSub?.cancel();
    _eventSub = _eventChannel.receiveBroadcastStream().listen(
      (dynamic raw) {
        if (raw is Map) {
          final event = KeyboardEventData.fromMap(raw);
          _animation.handleEvent(event);
        }
      },
      onError: (_) {}, // channel not available on web/desktop
    );
  }

  void _stopListening() {
    _eventSub?.cancel();
    _eventSub = null;
  }

  @override
  void dispose() {
    _stopListening();
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget child = KeyboardControllerScope(
      animation: _animation,
      child: widget.child,
    );

    if (widget.dismissBehavior == KeyboardDismissBehavior.onDrag ||
        widget.dismissBehavior == KeyboardDismissBehavior.onTapAndDrag) {
      child = NotificationListener<ScrollStartNotification>(
        onNotification: (n) {
          if (n.dragDetails != null) KeyboardController.dismiss();
          return false;
        },
        child: child,
      );
    }

    if (widget.dismissBehavior == KeyboardDismissBehavior.onTap ||
        widget.dismissBehavior == KeyboardDismissBehavior.onTapAndDrag) {
      child = GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => KeyboardController.dismiss(),
        child: child,
      );
    }

    return child;
  }
}

/// [InheritedNotifier] that exposes [KeyboardAnimation] to all descendants.
/// Use [KeyboardControllerScope.of] to read keyboard state or subscribe to
/// changes.
///
/// ```dart
/// // Cheap read — widget does NOT rebuild on keyboard change
/// final animation = KeyboardControllerScope.maybeOf(context);
///
/// // Subscribing — widget rebuilds on every keyboard event
/// final animation = KeyboardControllerScope.of(context);
/// ```
class KeyboardControllerScope extends InheritedNotifier<KeyboardAnimation> {
  const KeyboardControllerScope({
    super.key,
    required KeyboardAnimation animation,
    required super.child,
  }) : super(notifier: animation);

  /// Returns the nearest [KeyboardAnimation], subscribing to changes.
  /// Throws if no [KeyboardProvider] is in the tree.
  static KeyboardAnimation of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<KeyboardControllerScope>();
    assert(
      scope != null,
      'No KeyboardProvider found in the widget tree. '
      'Wrap your app with KeyboardProvider.',
    );
    return scope!.notifier!;
  }

  /// Returns the nearest [KeyboardAnimation] or null — does NOT subscribe.
  static KeyboardAnimation? maybeOf(BuildContext context) {
    return context
        .getInheritedWidgetOfExactType<KeyboardControllerScope>()
        ?.notifier;
  }

  @override
  bool updateShouldNotify(KeyboardControllerScope oldWidget) =>
      notifier != oldWidget.notifier;
}

/// Convenience extension for reading keyboard animation from a [BuildContext].
extension KeyboardControllerContext on BuildContext {
  /// Reads [KeyboardAnimation] and subscribes this widget to changes.
  KeyboardAnimation get keyboard => KeyboardControllerScope.of(this);

  /// Reads [KeyboardAnimation] without subscribing (no rebuilds).
  KeyboardAnimation? get keyboardOrNull =>
      KeyboardControllerScope.maybeOf(this);
}
