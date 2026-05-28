import 'package:flutter/rendering.dart';

/// Layout information of the currently focused text input.
/// Mirrors FocusedInputLayoutChangedEvent from react-native-keyboard-controller.
class FocusedInputLayout {
  /// Bounds of the focused input in global screen coordinates.
  final Rect absoluteRect;

  /// Whether any input is currently focused.
  final bool isFocused;

  const FocusedInputLayout({
    required this.absoluteRect,
    required this.isFocused,
  });

  const FocusedInputLayout.empty()
      : absoluteRect = Rect.zero,
        isFocused = false;

  factory FocusedInputLayout.fromMap(Map<dynamic, dynamic> map) {
    final layout = map['layout'] as Map<dynamic, dynamic>?;
    return FocusedInputLayout(
      isFocused: map['isFocused'] as bool? ?? false,
      absoluteRect: layout != null
          ? Rect.fromLTWH(
              (layout['x'] as num?)?.toDouble() ?? 0,
              (layout['y'] as num?)?.toDouble() ?? 0,
              (layout['width'] as num?)?.toDouble() ?? 0,
              (layout['height'] as num?)?.toDouble() ?? 0,
            )
          : Rect.zero,
    );
  }

  @override
  String toString() =>
      'FocusedInputLayout(isFocused: $isFocused, rect: $absoluteRect)';
}

/// Text change event from the focused input.
class FocusedInputTextChangedEvent {
  final String text;

  const FocusedInputTextChangedEvent({required this.text});

  factory FocusedInputTextChangedEvent.fromMap(Map<dynamic, dynamic> map) {
    return FocusedInputTextChangedEvent(
      text: map['text'] as String? ?? '',
    );
  }
}

/// Selection/cursor change event from the focused input.
class FocusedInputSelectionChangedEvent {
  final int start;
  final int end;

  const FocusedInputSelectionChangedEvent({
    required this.start,
    required this.end,
  });

  factory FocusedInputSelectionChangedEvent.fromMap(
      Map<dynamic, dynamic> map) {
    final selection = map['selection'] as Map<dynamic, dynamic>?;
    return FocusedInputSelectionChangedEvent(
      start: (selection?['start'] as num?)?.toInt() ?? 0,
      end: (selection?['end'] as num?)?.toInt() ?? 0,
    );
  }

  bool get isCollapsed => start == end;

  @override
  String toString() =>
      'FocusedInputSelectionChangedEvent(start: $start, end: $end)';
}
