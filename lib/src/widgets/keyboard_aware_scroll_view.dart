import 'package:flutter/widgets.dart';

import '../provider/keyboard_animation.dart';
import '../provider/keyboard_provider.dart';
import '../models/keyboard_event_data.dart';

/// A [ScrollView] that automatically scrolls to keep the focused text input
/// visible when the keyboard appears.
///
/// Mirrors `KeyboardAwareScrollView` from react-native-keyboard-controller.
///
/// ```dart
/// KeyboardAwareScrollView(
///   children: [
///     TextField(decoration: InputDecoration(labelText: 'Name')),
///     TextField(decoration: InputDecoration(labelText: 'Email')),
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
  final EdgeInsetsGeometry? padding;

  /// Extra space between the focused input and the keyboard edge.
  final EdgeInsets scrollPadding;

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
  double _lastKeyboardHeight = 0;

  // Cached to avoid context lookup in dispose() / listeners.
  KeyboardAnimation? _animation;

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
    final next = KeyboardControllerScope.maybeOf(context);
    if (next != _animation) {
      _animation?.lastEventNotifier.removeListener(_onAnimationEvent);
      _animation = next;
      _animation?.lastEventNotifier.addListener(_onAnimationEvent);
    }
  }

  void _onAnimationEvent() {
    final event = _animation?.lastEvent;
    if (event == null) return;

    if (event.type == KeyboardEventType.willShow ||
        event.type == KeyboardEventType.didShow) {
      if (event.height != _lastKeyboardHeight) {
        _lastKeyboardHeight = event.height;
        _scrollToFocusedInput();
      }
    } else if (event.type == KeyboardEventType.didHide) {
      _lastKeyboardHeight = 0;
    }
  }

  Future<void> _scrollToFocusedInput() async {
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;

    final focused = FocusManager.instance.primaryFocus;
    if (focused == null) return;

    final renderObj = focused.context?.findRenderObject();
    if (renderObj is! RenderBox) return;

    final inputTopLeft = renderObj.localToGlobal(Offset.zero);
    final inputBottom = inputTopLeft.dy + renderObj.size.height;

    final screenHeight = MediaQuery.sizeOf(context).height;
    final visibleBottom = screenHeight - _lastKeyboardHeight;

    if (inputBottom > visibleBottom - widget.scrollPadding.bottom) {
      final scrollAmount =
          inputBottom - visibleBottom + widget.scrollPadding.bottom;
      final target = (_scrollController.offset + scrollAmount)
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
    // Fallback for when no KeyboardProvider is present.
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final newHeight = view.viewInsets.bottom / view.devicePixelRatio;
    if (newHeight != _lastKeyboardHeight && newHeight > 0) {
      _lastKeyboardHeight = newHeight;
      _scrollToFocusedInput();
    }
  }

  @override
  void dispose() {
    // Use the cached reference — never touch context here.
    _animation?.lastEventNotifier.removeListener(_onAnimationEvent);
    WidgetsBinding.instance.removeObserver(this);
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
