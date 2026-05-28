import 'package:flutter/widgets.dart';
import '../provider/keyboard_animation.dart';
import '../provider/keyboard_provider.dart';

/// Controls how [KeyboardChatScrollView] lifts content when the keyboard appears.
enum KeyboardLiftBehavior {
  /// Content always lifts with keyboard. Matches Telegram.
  always,

  /// Content lifts only when the user is at the bottom of the list.
  /// Matches ChatGPT / most messenger apps.
  whenAtEnd,

  /// Content lifts on show, stays lifted even after keyboard hides.
  /// Matches Claude.ai.
  persistent,

  /// Keyboard never lifts content automatically. Matches Perplexity.
  never,
}

/// A [ScrollView] optimised for chat/messaging UIs.
///
/// **Requires Stack layout** — place inside a [Stack] with a floating input
/// bar driven by the plugin's keyboard height. The viewport must NOT shrink
/// when the keyboard opens (i.e. [Scaffold.resizeToAvoidBottomInset] = false).
///
/// Lifting is done purely via [ListView.padding] changes (matching
/// react-native-keyboard-controller's contentInset approach). No manual
/// `jumpTo` is needed for the basic open/close animation — the padding delta
/// handles it.  `persistent` is the only mode that keeps extra padding after
/// the keyboard closes.
class KeyboardChatScrollView extends StatefulWidget {
  const KeyboardChatScrollView({
    super.key,
    required this.children,
    this.liftBehavior = KeyboardLiftBehavior.whenAtEnd,
    this.controller,
    this.physics,
    this.padding,
    this.extraBottomPadding = 0,
    this.safeAreaBottom = 0,
    this.onEndVisible,
    this.clipBehavior = Clip.hardEdge,
  });

  final List<Widget> children;
  final KeyboardLiftBehavior liftBehavior;
  final ScrollController? controller;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry? padding;

  /// Fixed space reserved at the bottom (e.g. the floating input bar height,
  /// excluding any safe-area inset — pass that via [safeAreaBottom]).
  final double extraBottomPadding;

  /// Device safe-area bottom inset (e.g. home-indicator height on iOS).
  /// Passed separately so the widget can smoothly correct for the fact that
  /// SafeArea inside the input bar shrinks to 0 as the keyboard opens.
  /// Typical value: MediaQuery.of(context).viewPadding.bottom.
  final double safeAreaBottom;

  final VoidCallback? onEndVisible;
  final Clip clipBehavior;

  @override
  State<KeyboardChatScrollView> createState() =>
      _KeyboardChatScrollViewState();
}

class _KeyboardChatScrollViewState extends State<KeyboardChatScrollView> {
  late final ScrollController _controller;
  bool _ownsController = false;

  // In reverse:true, pixels=0 means at visual BOTTOM (newest messages).
  bool _wasAtEnd = true;

  // For persistent mode: remembers the last keyboard height so padding
  // stays elevated after the keyboard closes.
  double _persistentPadding = 0;

  // Fallback when no KeyboardProvider is in the tree.
  static final _zeroNotifier = ValueNotifier(0.0);
  KeyboardAnimation? _animation;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? ScrollController();
    _ownsController = widget.controller == null;
    _controller.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = KeyboardControllerScope.maybeOf(context);
    if (next != _animation) {
      _animation?.heightNotifier.removeListener(_onKeyboardHeightChange);
      _animation = next;
      _animation?.heightNotifier.addListener(_onKeyboardHeightChange);
    }
  }

  void _onScroll() {
    if (!_controller.hasClients) return;
    // In reverse:true, pixels=0 means at the visual BOTTOM (newest messages).
    final atEnd = _controller.position.pixels <= 20.0;
    if (atEnd != _wasAtEnd) {
      _wasAtEnd = atEnd;
      if (atEnd) widget.onEndVisible?.call();
    }
  }

  void _onKeyboardHeightChange() {
    final newH = _animation?.height ?? 0.0;

    // persistent: record keyboard height unconditionally while open.
    // RN: shouldShiftContent("persistent") = true always, so the shift is
    // always applied and must be persisted regardless of scroll position.
    if (widget.liftBehavior == KeyboardLiftBehavior.persistent && newH > 0) {
      _persistentPadding = newH;
    }
  }

  /// Extra lift padding on top of [extraBottomPadding], mirroring RN's
  /// `padding` (contentInset) value per behavior:
  ///
  /// - always    → always equals keyboard height
  /// - whenAtEnd → equals keyboard height only when at the bottom
  /// - persistent→ equals keyboard height while open; keeps last value after close
  /// - never     → always 0
  double _liftPaddingFor(double keyboardH) {
    switch (widget.liftBehavior) {
      case KeyboardLiftBehavior.always:
        return keyboardH;
      case KeyboardLiftBehavior.whenAtEnd:
        return _wasAtEnd ? keyboardH : 0;
      case KeyboardLiftBehavior.persistent:
        // RN: shouldShiftContent("persistent") = true → always lift while open.
        // After keyboard closes (keyboardH == 0): keep _persistentPadding so
        // content stays visually elevated — the "persistent" behaviour.
        return keyboardH > 0 ? keyboardH : _persistentPadding;
      case KeyboardLiftBehavior.never:
        return 0;
    }
  }

  @override
  void dispose() {
    _animation?.heightNotifier.removeListener(_onKeyboardHeightChange);
    _controller.removeListener(_onScroll);
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: _animation?.heightNotifier ?? _zeroNotifier,
      builder: (context, keyboardH, _) {
        // SafeArea inside the floating InputBar shrinks from safeAreaBottom → 0
        // as the keyboard opens. Mirror that here so the gap between the newest
        // message and the InputBar stays constant regardless of keyboard state.
        final safeAreaNow =
            (widget.safeAreaBottom - keyboardH).clamp(0.0, widget.safeAreaBottom);

        final basePadding = widget.padding ?? EdgeInsets.zero;
        return ListView(
          controller: _controller,
          reverse: true,
          physics: widget.physics,
          clipBehavior: widget.clipBehavior,
          padding: basePadding.add(
            EdgeInsets.only(
              bottom: widget.extraBottomPadding +
                  safeAreaNow +
                  _liftPaddingFor(keyboardH),
            ),
          ),
          children: widget.children,
        );
      },
    );
  }
}
