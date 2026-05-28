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
/// **Layout stability rule:** every branch always returns the same wrapper
/// widget type (Padding / SizedBox / Transform) so Flutter never unmounts
/// the child subtree — preventing TextFields from losing their FocusNode.
///
/// **`LayoutBuilder` (outermost) + `ValueListenableBuilder` (inner):**
/// - `LayoutBuilder.constraints.maxHeight` = parent's available height,
///   stable even while `SizedBox` changes its child's height. Used by the
///   `height` behavior to avoid the feedback loop.
/// - `ValueListenableBuilder` reacts to keyboard height each frame.
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

    // LayoutBuilder is the stable outer shell.
    // Its constraints.maxHeight never reflects our own SizedBox child —
    // it comes from the parent (Scaffold body), which doesn't change when
    // resizeToAvoidBottomInset: false.
    return LayoutBuilder(
      builder: (_, constraints) {
        final parentH = constraints.maxHeight;

        return ValueListenableBuilder<double>(
          valueListenable: animation.heightNotifier,
          builder: (_, keyboardHeight, __) {
            final offset = (keyboardHeight + keyboardVerticalOffset)
                .clamp(0.0, double.infinity);

            // Each case always returns its own wrapper type (never bare child)
            // so the element tree stays stable and TextFields keep focus.
            switch (behavior) {
              case KeyboardAvoidingBehavior.padding:
                return Padding(
                  padding: EdgeInsets.only(bottom: offset),
                  child: child,
                );

              case KeyboardAvoidingBehavior.height:
                // parentH (from LayoutBuilder) is the stable original height.
                // Using box.size.height would return the already-shrunk value
                // each frame, creating a feedback loop.
                final targetH = (parentH - offset).clamp(0.0, double.infinity);
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
      },
    );
  }
}
