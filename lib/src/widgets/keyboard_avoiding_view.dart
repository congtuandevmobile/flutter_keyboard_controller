import 'package:flutter/widgets.dart';
import '../provider/keyboard_provider.dart';

/// How [KeyboardAvoidingView] adjusts its layout when the keyboard appears.
enum KeyboardAvoidingBehavior {
  /// Adds `paddingBottom` equal to the keyboard height.
  padding,

  /// Reduces the widget's height by the keyboard height.
  height,

  /// Translates the widget upward by the keyboard height.
  position,

  /// Combines upward translation + padding (half each).
  translateWithPadding,
}

/// Adjusts its own layout when the on-screen keyboard appears.
///
/// ```dart
/// Scaffold(
///   resizeToAvoidBottomInset: false,
///   body: KeyboardAvoidingView(
///     behavior: KeyboardAvoidingBehavior.padding,
///     child: SingleChildScrollView(child: Column(children: [...])),
///   ),
/// )
/// ```
class KeyboardAvoidingView extends StatelessWidget {
  const KeyboardAvoidingView({
    super.key,
    required this.child,
    this.behavior = KeyboardAvoidingBehavior.padding,
    this.keyboardVerticalOffset = 0.0,
    this.enabled = true,
  });

  final Widget child;
  final KeyboardAvoidingBehavior behavior;
  final double keyboardVerticalOffset;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    final animation = KeyboardControllerScope.maybeOf(context);
    if (animation == null) return child;

    return ValueListenableBuilder<double>(
      valueListenable: animation.heightNotifier,
      builder: (_, keyboardHeight, __) {
        final offset =
            (keyboardHeight + keyboardVerticalOffset).clamp(0.0, double.infinity);

        // IMPORTANT: always return the SAME wrapper widget type regardless of
        // offset value. Switching between wrapper types (e.g. returning bare
        // `child` when offset==0 vs `Padding(child)` when offset>0) causes
        // Flutter to unmount/remount the subtree, which makes TextFields lose
        // their FocusNode — causing the keyboard to flash and dismiss.
        switch (behavior) {
          case KeyboardAvoidingBehavior.padding:
            return Padding(
              padding: EdgeInsets.only(bottom: offset),
              child: child,
            );

          case KeyboardAvoidingBehavior.height:
            final screenH = MediaQuery.sizeOf(context).height;
            final statusBarH = MediaQuery.paddingOf(context).top;
            final targetH =
                (screenH - statusBarH - offset).clamp(0.0, double.infinity);
            return SizedBox(height: targetH, child: child);

          case KeyboardAvoidingBehavior.position:
            return Transform.translate(
              offset: Offset(0, -offset),
              child: child,
            );

          case KeyboardAvoidingBehavior.translateWithPadding:
            return Transform.translate(
              offset: Offset(0, -offset / 2),
              child: Padding(
                padding: EdgeInsets.only(bottom: offset / 2),
                child: child,
              ),
            );
        }
      },
    );
  }
}
