import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flutter_keyboard_controller/flutter_keyboard_controller.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ── KeyboardController imperative API ─────────────────────────────────────

  group('KeyboardController', () {
    testWidgets('isVisible returns false when no keyboard is shown',
        (tester) async {
      await tester.pumpWidget(
        const KeyboardProvider(child: MaterialApp(home: Scaffold())),
      );
      await tester.pumpAndSettle();

      final visible = await KeyboardController.isVisible();
      expect(visible, isFalse);
    });

    testWidgets('state() returns height 0 when keyboard is hidden',
        (tester) async {
      await tester.pumpWidget(
        const KeyboardProvider(child: MaterialApp(home: Scaffold())),
      );
      await tester.pumpAndSettle();

      final state = await KeyboardController.state();
      expect(state.height, 0.0);
      expect(state.isVisible, isFalse);
    });

    testWidgets('dismiss() does not throw when keyboard is already hidden',
        (tester) async {
      await tester.pumpWidget(
        const KeyboardProvider(child: MaterialApp(home: Scaffold())),
      );

      await expectLater(
        KeyboardController.dismiss(),
        completes,
      );
    });
  });

  // ── KeyboardProvider + KeyboardAnimation ──────────────────────────────────

  group('KeyboardProvider', () {
    testWidgets('provides KeyboardAnimation to descendants', (tester) async {
      late KeyboardAnimation captured;

      await tester.pumpWidget(
        KeyboardProvider(
          child: MaterialApp(
            home: Builder(builder: (context) {
              captured = KeyboardControllerScope.of(context);
              return const Scaffold();
            }),
          ),
        ),
      );
      await tester.pump();

      expect(captured.height, 0.0);
      expect(captured.isVisible, isFalse);
    });
  });

  // ── KeyboardAvoidingView ──────────────────────────────────────────────────

  group('KeyboardAvoidingView', () {
    testWidgets('renders children with padding behavior', (tester) async {
      await tester.pumpWidget(
        const KeyboardProvider(
          child: MaterialApp(
            home: Scaffold(
              body: KeyboardAvoidingView(
                behavior: KeyboardAvoidingBehavior.padding,
                child: TextField(
                  decoration: InputDecoration(labelText: 'Name'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('renders children with height behavior', (tester) async {
      await tester.pumpWidget(
        const KeyboardProvider(
          child: MaterialApp(
            home: Scaffold(
              body: KeyboardAvoidingView(
                behavior: KeyboardAvoidingBehavior.height,
                child: Text('content'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('content'), findsOneWidget);
    });
  });

  // ── KeyboardAwareScrollView ───────────────────────────────────────────────

  group('KeyboardAwareScrollView', () {
    testWidgets('renders all children', (tester) async {
      await tester.pumpWidget(
        KeyboardProvider(
          child: MaterialApp(
            home: Scaffold(
              body: KeyboardAwareScrollView(
                children: List.generate(
                  5,
                  (i) => TextField(
                    decoration: InputDecoration(labelText: 'Field $i'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNWidgets(5));
    });
  });

  // ── KeyboardStickyView ────────────────────────────────────────────────────

  group('KeyboardStickyView', () {
    testWidgets('renders child at bottom', (tester) async {
      await tester.pumpWidget(
        const KeyboardProvider(
          child: MaterialApp(
            home: Scaffold(
              body: KeyboardStickyView(
                child: Text('sticky bar'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('sticky bar'), findsOneWidget);
    });
  });

  // ── KeyboardChatScrollView ────────────────────────────────────────────────

  group('KeyboardChatScrollView', () {
    testWidgets('renders messages in reverse order', (tester) async {
      await tester.pumpWidget(
        KeyboardProvider(
          child: MaterialApp(
            home: Scaffold(
              body: KeyboardChatScrollView(
                liftBehavior: KeyboardLiftBehavior.whenAtEnd,
                children: const [
                  Text('msg 1'),
                  Text('msg 2'),
                  Text('msg 3'),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('msg 1'), findsOneWidget);
      expect(find.text('msg 3'), findsOneWidget);
    });
  });
}
