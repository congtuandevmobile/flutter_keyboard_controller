import 'package:flutter/widgets.dart';
import '../provider/keyboard_animation.dart';
import '../provider/keyboard_provider.dart';
import '../models/keyboard_event_data.dart';

/// Controls how [KeyboardChatScrollView] lifts content when the keyboard appears.
///
/// Mirrors `keyboardLiftBehavior` from react-native-keyboard-controller.
enum KeyboardLiftBehavior {
  /// Content always lifts with keyboard — message list scrolls up.
  /// Matches Telegram.
  always,

  /// Content lifts only when the user is at the bottom of the list.
  /// Matches ChatGPT / most messenger apps.
  whenAtEnd,

  /// Content lifts on show, stays lifted even after keyboard hides.
  /// Matches Claude.ai.
  persistent,

  /// Keyboard never lifts content automatically.
  /// Matches Perplexity.
  never,
}

/// A [ScrollView] optimised for chat/messaging UIs that keeps new messages
/// visible as the keyboard appears and the user types.
///
/// Mirrors `KeyboardChatScrollView` from react-native-keyboard-controller.
///
/// ```dart
/// KeyboardChatScrollView(
///   liftBehavior: KeyboardLiftBehavior.whenAtEnd,
///   children: messages.map((m) => MessageBubble(m)).toList(),
/// )
/// ```
class KeyboardChatScrollView extends StatefulWidget {
  const KeyboardChatScrollView({
    super.key,
    required this.children,
    this.liftBehavior = KeyboardLiftBehavior.whenAtEnd,
    this.controller,
    this.physics,
    this.padding,
    this.extraBottomPadding = 0,
    this.onEndVisible,
    this.clipBehavior = Clip.hardEdge,
  });

  final List<Widget> children;
  final KeyboardLiftBehavior liftBehavior;
  final ScrollController? controller;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry? padding;
  final double extraBottomPadding;
  final VoidCallback? onEndVisible;
  final Clip clipBehavior;

  @override
  State<KeyboardChatScrollView> createState() =>
      _KeyboardChatScrollViewState();
}

class _KeyboardChatScrollViewState extends State<KeyboardChatScrollView> {
  late final ScrollController _controller;
  bool _ownsController = false;
  double _lastKeyboardHeight = 0;
  bool _wasAtEnd = true;
  bool _persistentlyLifted = false;

  // Cached to avoid context lookup in dispose() / listeners.
  KeyboardAnimation? _animation;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = ScrollController();
      _ownsController = true;
    }
    _controller.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = KeyboardControllerScope.maybeOf(context);
    if (next != _animation) {
      _animation?.lastEventNotifier.removeListener(_onKeyboardEvent);
      _animation = next;
      _animation?.lastEventNotifier.addListener(_onKeyboardEvent);
    }
  }

  void _onScroll() {
    if (!_controller.hasClients) return;
    final atEnd = _controller.position.pixels >=
        _controller.position.maxScrollExtent - 8;
    if (atEnd != _wasAtEnd) {
      _wasAtEnd = atEnd;
      if (atEnd) widget.onEndVisible?.call();
    }
  }

  void _onKeyboardEvent() {
    // Use cached _animation — safe to call from any context.
    final event = _animation?.lastEvent;
    if (event == null) return;

    switch (event.type) {
      case KeyboardEventType.willShow:
      case KeyboardEventType.didShow:
        _handleKeyboardShow(event.height);
      case KeyboardEventType.didHide:
        _lastKeyboardHeight = 0;
      case KeyboardEventType.move:
        _handleKeyboardMove(event.height);
      default:
        break;
    }
  }

  void _handleKeyboardShow(double newHeight) {
    final delta = newHeight - _lastKeyboardHeight;
    _lastKeyboardHeight = newHeight;
    if (delta <= 0 || !_controller.hasClients) return;

    if (_shouldLift()) {
      if (widget.liftBehavior == KeyboardLiftBehavior.persistent) {
        _persistentlyLifted = true;
      }
      final target =
          (_controller.offset + delta).clamp(0.0, double.infinity);
      _controller.animateTo(
        target,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  void _handleKeyboardMove(double newHeight) {
    final delta = newHeight - _lastKeyboardHeight;
    _lastKeyboardHeight = newHeight;
    if (delta == 0 || !_controller.hasClients) return;

    if (_shouldLift()) {
      final target =
          (_controller.offset + delta).clamp(0.0, double.infinity);
      _controller.jumpTo(target);
    }
  }

  bool _shouldLift() {
    switch (widget.liftBehavior) {
      case KeyboardLiftBehavior.always:
        return true;
      case KeyboardLiftBehavior.whenAtEnd:
        return _wasAtEnd;
      case KeyboardLiftBehavior.persistent:
        return _wasAtEnd || _persistentlyLifted;
      case KeyboardLiftBehavior.never:
        return false;
    }
  }

  @override
  void dispose() {
    // Use the cached reference — never touch context here.
    _animation?.lastEventNotifier.removeListener(_onKeyboardEvent);
    _controller.removeListener(_onScroll);
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: _controller,
      reverse: true,
      physics: widget.physics,
      clipBehavior: widget.clipBehavior,
      padding: widget.padding != null
          ? widget.padding!
              .add(EdgeInsets.only(bottom: widget.extraBottomPadding))
          : EdgeInsets.only(bottom: widget.extraBottomPadding),
      children: widget.children,
    );
  }
}
