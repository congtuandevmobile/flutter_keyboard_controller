import 'package:flutter/widgets.dart';
import '../provider/keyboard_provider.dart';

/// A view that "sticks" to the top edge of the keyboard and moves with it
/// frame-by-frame as the keyboard animates.
///
/// Mirrors `KeyboardStickyView` from react-native-keyboard-controller.
///
/// Common use-case: a toolbar or send-button bar that floats above the
/// keyboard at all times.
///
/// ```dart
/// Stack(
///   children: [
///     MessageList(),
///     KeyboardStickyView(
///       offset: KeyboardStickyOffset(closed: 0, opened: 8),
///       child: MessageInputBar(),
///     ),
///   ],
/// )
/// ```
class KeyboardStickyView extends StatelessWidget {
  const KeyboardStickyView({
    super.key,
    required this.child,
    this.offset = const KeyboardStickyOffset(),
  });

  final Widget child;

  /// Fine-tune the position when keyboard is open vs closed.
  final KeyboardStickyOffset offset;

  @override
  Widget build(BuildContext context) {
    final animation = KeyboardControllerScope.maybeOf(context);
    if (animation == null) return child;

    return Align(
      alignment: Alignment.bottomCenter,
      child: ValueListenableBuilder<double>(
        valueListenable: animation.heightNotifier,
        builder: (context, keyboardHeight, _) {
          final extraOffset = keyboardHeight > 0 ? offset.opened : offset.closed;
          return Padding(
            padding: EdgeInsets.only(
              bottom: keyboardHeight + extraOffset,
            ),
            child: child,
          );
        },
      ),
    );
  }
}

/// Pixel offsets applied to [KeyboardStickyView] depending on keyboard state.
class KeyboardStickyOffset {
  /// Extra offset (dp) when the keyboard is hidden.
  final double closed;

  /// Extra offset (dp) when the keyboard is visible.
  final double opened;

  const KeyboardStickyOffset({
    this.closed = 0,
    this.opened = 0,
  });
}
