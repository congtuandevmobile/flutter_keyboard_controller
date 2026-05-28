import 'package:flutter/material.dart';
import 'package:flutter_keyboard_controller/flutter_keyboard_controller.dart';

/// Displays live keyboard height and progress values as the keyboard animates.
/// Useful for debugging or building custom animations driven by keyboard state.
class KeyboardAnimationDemo extends StatelessWidget {
  const KeyboardAnimationDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Keyboard Animation')),
      resizeToAvoidBottomInset: true,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Values below update frame-by-frame as the keyboard '
                  'animates. Use KeyboardControllerScope.of(context) to '
                  'drive custom animations.',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const _LiveValues(),
            const SizedBox(height: 24),
            const TextField(
              decoration: InputDecoration(labelText: 'Tap to show keyboard'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveValues extends StatelessWidget {
  const _LiveValues();

  @override
  Widget build(BuildContext context) {
    final animation = KeyboardControllerScope.maybeOf(context);
    if (animation == null) {
      return const Text('No KeyboardProvider found.');
    }

    return Column(
      children: [
        _ValueRow(
          label: 'height',
          notifier: animation.heightNotifier,
          format: (v) => '${v.toStringAsFixed(1)} dp',
          color: Colors.deepPurple,
        ),
        const SizedBox(height: 12),
        _ValueRow(
          label: 'progress',
          notifier: animation.progressNotifier,
          format: (v) => v.toStringAsFixed(3),
          color: Colors.indigo,
        ),
        const SizedBox(height: 12),
        _BoolRow(
          label: 'isVisible',
          notifier: animation.isVisibleNotifier,
        ),
        const SizedBox(height: 12),
        ValueListenableBuilder<double>(
          valueListenable: animation.heightNotifier,
          builder: (_, height, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Progress bar',
                    style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: animation.progress,
                    minHeight: 12,
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ValueRow extends StatelessWidget {
  const _ValueRow({
    required this.label,
    required this.notifier,
    required this.format,
    required this.color,
  });

  final String label;
  final ValueNotifier<double> notifier;
  final String Function(double) format;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(label,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: ValueListenableBuilder<double>(
            valueListenable: notifier,
            builder: (_, value, _) => Text(
              format(value),
              style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: color),
            ),
          ),
        ),
      ],
    );
  }
}

class _BoolRow extends StatelessWidget {
  const _BoolRow({required this.label, required this.notifier});
  final String label;
  final ValueNotifier<bool> notifier;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(label,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: notifier,
          builder: (_, value, _) => Chip(
            label: Text(value.toString()),
            backgroundColor: value ? Colors.green.shade100 : Colors.red.shade100,
            labelStyle: TextStyle(
              color: value ? Colors.green.shade800 : Colors.red.shade800,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
