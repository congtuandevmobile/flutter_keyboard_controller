import 'package:flutter/widgets.dart';

import '../provider/keyboard_animation.dart';
import '../provider/keyboard_provider.dart';
import '../models/keyboard_event_data.dart';
import '../services/keyboard_geometry_service.dart';
import 'keyboard_toolbar.dart' show KeyboardToolbarInset;

/// Marks the outermost boundary of a custom input widget so that
/// [KeyboardAwareScrollView] can measure the full height (including labels
/// and error messages below the text field) when scrolling to keep the
/// focused input visible.
///
/// Wrap the root widget of your custom input widget with this once:
///
/// ```dart
/// // Inside AppTextInput.build()
/// return KeyboardScrollBoundary(
///   child: Column(children: [label, textField, errorText]),
/// );
/// ```
///
/// [KeyboardAwareScrollView] will automatically find this boundary when
/// traversing ancestors and use it as the scroll target — no per-screen
/// configuration required.
class KeyboardScrollBoundary extends StatelessWidget {
  const KeyboardScrollBoundary({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

/// A [ScrollView] that automatically scrolls to keep the focused text input
/// visible when the keyboard appears.
///
/// Works correctly with plain [TextField], reactive_forms, and custom input
/// wrappers (e.g. AppTextInput that includes a label + error message below
/// the actual input box).
///
/// ```dart
/// Scaffold(
///   resizeToAvoidBottomInset: false,
///   body: KeyboardAwareScrollView(
///     children: [
///       TextField(decoration: InputDecoration(labelText: 'Name')),
///       TextField(decoration: InputDecoration(labelText: 'Email')),
///     ],
///   ),
/// )
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
    this.scrollContextFinder,
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

  /// Optional hook to override the default ancestor traversal.
  ///
  /// Use when your app has custom input wrappers (AppTextInput, AppPhoneInput…)
  /// that include labels / error messages outside the focused [TextField].
  /// Return the [BuildContext] of the outermost wrapper so the scroll target
  /// includes the full widget height (label + input + error text).
  /// Return null to fall back to built-in traversal.
  ///
  /// Example:
  /// ```dart
  /// scrollContextFinder: (focused) {
  ///   BuildContext? result;
  ///   focused.context?.visitAncestorElements((el) {
  ///     if (el.widget.runtimeType.toString().startsWith('AppTextInput')) {
  ///       result = el;
  ///       return false;
  ///     }
  ///     return true;
  ///   });
  ///   return result;
  /// },
  /// ```
  final BuildContext? Function(FocusNode focused)? scrollContextFinder;

  @override
  State<KeyboardAwareScrollView> createState() =>
      _KeyboardAwareScrollViewState();
}

class _KeyboardAwareScrollViewState extends State<KeyboardAwareScrollView>
    with WidgetsBindingObserver {
  late final ScrollController _scrollController;
  bool _ownsController = false;
  double _lastKeyboardHeight = 0;
  int _scrollGeneration = 0;

  // Drives bottom padding per-frame via ValueListenableBuilder.
  // Only SingleChildScrollView rebuilds each frame — Column/children do not.
  final ValueNotifier<double> _paddingNotifier = ValueNotifier(0.0);

  // Plain bool — used only to suppress _onFocusChanged scroll during dismiss.
  // NOT a ValueNotifier: no physics switching needed. Letting platform physics
  // (BouncingScrollPhysics on iOS) handle the scroll-back gives the same
  // smooth spring animation as KeyboardAvoidingView.
  bool _isDismissing = false;

  KeyboardAnimation? _animation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    FocusManager.instance.addListener(_onFocusChanged);
    if (widget.scrollController != null) {
      _scrollController = widget.scrollController!;
    } else {
      _scrollController = ScrollController();
      _ownsController = true;
    }
  }

  // Uses addPostFrameCallback (one layout frame ≈ 16ms) instead of an
  // arbitrary delay. The ModalRoute.isCurrent guard handles bottom-sheet
  // opens; _scrollGeneration cancels stale callbacks from rapid taps;
  // _isDismissing blocks scrolls when keyboard is truly being dismissed.
  //
  // Note: on Android the static setOnApplyWindowInsetsListener now fires
  // _isDismissing promptly, so the 16ms window is sufficient.
  void _onFocusChanged() {
    if (_lastKeyboardHeight <= 0) return;
    final generation = ++_scrollGeneration;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _scrollGeneration != generation) return;

      final route = ModalRoute.of(context);
      if (route != null && !route.isCurrent) return;

      if (!_isDismissing) _scrollToFocusedInput();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = KeyboardControllerScope.maybeOf(context);
    if (next != _animation) {
      _animation?.lastEventNotifier.removeListener(_onAnimationEvent);
      _animation?.heightNotifier.removeListener(_onHeightChanged);
      _animation = next;
      _animation?.lastEventNotifier.addListener(_onAnimationEvent);
      _animation?.heightNotifier.addListener(_onHeightChanged);
    }
  }

  // Always follow keyboard height per-frame — appear AND dismiss.
  void _onHeightChanged() {
    _paddingNotifier.value = _animation?.heightNotifier.value ?? 0;
  }

  void _onAnimationEvent() {
    final event = _animation?.lastEvent;
    if (event == null) return;

    switch (event.type) {
      case KeyboardEventType.willHide:
        _isDismissing = true;

      case KeyboardEventType.willShow:
        // iOS field switch: willHide → willShow fires immediately.
        _isDismissing = false;

      case KeyboardEventType.didShow:
        _isDismissing = false;
        _lastKeyboardHeight = event.height;
        _paddingNotifier.value = event.height;
        _scrollToFocusedInput();

      case KeyboardEventType.didHide:
        _isDismissing = false;
        _lastKeyboardHeight = 0;
        _paddingNotifier.value = 0;
        // Safety clamp after padding snaps to 0.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !_scrollController.hasClients) return;
          final pos = _scrollController.position;
          if (pos.pixels > pos.maxScrollExtent) {
            _scrollController.jumpTo(pos.maxScrollExtent);
          }
        });

      default:
        break;
    }
  }

  Future<void> _scrollToFocusedInput() async {
    if (!mounted || !_scrollController.hasClients) return;

    final focused = FocusManager.instance.primaryFocus;
    if (focused == null || focused.context == null) return;

    // DOM traversal + geometry delegated to KeyboardGeometryService.
    final targetContext = KeyboardGeometryService.resolveTargetContext(
      focused: focused,
      scrollViewContext: context,
      customFinder: widget.scrollContextFinder,
    );
    if (targetContext == null) return;

    final targetOffset = KeyboardGeometryService.calculateScrollOffset(
      controller: _scrollController,
      scrollViewContext: context,
      targetContext: targetContext,
      keyboardHeight: _lastKeyboardHeight,
      scrollPadding: widget.scrollPadding,
      toolbarInset: KeyboardToolbarInset.of(context),
      screenHeight: MediaQuery.sizeOf(context).height,
    );

    if (targetOffset != null && targetOffset != _scrollController.offset) {
      await _scrollController.animateTo(
        targetOffset,
        duration: widget.animationDuration,
        curve: widget.animationCurve,
      );
    }
  }

  // ── Fallback: no KeyboardProvider in tree ─────────────────────────────────

  @override
  void didChangeMetrics() {
    if (_animation != null) return;
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final newHeight = view.viewInsets.bottom / view.devicePixelRatio;
    if (newHeight != _lastKeyboardHeight) {
      _lastKeyboardHeight = newHeight;
      _paddingNotifier.value = newHeight;
      if (newHeight > 0) _scrollToFocusedInput();
    }
  }

  @override
  void dispose() {
    _animation?.lastEventNotifier.removeListener(_onAnimationEvent);
    _animation?.heightNotifier.removeListener(_onHeightChanged);
    _paddingNotifier.dispose();
    FocusManager.instance.removeListener(_onFocusChanged);
    WidgetsBinding.instance.removeObserver(this);
    if (_ownsController) _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final basePadding = (widget.padding as EdgeInsets?) ?? EdgeInsets.zero;

    return ValueListenableBuilder<double>(
      valueListenable: _paddingNotifier,
      builder: (_, kbHeight, child) {
        return SingleChildScrollView(
          controller: _scrollController,
          padding: basePadding.copyWith(bottom: basePadding.bottom + kbHeight),
          physics: widget.physics,
          reverse: widget.reverse,
          primary: widget.primary,
          clipBehavior: widget.clipBehavior,
          child: child,
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: widget.children,
      ),
    );
  }
}
