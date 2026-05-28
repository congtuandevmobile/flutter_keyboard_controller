import 'package:flutter/material.dart';
import 'package:flutter_keyboard_controller/flutter_keyboard_controller.dart';

class KeyboardAwareScrollDemo extends StatelessWidget {
  const KeyboardAwareScrollDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('KeyboardAwareScrollView')),
      body: KeyboardAwareScrollView(
        padding: const EdgeInsets.all(24),
        children: [
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Tap any field — the scroll view automatically scrolls so '
                'the focused input is always above the keyboard.',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer),
              ),
            ),
          ),
          const SizedBox(height: 24),
          for (int i = 1; i <= 10; i++) ...[
            TextField(
              decoration: InputDecoration(labelText: 'Field $i'),
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
