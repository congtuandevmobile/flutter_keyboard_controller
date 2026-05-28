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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
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
          Expanded(
            child: KeyboardAvoidingView(
              behavior: _behavior,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const _InfoCard(
                      'This view avoids the keyboard using the selected behavior. '
                      'Tap an input below and watch the layout adjust.',
                    ),
                    const SizedBox(height: 24),
                    const TextField(
                        decoration: InputDecoration(labelText: 'First name')),
                    const SizedBox(height: 16),
                    const TextField(
                        decoration: InputDecoration(labelText: 'Last name')),
                    const SizedBox(height: 16),
                    const TextField(
                        decoration:
                            InputDecoration(labelText: 'Email address')),
                    const SizedBox(height: 16),
                    const TextField(
                        decoration: InputDecoration(labelText: 'Password'),
                        obscureText: true),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => KeyboardController.dismiss(),
                        child: const Text('Submit'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(text,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer)),
      ),
    );
  }
}
