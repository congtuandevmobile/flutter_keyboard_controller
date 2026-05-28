import 'package:flutter/material.dart';
import '../controller/keyboard_controller.dart';
import '../provider/keyboard_animation.dart';
import '../provider/keyboard_provider.dart';

/// A toolbar widget rendered above the keyboard that provides Prev / Next /
/// Done navigation buttons for moving between focusable inputs.
///
/// Mirrors `KeyboardToolbar` from react-native-keyboard-controller.
///
/// ```dart
/// KeyboardToolbarScaffold(
///   toolbar: KeyboardToolbar(
///     doneLabel: 'Xong',       // multilang — pass from Dart
///     arrowColor: Colors.blue,
///     doneColor: Colors.blue,
///   ),
///   body: MyForm(),
/// )
/// ```
class KeyboardToolbar extends StatelessWidget {
  const KeyboardToolbar({
    super.key,
    this.onPrev,
    this.onNext,
    this.onDone,
    this.prevLabel = 'Prev',
    this.nextLabel = 'Next',
    this.doneLabel = 'Done',
    this.backgroundColor,
    this.borderColor,
    this.textStyle,
    this.arrowColor,
    this.doneColor,
    this.showArrows = true,
    this.content,
  });

  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final VoidCallback? onDone;

  final String prevLabel;
  final String nextLabel;

  /// Label for the dismiss button. Override for localisation / multilang.
  final String doneLabel;

  final Color? backgroundColor;
  final Color? borderColor;

  /// Base text style applied to all labels. [arrowColor] / [doneColor] take
  /// precedence over this for their respective elements.
  final TextStyle? textStyle;

  /// Color for the ‹ › arrow buttons. Falls back to [textStyle] color then
  /// the theme primary color.
  final Color? arrowColor;

  /// Color for the Done label. Falls back to [textStyle] color then the
  /// theme primary color.
  final Color? doneColor;

  final bool showArrows;
  final Widget? content;

  void _defaultPrev(BuildContext context) =>
      FocusScope.of(context).previousFocus();

  void _defaultNext(BuildContext context) =>
      FocusScope.of(context).nextFocus();

  void _defaultDone() => KeyboardController.dismiss();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = backgroundColor ?? theme.colorScheme.surfaceContainerHighest;
    final border = borderColor ?? theme.dividerColor;

    final baseColor = textStyle?.color ?? theme.colorScheme.primary;
    final baseStyle = textStyle ??
        theme.textTheme.bodyMedium?.copyWith(color: baseColor);

    final resolvedArrowColor = arrowColor ?? baseColor;
    final resolvedDoneColor = doneColor ?? baseColor;

    return Container(
      color: bg,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: border, width: 0.5)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  children: [
                    if (showArrows) ...[
                      _ToolbarButton(
                        icon: Icons.keyboard_arrow_up,
                        label: prevLabel,
                        color: resolvedArrowColor,
                        onTap: () => onPrev != null
                            ? onPrev!()
                            : _defaultPrev(context),
                      ),
                      _ToolbarButton(
                        icon: Icons.keyboard_arrow_down,
                        label: nextLabel,
                        color: resolvedArrowColor,
                        onTap: () => onNext != null
                            ? onNext!()
                            : _defaultNext(context),
                      ),
                    ],
                    if (content != null) ...[
                      const SizedBox(width: 8),
                      Expanded(child: content!),
                    ] else
                      const Spacer(),
                    _ToolbarButton(
                      label: doneLabel,
                      color: resolvedDoneColor,
                      style: baseStyle?.copyWith(
                        color: resolvedDoneColor,
                        fontWeight: FontWeight.w600,
                      ),
                      onTap: onDone ?? _defaultDone,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.label,
    required this.onTap,
    required this.color,
    this.icon,
    this.style,
  });

  final String label;
  final VoidCallback onTap;
  final Color color;
  final IconData? icon;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: icon != null
            ? Icon(icon, size: 24, color: color)
            : Text(label, style: style),
      ),
    );
  }
}

/// Convenience scaffold that positions [KeyboardToolbar] just above the
/// keyboard using a sticky bottom approach.
class KeyboardToolbarScaffold extends StatelessWidget {
  const KeyboardToolbarScaffold({
    super.key,
    required this.body,
    this.toolbar = const KeyboardToolbar(),
    this.appBar,
    this.resizeToAvoidBottomInset = true,
    this.backgroundColor,
    this.floatingActionButton,
    this.bottomNavigationBar,
  });

  final Widget body;
  final KeyboardToolbar toolbar;
  final PreferredSizeWidget? appBar;
  final bool resizeToAvoidBottomInset;
  final Color? backgroundColor;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      backgroundColor: backgroundColor,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: Column(
        children: [
          Expanded(child: body),
          _ToolbarVisibility(toolbar: toolbar),
        ],
      ),
    );
  }
}

class _ToolbarVisibility extends StatefulWidget {
  const _ToolbarVisibility({required this.toolbar});
  final KeyboardToolbar toolbar;

  @override
  State<_ToolbarVisibility> createState() => _ToolbarVisibilityState();
}

class _ToolbarVisibilityState extends State<_ToolbarVisibility>
    with WidgetsBindingObserver {
  KeyboardAnimation? _animation;
  bool _fallbackShow = false;
  // Peak keyboard height this session — used to compute 0→1 slide progress.
  double _maxKeyboardHeight = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // No listener needed here — ValueListenableBuilder in build() drives
    // updates directly, avoiding the setState→rebuild 1-frame delay.
    _animation = KeyboardControllerScope.maybeOf(context);
  }

  @override
  void didChangeMetrics() {
    if (_animation != null) return;
    final bottom = WidgetsBinding
        .instance.platformDispatcher.views.first.viewInsets.bottom;
    final show = bottom > 0;
    if (show != _fallbackShow) setState(() => _fallbackShow = show);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ── Fallback (no KeyboardProvider) ──────────────────────────────────────
    if (_animation == null) {
      if (!_fallbackShow) return const SizedBox.shrink();
      return widget.toolbar;
    }

    // ── Plugin path ──────────────────────────────────────────────────────────
    // ValueListenableBuilder rebuilds on the exact frame the height changes —
    // no setState round-trip, so toolbar and keyboard move together.
    return ValueListenableBuilder<double>(
      valueListenable: _animation!.heightNotifier,
      child: widget.toolbar,
      builder: (_, height, child) {
        if (height <= 0) {
          _maxKeyboardHeight = 0;
          return const SizedBox.shrink();
        }

        if (height > _maxKeyboardHeight) _maxKeyboardHeight = height;

        // Slide the toolbar in/out in sync with the keyboard.
        // factor: 0 = fully hidden, 1 = fully visible.
        final factor = _maxKeyboardHeight > 0
            ? (height / _maxKeyboardHeight).clamp(0.0, 1.0)
            : 1.0;

        return ClipRect(
          child: Align(
            // Align bottom so toolbar rises from the bottom edge,
            // matching the keyboard's upward motion.
            alignment: Alignment.bottomCenter,
            heightFactor: factor,
            child: child,
          ),
        );
      },
    );
  }
}
