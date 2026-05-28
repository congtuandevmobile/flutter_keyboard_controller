import 'package:flutter/material.dart';
import 'package:flutter_keyboard_controller/flutter_keyboard_controller.dart';

class KeyboardAvoidingDemo extends StatefulWidget {
  const KeyboardAvoidingDemo({super.key});

  @override
  State<KeyboardAvoidingDemo> createState() => _KeyboardAvoidingDemoState();
}

class _KeyboardAvoidingDemoState extends State<KeyboardAvoidingDemo> {
  KeyboardAvoidingBehavior _behavior = KeyboardAvoidingBehavior.padding;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('KeyboardAvoidingView')),
      // IMPORTANT: set false so KeyboardAvoidingView handles the avoidance.
      // If both are true, the body gets resized twice.
      resizeToAvoidBottomInset: false,
      // KeyboardAvoidingView wraps the ENTIRE body — including the
      // SegmentedButton — so all behaviors work correctly.
      body: KeyboardAvoidingView(
        behavior: _behavior,
        child: Column(
          children: [
            // Behavior selector lives INSIDE KeyboardAvoidingView so it
            // moves with the content in 'position' mode.
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
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
                onSelectionChanged: (s) =>
                    setState(() => _behavior = s.first),
              ),
            ),
            // Scrollable form — fills remaining space
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          'padding — adds paddingBottom, content scrollable above keyboard.\n'
                          'height — reduces max height, same effect.\n'
                          'position — translates whole view upward.\n'
                          'translate — translate + padding combined.',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const TextField(
                        decoration:
                            InputDecoration(labelText: 'First name')),
                    const SizedBox(height: 16),
                    const TextField(
                        decoration:
                            InputDecoration(labelText: 'Last name')),
                    const SizedBox(height: 16),
                    const TextField(
                        decoration:
                            InputDecoration(labelText: 'Email address'),
                        keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 16),
                    const TextField(
                        decoration:
                            InputDecoration(labelText: 'Password'),
                        obscureText: true),
                    const SizedBox(height: 32),
                    FilledButton(
                      onPressed: () => KeyboardController.dismiss(),
                      child: const Text('Submit'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
