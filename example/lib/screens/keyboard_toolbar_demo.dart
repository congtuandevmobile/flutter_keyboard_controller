import 'package:flutter/material.dart';
import 'package:flutter_keyboard_controller/flutter_keyboard_controller.dart';

class KeyboardToolbarDemo extends StatelessWidget {
  const KeyboardToolbarDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return KeyboardToolbarScaffold(
      appBar: AppBar(title: const Text('KeyboardToolbar')),
      toolbar: KeyboardToolbar(
        prevLabel: 'Prev',
        nextLabel: 'Next',
        doneLabel: 'Done',
        onPrev: () => FocusScope.of(context).previousFocus(),
        onNext: () => FocusScope.of(context).nextFocus(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'A Prev / Next / Done toolbar appears above the keyboard '
                  'when any field is focused. Prev/Next navigate between fields; '
                  'Done dismisses the keyboard.',
                  style: TextStyle(
                      color:
                          Theme.of(context).colorScheme.onPrimaryContainer),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const TextField(
                decoration: InputDecoration(labelText: 'First name')),
            const SizedBox(height: 16),
            const TextField(
                decoration: InputDecoration(labelText: 'Last name')),
            const SizedBox(height: 16),
            const TextField(
                decoration: InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 16),
            const TextField(
                decoration: InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Bio',
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              // Extra scroll padding so Bio scrolls fully above the toolbar.
              scrollPadding: EdgeInsets.only(bottom: 80),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => KeyboardController.dismiss(),
                child: const Text('Save Profile'),
              ),
            ),
            // Bottom padding so Save button is never behind the toolbar.
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
