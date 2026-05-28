import 'package:flutter/widgets.dart';
import '../provider/keyboard_provider.dart';

/// How [KeyboardAvoidingView] adjusts its layout when the keyboard appears.
enum KeyboardAvoidingBehavior {
  /// Reduce the widget's height by the keyboard height.
  height,

  /// Add bottom padding equal to the keyboard height.
  padding,

  /// Translate the widget upward by the keyboard height.
  position,

  /// Translate upward AND add padding (useful for bottom sheets with inputs).
  translateWithPadding,
}

/// A widget that automatically adjusts its layout to avoid being obscured
/// by the on-screen keyboard.
///
/// Mirrors `KeyboardAvoidingView` from react-native-keyboard-controller.
///
/// **Behaviors:**
/// | [behavior]            | Effect |
/// |----------------------|--------|
/// | `height`             | Shrinks the widget vertically |
/// | `padding`            | Adds `paddingBottom` |
/// | `position`           | Slides the widget upward |
/// | `translateWithPadding` | Combines translate + padding |
///
/// ```dart
/// KeyboardAvoidingView(
///   behavior: KeyboardAvoidingBehavior.padding,
///   child: Column(
///     children: [
///       Expanded(child: MessageList()),
///       MessageInput(),
///     ],
///   ),
/// );
/// ```
class KeyboardAvoidingView extends StatelessWidget {
  const KeyboardAvoidingView({
    super.key,
    required this.child,
    this.behavior = KeyboardAvoidingBehavior.padding,
    this.keyboardVerticalOffset = 0.0,
    this.duration = const Duration(milliseconds: 250),
    this.curve = Curves.easeOut,
    this.enabled = true,
  });

  final Widget child;

  /// How the view adjusts when the keyboard is visible.
  final KeyboardAvoidingBehavior behavior;

  /// Extra vertical offset in logical pixels.
  /// Positive values move the content further up.
  final double keyboardVerticalOffset;

  /// Duration of the avoidance animation.
  final Duration duration;

  /// Curve of the avoidance animation.
  final Curve curve;

  /// When false, behaves as a plain [SizedBox]/passthrough.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    final animation = KeyboardControllerScope.maybeOf(context);
    if (animation == null) return child;

    return ValueListenableBuilder<double>(
      valueListenable: animation.heightNotifier,
      builder: (context, keyboardHeight, _) {
        final offset =
            (keyboardHeight - keyboardVerticalOffset).clamp(0.0, double.infinity);

        switch (behavior) {
          case KeyboardAvoidingBehavior.height:
            return AnimatedContainer(
              duration: duration,
              curve: curve,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height -
                    MediaQuery.paddingOf(context).top -
                    offset,
              ),
              child: child,
            );

          case KeyboardAvoidingBehavior.padding:
            return AnimatedPadding(
              duration: duration,
              curve: curve,
              padding: EdgeInsets.only(bottom: offset),
              child: child,
            );

          case KeyboardAvoidingBehavior.position:
            return AnimatedSlide(
              duration: duration,
              curve: curve,
              offset: Offset(0, -offset / MediaQuery.sizeOf(context).height),
              child: child,
            );

          case KeyboardAvoidingBehavior.translateWithPadding:
            return AnimatedSlide(
              duration: duration,
              curve: curve,
              offset: Offset(0, -offset / 2 / MediaQuery.sizeOf(context).height),
              child: AnimatedPadding(
                duration: duration,
                curve: curve,
                padding: EdgeInsets.only(bottom: offset / 2),
                child: child,
              ),
            );
        }
      },
    );
  }
}
