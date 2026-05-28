/// Types of keyboard lifecycle events emitted by the native layer.
enum KeyboardEventType {
  /// Keyboard is about to appear (native: UIKeyboardWillShow / IME onStart).
  willShow,

  /// Keyboard fully visible (native: UIKeyboardDidShow / IME onEnd showing).
  didShow,

  /// Keyboard is about to hide.
  willHide,

  /// Keyboard fully hidden.
  didHide,

  /// Frame-by-frame progress during keyboard animation.
  move,

  /// User-driven interactive dismissal (iOS swipe-down / Android gesture).
  interactive,
}

/// Data carried with every keyboard event from the native layer.
class KeyboardEventData {
  /// Current keyboard height in logical pixels (dp).
  final double height;

  /// Animation progress in [0.0, 1.0].
  /// 0.0 = fully hidden, 1.0 = fully visible.
  final double progress;

  /// Animation duration in milliseconds reported by the native layer.
  final double duration;

  /// Unix timestamp (ms) when the event was fired.
  final double timestamp;

  /// Whether the keyboard is (or will be) visible.
  final bool isVisible;

  /// Native event type.
  final KeyboardEventType type;

  const KeyboardEventData({
    required this.height,
    required this.progress,
    required this.duration,
    required this.timestamp,
    required this.isVisible,
    required this.type,
  });

  factory KeyboardEventData.fromMap(Map<dynamic, dynamic> map) {
    final typeStr = map['type'] as String? ?? 'move';
    final KeyboardEventType type;
    switch (typeStr) {
      case 'keyboardWillShow':
        type = KeyboardEventType.willShow;
        break;
      case 'keyboardDidShow':
        type = KeyboardEventType.didShow;
        break;
      case 'keyboardWillHide':
        type = KeyboardEventType.willHide;
        break;
      case 'keyboardDidHide':
        type = KeyboardEventType.didHide;
        break;
      case 'keyboardInteractive':
        type = KeyboardEventType.interactive;
        break;
      default:
        type = KeyboardEventType.move;
    }

    final double height = (map['height'] as num?)?.toDouble() ?? 0.0;
    final double progress = (map['progress'] as num?)?.toDouble() ?? 0.0;

    return KeyboardEventData(
      height: height,
      progress: progress,
      duration: (map['duration'] as num?)?.toDouble() ?? 0.0,
      timestamp: (map['timestamp'] as num?)?.toDouble() ??
          DateTime.now().millisecondsSinceEpoch.toDouble(),
      isVisible: height > 0,
      type: type,
    );
  }

  KeyboardEventData copyWith({
    double? height,
    double? progress,
    double? duration,
    double? timestamp,
    bool? isVisible,
    KeyboardEventType? type,
  }) {
    return KeyboardEventData(
      height: height ?? this.height,
      progress: progress ?? this.progress,
      duration: duration ?? this.duration,
      timestamp: timestamp ?? this.timestamp,
      isVisible: isVisible ?? this.isVisible,
      type: type ?? this.type,
    );
  }

  @override
  String toString() =>
      'KeyboardEventData(type: $type, height: $height, progress: $progress, '
      'duration: $duration, isVisible: $isVisible)';
}
