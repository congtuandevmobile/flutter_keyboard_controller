import 'package:flutter/material.dart';
import 'package:flutter_keyboard_controller/flutter_keyboard_controller.dart';

class KeyboardAvoidingDemo extends StatefulWidget {
  const KeyboardAvoidingDemo({super.key});

  @override
  State<KeyboardAvoidingDemo> createState() => _KeyboardAvoidingDemoState();
}

class _KeyboardAvoidingDemoState extends State<KeyboardAvoidingDemo> {
  KeyboardAvoidingBehavior _behavior = KeyboardAvoidingBehavior.padding;

  static const _descriptions = {
    KeyboardAvoidingBehavior.padding:
        'padding — adds paddingBottom equal to keyboard height.\n'
        'Entire layout stays in place; keyboard does not overlap content.',
    KeyboardAvoidingBehavior.height:
        'height — reduces the view\'s maxHeight by keyboard height.\n'
        'Same visual result as padding but via a SizedBox constraint.',
    KeyboardAvoidingBehavior.position:
        'position — translates the whole view upward by keyboard height.\n'
        'Content can go behind the AppBar — good for overlay screens.',
    KeyboardAvoidingBehavior.translateWithPadding:
        'translateWithPadding — half translate + half padding.\n'
        'Softer upward shift; middle ground between padding and position.',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('KeyboardAvoidingView')),
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          // ── Behavior picker (outside — never affected by keyboard) ──────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: SegmentedButton<KeyboardAvoidingBehavior>(
              segments: const [
                ButtonSegment(
                    value: KeyboardAvoidingBehavior.padding,
                    label: Text('padding')),
                ButtonSegment(
                    value: KeyboardAvoidingBehavior.height,
                    label: Text('height')),
                ButtonSegment(
                    value: KeyboardAvoidingBehavior.position,
                    label: Text('position')),
                ButtonSegment(
                    value: KeyboardAvoidingBehavior.translateWithPadding,
                    label: Text('translate')),
              ],
              selected: {_behavior},
              onSelectionChanged: (s) => setState(() => _behavior = s.first),
            ),
          ),

          // Description (outside — stable reference point)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Card(
                key: ValueKey(_behavior),
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _descriptions[_behavior]!,
                    style: TextStyle(
                      fontSize: 13,
                      color:
                          Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Flexible (FlexFit.loose) instead of Expanded (FlexFit.tight).
          // Expanded forces exact tight constraints → SizedBox inside
          // KeyboardAvoidingView(height) cannot shrink below parentH.
          // Flexible gives MAX constraints → height behavior works correctly.
          Flexible(
            child: KeyboardAvoidingView(
              behavior: _behavior,
              child: Column(
                children: [
                  // Content area
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 48,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant
                                  .withValues(alpha: 0.4),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Content area\n(never overlapped by keyboard)',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Input bar — lifts with keyboard.
                  // No SafeArea here: KeyboardAvoidingView already accounts
                  // for keyboard height so the bar is always just above keys.
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Tap — input lifts above keyboard',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              isDense: true,
                            ),
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => KeyboardController.dismiss(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: () => KeyboardController.dismiss(),
                          icon: const Icon(Icons.send),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
