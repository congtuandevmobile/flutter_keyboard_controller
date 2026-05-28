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
    // WidgetsBindingObserver only kept as fallback — see didChangeMetrics.
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

  // ── Primary path: native keyboard events ─────────────────────────────────

  void _onAnimationEvent() {
    final event = _animation?.lastEvent;
    if (event == null) return;

    switch (event.type) {
      case KeyboardEventType.didShow:
        // Keyboard fully visible — scroll once to bring field into view.
        if (event.height != _lastKeyboardHeight) {
          _lastKeyboardHeight = event.height;
          _scrollToFocusedInput();
        }

      case KeyboardEventType.didHide:
        _lastKeyboardHeight = 0;
        // After keyboard hides the viewport may have grown and the current
        // scroll offset might now exceed maxScrollExtent. Fix it so the
        // user doesn't see an unexpected animated snap-back from the physics.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !_scrollController.hasClients) return;
          final pos = _scrollController.position;
          if (pos.pixels > pos.maxScrollExtent) {
            _scrollController.animateTo(
              pos.maxScrollExtent,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          }
        });

      default:
        break;
    }
  }

  Future<void> _scrollToFocusedInput() async {
    // Yield one frame so layout has settled with the new keyboard height.
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;

    final focused = FocusManager.instance.primaryFocus;
    if (focused == null) return;

    final renderObj = focused.context?.findRenderObject();
    if (renderObj is! RenderBox) return;

    final inputBottom =
        renderObj.localToGlobal(Offset.zero).dy + renderObj.size.height;

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

  // ── Fallback: no KeyboardProvider in tree ─────────────────────────────────
  // Only used when KeyboardProvider is absent. When present, _onAnimationEvent
  // handles scrolling and didChangeMetrics is a no-op.

  @override
  void didChangeMetrics() {
    if (_animation != null) return; // native events take priority
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final newHeight = view.viewInsets.bottom / view.devicePixelRatio;
    if (newHeight > 0 && newHeight != _lastKeyboardHeight) {
      _lastKeyboardHeight = newHeight;
      _scrollToFocusedInput();
    }
  }

  @override
  void dispose() {
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
