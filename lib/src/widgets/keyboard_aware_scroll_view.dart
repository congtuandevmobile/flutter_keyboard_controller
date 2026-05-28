import 'dart:async';

import 'package:flutter/widgets.dart';

import '../provider/keyboard_provider.dart';
import '../models/keyboard_event_data.dart';

/// A [ScrollView] that automatically scrolls to keep the focused text input
/// visible when the keyboard appears.
///
/// Mirrors `KeyboardAwareScrollView` from react-native-keyboard-controller.
///
/// **Key features:**
/// - Tracks focused input position and keyboard height
/// - Smooth animated scroll on keyboard show
/// - Respects `scrollPadding` like Flutter's default `TextField`
/// - Works with any scroll direction
///
/// ```dart
/// KeyboardAwareScrollView(
///   children: [
///     TextField(decoration: InputDecoration(labelText: 'Name')),
///     TextField(decoration: InputDecoration(labelText: 'Email')),
///     TextField(decoration: InputDecoration(labelText: 'Message')),
///   ],
/// );
/// ```
class KeyboardAwareScrollView extends StatefulWidget {
  const KeyboardAwareScrollView({
    super.key,
    required this.children,
    this.scrollController,
    this.padding,
    this.scrollPadding = const EdgeInsets.all(20.0),
    this.animationDuration = const Duration(milliseconds: 300),
    this.animationCurve = Curves.easeOut,
    this.physics,
    this.reverse = false,
    this.primary,
    this.shrinkWrap = false,
    this.clipBehavior = Clip.hardEdge,
  });

  final List<Widget> children;
  final ScrollController? scrollController;

  /// Padding around the scroll content.
  final EdgeInsetsGeometry? padding;

  /// Extra space between the focused input and the keyboard edge.
  final EdgeInsets scrollPadding;

  /// Duration of the scroll animation when the keyboard appears.
  final Duration animationDuration;
  final Curve animationCurve;

  final ScrollPhysics? physics;
  final bool reverse;
  final bool? primary;
  final bool shrinkWrap;
  final Clip clipBehavior;

  @override
  State<KeyboardAwareScrollView> createState() =>
      _KeyboardAwareScrollViewState();
}

class _KeyboardAwareScrollViewState extends State<KeyboardAwareScrollView>
    with WidgetsBindingObserver {
  late final ScrollController _scrollController;
  bool _ownsController = false;

  // The last reported keyboard height.
  double _lastKeyboardHeight = 0;
  StreamSubscription<dynamic>? _animSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.scrollController != null) {
      _scrollController = widget.scrollController!;
    } else {
      _scrollController = ScrollController();
      _ownsController = true;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animation = KeyboardControllerScope.maybeOf(context);
    if (animation != null) {
      animation.lastEventNotifier.addListener(_onAnimationEvent);
    }
  }

  void _onAnimationEvent() {
    final animation = KeyboardControllerScope.maybeOf(context);
    final event = animation?.lastEvent;
    if (event == null) return;

    if (event.type == KeyboardEventType.willShow ||
        event.type == KeyboardEventType.didShow) {
      final newHeight = event.height;
      if (newHeight != _lastKeyboardHeight) {
        _lastKeyboardHeight = newHeight;
        _scrollToFocusedInput();
      }
    } else if (event.type == KeyboardEventType.didHide) {
      _lastKeyboardHeight = 0;
    }
  }

  Future<void> _scrollToFocusedInput() async {
    // Give the layout a frame to settle before measuring
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;

    final focused = FocusManager.instance.primaryFocus;
    if (focused == null) return;

    final renderObj = focused.context?.findRenderObject();
    if (renderObj is! RenderBox) return;

    // Get the input's absolute position
    final inputBox = renderObj;
    final inputTopLeft = inputBox.localToGlobal(Offset.zero);
    final inputBottom = inputTopLeft.dy + inputBox.size.height;

    // Viewport height minus the keyboard
    final screenHeight = MediaQuery.sizeOf(context).height;
    final visibleBottom = screenHeight - _lastKeyboardHeight;

    if (inputBottom > visibleBottom - widget.scrollPadding.bottom) {
      final scrollAmount =
          inputBottom - visibleBottom + widget.scrollPadding.bottom;
      final target =
          (_scrollController.offset + scrollAmount)
              .clamp(0.0, _scrollController.position.maxScrollExtent);

      _scrollController.animateTo(
        target,
        duration: widget.animationDuration,
        curve: widget.animationCurve,
      );
    }
  }

  @override
  void didChangeMetrics() {
    // Fallback: also respond to MediaQuery keyboard height changes
    final newHeight =
        WidgetsBinding.instance.platformDispatcher.views.first.viewInsets.bottom /
            WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;

    if (newHeight != _lastKeyboardHeight && newHeight > 0) {
      _lastKeyboardHeight = newHeight;
      _scrollToFocusedInput();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final animation = KeyboardControllerScope.maybeOf(context);
    animation?.lastEventNotifier.removeListener(_onAnimationEvent);
    _animSub?.cancel();
    if (_ownsController) _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: widget.padding,
      physics: widget.physics,
      reverse: widget.reverse,
      primary: widget.primary,
      clipBehavior: widget.clipBehavior,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: widget.children,
      ),
    );
  }
}
