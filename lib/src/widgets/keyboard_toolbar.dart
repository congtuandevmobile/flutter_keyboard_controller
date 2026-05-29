import 'dart:ui';

import 'package:flutter/material.dart';
import '../controller/keyboard_controller.dart';
import '../models/keyboard_event_data.dart';
import '../provider/keyboard_animation.dart';
import '../provider/keyboard_provider.dart';
import 'keyboard_sticky_view.dart';

/// A single action button displayed in [KeyboardToolbar]'s center area.
///
/// ```dart
/// KeyboardToolbarAction(
///   icon: Icons.tag,
///   onPressed: () => insertHashtag(),
/// )
///
/// // With selected highlight (like the blue circle in the screenshot)
/// KeyboardToolbarAction(
///   icon: Icons.photo_camera_outlined,
///   onPressed: () => pickImage(),
///   isSelected: _mode == Mode.camera,
///   selectedColor: Colors.blue,
/// )
/// ```
class KeyboardToolbarAction {
  const KeyboardToolbarAction({
    required this.icon,
    required this.onPressed,
    this.isSelected = false,
    this.color,
    this.selectedColor,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;

  /// When true the icon is rendered inside a filled circle (like the first
  /// icon in the screenshot). Use for toggleable modes (e.g. active camera).
  final bool isSelected;

  /// Icon colour. Falls back to toolbar's [KeyboardToolbar.arrowColor] then
  /// the theme primary colour.
  final Color? color;

  /// Fill colour for the selection circle.
  /// Falls back to [color] then the theme primary colour.
  final Color? selectedColor;

  /// Optional tooltip shown on long-press.
  final String? tooltip;
}

/// A toolbar widget rendered above the keyboard.
///
/// **Default layout**
/// ```
/// [ ↑ ↓ ]  [ action … action ]  ──────────  [ Done ]
///  arrows      custom icons        spacer     dismiss
/// ```
///
/// ```dart
/// KeyboardToolbarScaffold(
///   toolbar: KeyboardToolbar(
///     doneLabel: 'Xong',
///     arrowColor: Colors.blue,
///     doneColor: Colors.blue,
///     actions: [
///       KeyboardToolbarAction(icon: Icons.tag, onPressed: insertTag),
///       KeyboardToolbarAction(
///         icon: Icons.photo_camera_outlined,
///         onPressed: openCamera,
///         isSelected: _cameraMode,
///       ),
///     ],
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
    this.prevLabel = '‹',
    this.nextLabel = '›',
    this.doneLabel = 'Done',
    this.backgroundColor,
    this.borderColor,
    this.textStyle,
    this.arrowColor,
    this.doneColor,
    this.showArrows = true,
    this.actions = const [],
    this.content,
    this.margin,
    this.borderRadius,
    this.liquidGlass = false,
  });

  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final VoidCallback? onDone;

  final String prevLabel;
  final String nextLabel;

  /// Label for the dismiss button. Override for localisation / multilang.
  final String doneLabel;

  final Color? backgroundColor;

  /// Top border color. Pass `Colors.transparent` or leave null to hide border.
  final Color? borderColor;
  final TextStyle? textStyle;
  final Color? arrowColor;
  final Color? doneColor;
  final bool showArrows;

  /// Custom icon buttons placed between the arrows and the Done button.
  /// Rendered in a row; keep to ≤ 5 on small screens.
  final List<KeyboardToolbarAction> actions;

  /// Optional arbitrary widget placed in the centre (replaces actions spacer).
  final Widget? content;

  /// Outer margin around the toolbar.
  /// Use to create a floating effect above the keyboard:
  /// ```dart
  /// margin: EdgeInsets.fromLTRB(8, 0, 8, 8)
  /// ```
  final EdgeInsetsGeometry? margin;

  /// Corner radius. Combine with [margin] for a floating pill style:
  /// ```dart
  /// margin: EdgeInsets.fromLTRB(8, 0, 8, 8),
  /// borderRadius: BorderRadius.circular(16),
  /// borderColor: Colors.transparent,
  /// ```
  final BorderRadiusGeometry? borderRadius;

  /// When true, applies a frosted-glass / liquid-glass backdrop blur.
  /// Requires the content behind the toolbar to be visible — works best
  /// with [margin] + [borderRadius] so the blur area is clearly defined.
  /// ```dart
  /// liquidGlass: true,
  /// backgroundColor: Colors.white.withValues(alpha: 0.6),
  /// ```
  final bool liquidGlass;

  void _defaultPrev(BuildContext context) =>
      FocusScope.of(context).previousFocus();

  void _defaultNext(BuildContext context) => FocusScope.of(context).nextFocus();

  void _defaultDone() => KeyboardController.dismiss();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = backgroundColor ?? theme.colorScheme.surfaceContainerHighest;

    final baseColor = textStyle?.color ?? theme.colorScheme.primary;
    final resolvedArrowColor = arrowColor ?? baseColor;
    final resolvedDoneColor = doneColor ?? baseColor;

    final radius = borderRadius ?? BorderRadius.zero;
    final hasRounded = borderRadius != null;
    final hasBorder = !hasRounded && borderColor != Colors.transparent;

    // ── Row content ───────────────────────────────────────────────────────────
    final row = SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          children: [
            if (showArrows) ...[
              _ArrowButton(
                icon: Icons.keyboard_arrow_up,
                color: resolvedArrowColor,
                tooltip: prevLabel,
                onTap: () => onPrev != null ? onPrev!() : _defaultPrev(context),
              ),
              _ArrowButton(
                icon: Icons.keyboard_arrow_down,
                color: resolvedArrowColor,
                tooltip: nextLabel,
                onTap: () => onNext != null ? onNext!() : _defaultNext(context),
              ),
              const SizedBox(width: 4),
            ],
            for (final action in actions)
              _ActionButton(
                action: action,
                fallbackColor: resolvedArrowColor,
                theme: theme,
              ),
            if (content != null) ...[
              const SizedBox(width: 4),
              Expanded(child: content!),
            ] else
              const Spacer(),
            _ToolbarTextButton(
              label: doneLabel,
              color: resolvedDoneColor,
              style: (textStyle ??
                      theme.textTheme.bodyMedium
                          ?.copyWith(color: resolvedDoneColor))
                  ?.copyWith(
                color: resolvedDoneColor,
                fontWeight: FontWeight.w600,
              ),
              onTap: onDone ?? _defaultDone,
            ),
          ],
        ),
      ),
    );

    // ── Assemble with optional glass effect ───────────────────────────────────
    Widget toolbar;

    if (liquidGlass) {
      // Frosted / liquid-glass: blur content behind, semi-transparent fill
      toolbar = ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: (backgroundColor ?? Colors.white).withValues(alpha: 0.65),
              borderRadius: radius,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.4),
                width: 0.5,
              ),
            ),
            child: row,
          ),
        ),
      );
    } else if (hasRounded) {
      // Solid rounded card with shadow
      toolbar = ClipRRect(
        borderRadius: radius,
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: radius,
            border: Border.all(
              color:
                  (borderColor ?? theme.dividerColor).withValues(alpha: 0.15),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: row,
        ),
      );
    } else {
      // Default: flat bar with top border
      toolbar = Container(
        color: bg,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasBorder)
              Container(
                height: 0.5,
                color: borderColor ?? theme.dividerColor,
              ),
            row,
          ],
        ),
      );
    }

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: toolbar,
    );
  }
}

// ── Internal widgets ──────────────────────────────────────────────────────────

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({
    required this.icon,
    required this.color,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final btn = GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Icon(icon, size: 26, color: color),
      ),
    );
    return tooltip != null ? Tooltip(message: tooltip!, child: btn) : btn;
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.action,
    required this.fallbackColor,
    required this.theme,
  });

  final KeyboardToolbarAction action;
  final Color fallbackColor;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final iconColor = action.color ?? fallbackColor;
    final fillColor = action.selectedColor ?? iconColor;

    Widget icon = Icon(action.icon,
        size: 22,
        color: action.isSelected ? theme.colorScheme.onPrimary : iconColor);

    Widget button = GestureDetector(
      onTap: action.onPressed,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: action.isSelected
            ? Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: fillColor,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: icon,
              )
            : SizedBox(width: 34, height: 34, child: Center(child: icon)),
      ),
    );

    return action.tooltip != null
        ? Tooltip(message: action.tooltip!, child: button)
        : button;
  }
}

class _ToolbarTextButton extends StatelessWidget {
  const _ToolbarTextButton({
    required this.label,
    required this.color,
    required this.onTap,
    this.style,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(label, style: style),
      ),
    );
  }
}

// ── ToolbarInset (InheritedWidget) ───────────────────────────────────────────

/// Provides the visible toolbar height to descendants.
/// [KeyboardAwareScrollView] reads this to add extra scroll clearance so
/// focused fields are never hidden behind the floating toolbar.
class KeyboardToolbarInset extends InheritedWidget {
  const KeyboardToolbarInset({
    super.key,
    required this.height,
    required super.child,
  });

  final double height;

  static double of(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<KeyboardToolbarInset>()
            ?.height ??
        0;
  }

  @override
  bool updateShouldNotify(KeyboardToolbarInset old) => height != old.height;
}

// ── KeyboardToolbarScaffold ───────────────────────────────────────────────────

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
    this.toolbarScrollClearance = 64.0,
  });

  final Widget body;
  final KeyboardToolbar toolbar;
  final PreferredSizeWidget? appBar;
  final bool resizeToAvoidBottomInset;
  final Color? backgroundColor;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;

  /// Extra scroll clearance (dp) added automatically to [KeyboardAwareScrollView]
  /// so focused fields scroll above the toolbar with a comfortable gap.
  /// Formula: toolbar_height (~42) + margin_bottom (8) + desired_gap_above_toolbar.
  /// Default 64 = toolbar (~42) + bottom margin (8) + top gap (8) + safety (6).
  /// Match this to your toolbar's [margin] if you use a custom value.
  final double toolbarScrollClearance;

  @override
  Widget build(BuildContext context) {
    final toolbarWidget = _ToolbarVisibility(toolbar: toolbar);

    final bodyWithInset = KeyboardToolbarInset(
      height: toolbarScrollClearance,
      child: body,
    );

    Widget body_;
    if (resizeToAvoidBottomInset) {
      body_ = Column(children: [
        Expanded(child: bodyWithInset),
        toolbarWidget,
      ]);
    } else {
      // When resizeToAvoidBottomInset: false the keyboard overlays the body.
      // We position the toolbar using Positioned(bottom: kbH - clearance) so:
      //   • kbH > clearance  → toolbar above keyboard (normal)
      //   • kbH = 0          → bottom = -clearance  → fully off-screen
      // Stack(clipBehavior: Clip.none) lets the widget render below the
      // physical screen edge, so the toolbar exits with the keyboard smoothly.
      final animation = KeyboardControllerScope.maybeOf(context);

      Widget stackedToolbar;
      if (animation != null) {
        stackedToolbar = ValueListenableBuilder<double>(
          valueListenable: animation.heightNotifier,
          child: toolbarWidget,
          builder: (_, kbH, child) {
            // Place toolbar just above keyboard (bottom = kbH = keyboard top).
            // When kbH < toolbarScrollClearance (near end of dismiss), slide
            // the toolbar off-screen by adding a negative offset so it exits
            // together with the keyboard instead of lingering at bottom: 0.
            //
            // Formula: bottom = kbH + min(0, kbH - approxToolbarHeight)
            //   kbH = 340 → 340 + 0      = 340  (above keyboard) ✓
            //   kbH = 64  → 64  + 0      = 64   (near screen edge)
            //   kbH = 0   → 0   + (-64)  = -64  (off-screen) ✓
            final approx = toolbarScrollClearance;
            final bottom = kbH + (kbH < approx ? kbH - approx : 0.0);
            return Positioned(
              left: 0,
              right: 0,
              bottom: bottom,
              child: child!,
            );
          },
        );
      } else {
        stackedToolbar = Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: KeyboardStickyView(child: toolbarWidget),
        );
      }

      body_ = Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: bodyWithInset),
          stackedToolbar,
        ],
      );
    }

    return Scaffold(
      appBar: appBar,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      backgroundColor: backgroundColor,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: body_,
    );
  }
}

// ── _ToolbarVisibility ────────────────────────────────────────────────────────

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
  double _maxKeyboardHeight = 0;
  // True once keyboard is confirmed visible (didShow) and cleared on didHide.
  // Using lastEventNotifier prevents the toolbar from flickering when the OS
  // fires willHide + willShow during a keyboard-type switch (text → number).
  bool _keyboardVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = KeyboardControllerScope.maybeOf(context);
    if (next != _animation) {
      _animation?.lastEventNotifier.removeListener(_onEvent);
      _animation = next;
      _animation?.lastEventNotifier.addListener(_onEvent);
    }
  }

  void _onEvent() {
    final type = _animation?.lastEvent?.type;
    if (type == KeyboardEventType.didShow ||
        type == KeyboardEventType.willShow) {
      if (!_keyboardVisible && mounted) setState(() => _keyboardVisible = true);
    } else if (type == KeyboardEventType.didHide) {
      if (_keyboardVisible && mounted) {
        setState(() {
          _keyboardVisible = false;
          _maxKeyboardHeight = 0;
        });
      }
    }
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
    _animation?.lastEventNotifier.removeListener(_onEvent);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ── Fallback (no KeyboardProvider) ───────────────────────────────────────
    if (_animation == null) {
      if (!_fallbackShow) return const SizedBox.shrink();
      return widget.toolbar;
    }

    // ── Always go through VLB so toolbar hides via height, not setState snap ───
    // Hiding via outer setState causes a one-frame snap because the toolbar
    // disappears before KeyboardStickyView finishes moving it down.
    // Instead, we hide INSIDE the VLB only when height == 0 (keyboard fully
    // gone) — the toolbar rides down smoothly with the keyboard every frame.
    return ValueListenableBuilder<double>(
      valueListenable: _animation!.heightNotifier,
      child: widget.toolbar,
      builder: (_, height, child) {
        if (height > _maxKeyboardHeight) _maxKeyboardHeight = height;

        // Keyboard logically gone AND height reached 0 → safe to remove.
        if (!_keyboardVisible && height <= 0) {
          _maxKeyboardHeight = 0;
          return const SizedBox.shrink();
        }

        // Keyboard type switch: _keyboardVisible stays true, height may dip
        // to 0 briefly — keep showing so no clip artifact.
        if (_maxKeyboardHeight > 0 && (_keyboardVisible || height > 0)) {
          return child!;
        }

        // Slide-in animation for the very first appearance.
        final factor = _maxKeyboardHeight > 0
            ? (height / _maxKeyboardHeight).clamp(0.0, 1.0)
            : 1.0;

        if (factor >= 1.0) return child!;

        return ClipRect(
          child: Align(
            alignment: Alignment.bottomCenter,
            heightFactor: factor,
            child: child,
          ),
        );
      },
    );
  }
}
