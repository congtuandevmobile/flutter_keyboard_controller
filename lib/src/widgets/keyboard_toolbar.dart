import 'package:flutter/material.dart';
import '../controller/keyboard_controller.dart';

/// A toolbar widget rendered above the keyboard that provides Prev / Next /
/// Done navigation buttons for moving between focusable inputs.
///
/// Mirrors `KeyboardToolbar` from react-native-keyboard-controller.
///
/// Wrap your scaffold body or screen with [KeyboardToolbarScaffold], **or**
/// place [KeyboardToolbar] in a [KeyboardStickyView] manually.
///
/// ```dart
/// KeyboardToolbarScaffold(
///   toolbar: KeyboardToolbar(
///     onPrev: () => FocusScope.of(context).previousFocus(),
///     onNext: () => FocusScope.of(context).nextFocus(),
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
    this.showArrows = true,
    this.content,
  });

  /// Called when the user taps the "Prev" arrow/button.
  /// Defaults to [FocusScope.previousFocus].
  final VoidCallback? onPrev;

  /// Called when the user taps the "Next" arrow/button.
  /// Defaults to [FocusScope.nextFocus].
  final VoidCallback? onNext;

  /// Called when the user taps "Done". Defaults to [KeyboardController.dismiss].
  final VoidCallback? onDone;

  final String prevLabel;
  final String nextLabel;
  final String doneLabel;

  final Color? backgroundColor;
  final Color? borderColor;
  final TextStyle? textStyle;

  /// Show the prev/next arrows. Set false to show only Done.
  final bool showArrows;

  /// Optional custom widget placed between arrows and Done button.
  final Widget? content;

  void _defaultPrev(BuildContext context) {
    FocusScope.of(context).previousFocus();
  }

  void _defaultNext(BuildContext context) {
    FocusScope.of(context).nextFocus();
  }

  void _defaultDone() {
    KeyboardController.dismiss();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = backgroundColor ?? theme.colorScheme.surfaceContainerHighest;
    final border = borderColor ?? theme.dividerColor;
    final style = textStyle ??
        theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.primary,
        );

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border(top: BorderSide(color: border, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            children: [
              if (showArrows) ...[
                _ToolbarButton(
                  icon: Icons.keyboard_arrow_up,
                  label: prevLabel,
                  style: style,
                  onTap: () =>
                      onPrev != null ? onPrev!() : _defaultPrev(context),
                ),
                _ToolbarButton(
                  icon: Icons.keyboard_arrow_down,
                  label: nextLabel,
                  style: style,
                  onTap: () =>
                      onNext != null ? onNext!() : _defaultNext(context),
                ),
              ],
              if (content != null) ...[
                const SizedBox(width: 8),
                Expanded(child: content!),
              ] else
                const Spacer(),
              _ToolbarButton(
                label: doneLabel,
                style: style?.copyWith(fontWeight: FontWeight.w600),
                onTap: onDone ?? _defaultDone,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.label,
    required this.onTap,
    this.icon,
    this.style,
  });

  final String label;
  final VoidCallback onTap;
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
            ? Icon(icon, size: 24, color: style?.color)
            : Text(label, style: style),
      ),
    );
  }
}

/// Convenience scaffold that positions [KeyboardToolbar] just above the
/// keyboard using a sticky bottom approach.
///
/// ```dart
/// KeyboardToolbarScaffold(
///   appBar: AppBar(title: Text('Form')),
///   toolbar: const KeyboardToolbar(),
///   body: MyForm(),
/// )
/// ```
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
      body: Stack(
        children: [
          body,
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _ToolbarVisibility(toolbar: toolbar),
          ),
        ],
      ),
    );
  }
}

/// Shows the toolbar only when the keyboard is visible.
class _ToolbarVisibility extends StatefulWidget {
  const _ToolbarVisibility({required this.toolbar});
  final KeyboardToolbar toolbar;

  @override
  State<_ToolbarVisibility> createState() => _ToolbarVisibilityState();
}

class _ToolbarVisibilityState extends State<_ToolbarVisibility>
    with WidgetsBindingObserver {
  bool _show = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeMetrics() {
    final bottom =
        WidgetsBinding.instance.platformDispatcher.views.first.viewInsets.bottom;
    final show = bottom > 0;
    if (show != _show) setState(() => _show = show);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_show) return const SizedBox.shrink();
    final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: widget.toolbar,
    );
  }
}
