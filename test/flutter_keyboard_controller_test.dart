import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_keyboard_controller/flutter_keyboard_controller.dart';

void main() {
  // ── KeyboardEventData ───────────────────────────────────────────────────────

  group('KeyboardEventData', () {
    test('fromMap parses keyboardWillShow', () {
      final event = KeyboardEventData.fromMap({
        'type': 'keyboardWillShow',
        'height': 336.0,
        'progress': 0.0,
        'duration': 250.0,
        'timestamp': 1234567890.0,
      });
      expect(event.type, KeyboardEventType.willShow);
      expect(event.height, 336.0);
      expect(event.progress, 0.0);
      expect(event.isVisible, isTrue);
    });

    test('fromMap parses keyboardWillHide', () {
      final event = KeyboardEventData.fromMap({
        'type': 'keyboardWillHide',
        'height': 0.0,
        'progress': 1.0,
        'duration': 200.0,
        'timestamp': 1234567890.0,
      });
      expect(event.type, KeyboardEventType.willHide);
      expect(event.height, 0.0);
      expect(event.isVisible, isFalse);
    });

    test('fromMap parses keyboardMove', () {
      final event = KeyboardEventData.fromMap({
        'type': 'keyboardMove',
        'height': 168.0,
        'progress': 0.5,
        'duration': 250.0,
        'timestamp': 1234567890.0,
      });
      expect(event.type, KeyboardEventType.move);
      expect(event.progress, 0.5);
    });

    test('fromMap defaults unknown type to move', () {
      final event = KeyboardEventData.fromMap({
        'type': 'unknownEvent',
        'height': 0.0,
        'progress': 0.0,
        'duration': 0.0,
        'timestamp': 0.0,
      });
      expect(event.type, KeyboardEventType.move);
    });

    test('copyWith produces new instance with overrides', () {
      final original = KeyboardEventData.fromMap({
        'type': 'keyboardDidShow',
        'height': 336.0,
        'progress': 1.0,
        'duration': 250.0,
        'timestamp': 1.0,
      });
      final copy = original.copyWith(height: 400.0);
      expect(copy.height, 400.0);
      expect(copy.type, original.type);
    });
  });

  // ── KeyboardState ───────────────────────────────────────────────────────────

  group('KeyboardState', () {
    test('hidden() defaults', () {
      const state = KeyboardState.hidden();
      expect(state.height, 0.0);
      expect(state.isVisible, isFalse);
      expect(state.progress, 0.0);
    });

    test('fromMap parses visible state', () {
      final state = KeyboardState.fromMap({
        'height': 320.0,
        'isVisible': true,
        'progress': 1.0,
      });
      expect(state.height, 320.0);
      expect(state.isVisible, isTrue);
    });

    test('fromMap infers isVisible from height', () {
      final state = KeyboardState.fromMap({'height': 300.0});
      expect(state.isVisible, isTrue);
    });
  });

  // ── FocusedInputLayout ──────────────────────────────────────────────────────

  group('FocusedInputLayout', () {
    test('empty() defaults', () {
      const layout = FocusedInputLayout.empty();
      expect(layout.isFocused, isFalse);
      expect(layout.absoluteRect, Rect.zero);
    });

    test('fromMap parses layout', () {
      final layout = FocusedInputLayout.fromMap({
        'isFocused': true,
        'layout': {'x': 10.0, 'y': 200.0, 'width': 300.0, 'height': 48.0},
      });
      expect(layout.isFocused, isTrue);
      expect(layout.absoluteRect.left, 10.0);
      expect(layout.absoluteRect.top, 200.0);
    });
  });

  // ── KeyboardAnimation ───────────────────────────────────────────────────────

  group('KeyboardAnimation', () {
    late KeyboardAnimation animation;

    setUp(() => animation = KeyboardAnimation());
    tearDown(() => animation.dispose());

    test('initial values are zero/false', () {
      expect(animation.height, 0.0);
      expect(animation.progress, 0.0);
      expect(animation.isVisible, isFalse);
      expect(animation.lastEvent, isNull);
    });

    test('handleEvent updates all notifiers', () {
      final event = KeyboardEventData.fromMap({
        'type': 'keyboardDidShow',
        'height': 336.0,
        'progress': 1.0,
        'duration': 250.0,
        'timestamp': 1.0,
      });

      animation.handleEvent(event);

      expect(animation.height, 336.0);
      expect(animation.progress, 1.0);
      expect(animation.isVisible, isTrue);
      expect(animation.lastEvent, event);
    });

    test('notifyListeners fires on handleEvent', () {
      var notified = false;
      animation.addListener(() => notified = true);

      animation.handleEvent(KeyboardEventData.fromMap({
        'type': 'keyboardMove',
        'height': 100.0,
        'progress': 0.3,
        'duration': 0.0,
        'timestamp': 0.0,
      }));

      expect(notified, isTrue);
    });

    test('heightNotifier updates independently', () {
      double? lastHeight;
      animation.heightNotifier.addListener(
        () => lastHeight = animation.heightNotifier.value,
      );

      animation.handleEvent(KeyboardEventData.fromMap({
        'type': 'keyboardMove',
        'height': 250.0,
        'progress': 0.75,
        'duration': 0.0,
        'timestamp': 0.0,
      }));

      expect(lastHeight, 250.0);
    });
  });

  // ── KeyboardProvider widget ─────────────────────────────────────────────────

  group('KeyboardProvider widget', () {
    testWidgets('provides KeyboardAnimation via scope', (tester) async {
      await tester.pumpWidget(
        const KeyboardProvider(
          child: MaterialApp(
            home: _ScopeReader(),
          ),
        ),
      );

      expect(find.text('scope found'), findsOneWidget);
    });

    testWidgets('maybeOf returns null without provider', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: _MaybeReader()),
      );

      expect(find.text('no scope'), findsOneWidget);
    });
  });

  // ── KeyboardAvoidingView ────────────────────────────────────────────────────

  group('KeyboardAvoidingView', () {
    testWidgets('renders child when disabled', (tester) async {
      await tester.pumpWidget(
        const KeyboardProvider(
          child: MaterialApp(
            home: Scaffold(
              body: KeyboardAvoidingView(
                enabled: false,
                child: Text('content'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('content'), findsOneWidget);
    });

    testWidgets('renders child for each behavior', (tester) async {
      for (final behavior in KeyboardAvoidingBehavior.values) {
        await tester.pumpWidget(
          KeyboardProvider(
            child: MaterialApp(
              home: Scaffold(
                body: KeyboardAvoidingView(
                  behavior: behavior,
                  child: const Text('content'),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(find.text('content'), findsOneWidget,
            reason: 'behavior=$behavior');
      }
    });
  });

  // ── KeyboardStickyView ──────────────────────────────────────────────────────

  group('KeyboardStickyView', () {
    testWidgets('renders child', (tester) async {
      await tester.pumpWidget(
        const KeyboardProvider(
          child: MaterialApp(
            home: Scaffold(
              body: KeyboardStickyView(
                child: Text('sticky'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('sticky'), findsOneWidget);
    });
  });

  // ── AndroidSoftInputMode ────────────────────────────────────────────────────

  group('AndroidSoftInputMode', () {
    test('has correct raw values', () {
      expect(AndroidSoftInputMode.adjustResize.value, 0x00000010);
      expect(AndroidSoftInputMode.adjustPan.value, 0x00000020);
      expect(AndroidSoftInputMode.adjustNothing.value, 0x00000030);
      expect(AndroidSoftInputMode.adjustUnspecified.value, 0x00000000);
    });
  });
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _ScopeReader extends StatelessWidget {
  const _ScopeReader();

  @override
  Widget build(BuildContext context) {
    final animation = KeyboardControllerScope.maybeOf(context);
    return Scaffold(body: Text(animation != null ? 'scope found' : 'no scope'));
  }
}

class _MaybeReader extends StatelessWidget {
  const _MaybeReader();

  @override
  Widget build(BuildContext context) {
    final animation = KeyboardControllerScope.maybeOf(context);
    return Scaffold(body: Text(animation != null ? 'scope found' : 'no scope'));
  }
}
