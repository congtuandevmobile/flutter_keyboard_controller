/// Snapshot of the keyboard's current state.
class KeyboardState {
  final double height;
  final bool isVisible;
  final double progress;

  const KeyboardState({
    required this.height,
    required this.isVisible,
    required this.progress,
  });

  const KeyboardState.hidden()
      : height = 0,
        isVisible = false,
        progress = 0;

  factory KeyboardState.fromMap(Map<dynamic, dynamic> map) {
    final double height =
        (map['height'] as num?)?.toDouble() ?? 0.0;
    return KeyboardState(
      height: height,
      isVisible: map['isVisible'] as bool? ?? height > 0,
      progress: (map['progress'] as num?)?.toDouble() ?? (height > 0 ? 1.0 : 0.0),
    );
  }

  @override
  String toString() =>
      'KeyboardState(height: $height, isVisible: $isVisible, progress: $progress)';
}

/// Soft input modes for Android.
/// Mirror of AndroidSoftInputModes from react-native-keyboard-controller.
enum AndroidSoftInputMode {
  adjustUnspecified(0x00000000),
  adjustResize(0x00000010),
  adjustPan(0x00000020),
  adjustNothing(0x00000030);

  final int value;
  const AndroidSoftInputMode(this.value);
}
