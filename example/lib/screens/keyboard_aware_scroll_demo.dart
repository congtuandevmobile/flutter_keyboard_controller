import 'package:flutter/material.dart';
import 'package:flutter_keyboard_controller/flutter_keyboard_controller.dart';

class KeyboardAwareScrollDemo extends StatelessWidget {
  const KeyboardAwareScrollDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('KeyboardAwareScrollView')),
      // resizeToAvoidBottomInset: false is required.
      // KeyboardAwareScrollView adds bottom padding equal to keyboard height,
      // making the content scrollable above the keyboard without Scaffold
      // resize. If both are true, layout shifts twice.
      resizeToAvoidBottomInset: false,
      body: KeyboardAwareScrollView(
        padding: const EdgeInsets.all(24),
        children: [
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Tap any field — the view automatically scrolls to keep the '
                'focused input above the keyboard, even when switching fields '
                'while the keyboard is already visible.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          for (int i = 1; i <= 10; i++) ...[
            TextField(
              decoration: InputDecoration(labelText: 'Field $i'),
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 16),
          ],
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => KeyboardController.dismiss(),
              child: const Text('Done'),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
