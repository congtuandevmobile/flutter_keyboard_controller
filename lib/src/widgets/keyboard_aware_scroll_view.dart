import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../provider/keyboard_animation.dart';
import '../provider/keyboard_provider.dart';
import '../models/keyboard_event_data.dart';

/// Marks the outermost boundary of a custom input component so that
/// [KeyboardAwareScrollView] can measure the full height (including labels
/// and error messages below the text field) when scrolling to keep the
/// focused input visible.
///
/// Wrap the root widget of your custom input component with this once:
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
  /// includes the full component height (label + input + error text).
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
  bool _isDismissing = false;
  int _scrollGeneration = 0; // incremented on each focus change to cancel stale scrolls

  // Drives bottom padding via ValueListenableBuilder — only SingleChildScrollView
  // rebuilds per frame, not Column/children.
  //
  // Lifecycle:
  //   appear  → _onHeightChanged follows heightNotifier per-frame (smooth grow)
  //   willHide → _isDismissing=true freezes notifier; scroll returns to natural pos
  //   didHide  → snap to 0; scroll already positioned correctly, no bounce
  final ValueNotifier<double> _paddingNotifier = ValueNotifier(0.0);

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

  // When user switches between fields while keyboard is already visible,
  // no didShow fires — so we scroll manually on focus change.
  void _onFocusChanged() {
    if (_lastKeyboardHeight > 0 && !_isDismissing) {
      _scrollGeneration++; // invalidate any pending scroll from previous focus event
      _scrollToFocusedInput();
    }
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

  // Follow heightNotifier per-frame only during appear phase.
  // Frozen during dismiss to keep maxScrollExtent stable.
  void _onHeightChanged() {
    if (!_isDismissing) {
      _paddingNotifier.value = _animation?.heightNotifier.value ?? 0;
    }
  }

  void _onAnimationEvent() {
    final event = _animation?.lastEvent;
    if (event == null) return;

    switch (event.type) {
      case KeyboardEventType.willHide:
        _isDismissing = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !_scrollController.hasClients) return;
          if (!_isDismissing) return;
          final pos = _scrollController.position;
          final naturalMax =
              (pos.maxScrollExtent - _lastKeyboardHeight).clamp(0.0, double.infinity);
          if (pos.pixels > naturalMax) {
            _scrollController.animateTo(
              naturalMax,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });

      case KeyboardEventType.willShow:
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

      default:
        break;
    }
  }

  Future<void> _scrollToFocusedInput() async {
    final generation = _scrollGeneration;
    await Future<void>.delayed(Duration.zero);
    if (!mounted || !_scrollController.hasClients) return;
    if (_scrollGeneration != generation) return; // stale focus event, abort

    final focused = FocusManager.instance.primaryFocus;
    if (focused == null || focused.context == null) return;

    final targetContext = _resolveScrollContext(focused);
    if (targetContext == null) return;

    final renderObj = targetContext.findRenderObject();
    if (renderObj is! RenderBox || !renderObj.attached || !renderObj.hasSize) return;

    final inputTop = renderObj.localToGlobal(Offset.zero).dy;
    final inputBottom = inputTop + renderObj.size.height;

    final screenHeight = MediaQuery.sizeOf(context).height;
    final visibleBottom = screenHeight - _lastKeyboardHeight;

    // Top of this scroll view (to avoid scrolling content behind AppBar).
    final scrollBox = context.findRenderObject() as RenderBox?;
    final safeTop = (scrollBox?.localToGlobal(Offset.zero).dy ?? 0) +
        widget.scrollPadding.top;

    double targetOffset = _scrollController.offset;
    bool needsScroll = false;

    if (inputBottom > visibleBottom - widget.scrollPadding.bottom) {
      // Field is hidden below keyboard — scroll down.
      targetOffset += inputBottom - visibleBottom + widget.scrollPadding.bottom;
      needsScroll = true;
    } else if (inputTop < safeTop) {
      // Field is hidden above the scroll view top (e.g. behind AppBar) — scroll up.
      targetOffset -= safeTop - inputTop;
      needsScroll = true;
    }

    if (needsScroll) {
      targetOffset =
          targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent);
      if (targetOffset != _scrollController.offset) {
        await _scrollController.animateTo(
          targetOffset,
          duration: widget.animationDuration,
          curve: widget.animationCurve,
        );
      }
    }
  }

  /// Resolves which [BuildContext] to use as the scroll target.
  ///
  /// Priority:
  /// 1. [scrollContextFinder] callback (app-provided)
  /// 2. Ancestor traversal: FormField → outermost custom App* wrapper
  /// 3. The focused node's own context
  BuildContext? _resolveScrollContext(FocusNode focused) {
    // 1. App-provided override (escape hatch for edge cases)
    if (widget.scrollContextFinder != null) {
      return widget.scrollContextFinder!(focused) ?? focused.context;
    }

    // 2. Traverse ancestors — priority order:
    //    a) KeyboardScrollBoundary  ← explicit marker, most accurate
    //    b) FormField               ← covers reactive_forms, TextFormField
    //    c) focused.context         ← plain TextField fallback
    BuildContext? result;
    focused.context?.visitAncestorElements((element) {
      if (element.widget is Scrollable ||
          element.widget is KeyboardAwareScrollView) {
        return false; // stop at scroll boundary
      }

      if (element.widget is KeyboardScrollBoundary) {
        result = element;
        return false; // exact match — stop immediately
      }

      if (element.widget is FormField) {
        result = element; // keep climbing, may find KeyboardScrollBoundary above
      }

      return true;
    });

    return result ?? focused.context;
  }

  // ── Fallback: no KeyboardProvider in tree ─────────────────────────────────

  @override
  void didChangeMetrics() {
    if (_animation != null) return;
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final newHeight = view.viewInsets.bottom / view.devicePixelRatio;
    if (newHeight != _lastKeyboardHeight) {
      _lastKeyboardHeight = newHeight;
      if (!_isDismissing) _paddingNotifier.value = newHeight;
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
      // Column is passed as `child` so it is NOT rebuilt on every keyboard frame.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: widget.children,
      ),
    );
  }
}
