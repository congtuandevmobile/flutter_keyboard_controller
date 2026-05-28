import 'package:flutter/material.dart';
import 'package:flutter_keyboard_controller/flutter_keyboard_controller.dart';

class KeyboardStateDemo extends StatefulWidget {
  const KeyboardStateDemo({super.key});

  @override
  State<KeyboardStateDemo> createState() => _KeyboardStateDemoState();
}

class _KeyboardStateDemoState extends State<KeyboardStateDemo> {
  String _log = 'Ready.';

  Future<void> _checkIsVisible() async {
    final visible = await KeyboardController.isVisible();
    _appendLog('isVisible() → $visible');
  }

  Future<void> _checkState() async {
    final state = await KeyboardController.state();
    _appendLog('state() → height: ${state.height.toStringAsFixed(1)}, '
        'visible: ${state.isVisible}');
  }

  Future<void> _dismiss() async {
    await KeyboardController.dismiss();
    _appendLog('dismiss() called');
  }

  Future<void> _dismissKeepFocus() async {
    await KeyboardController.dismiss(keepFocus: true);
    _appendLog('dismiss(keepFocus: true) called');
  }

  Future<void> _preload() async {
    await KeyboardController.preload();
    _appendLog('preload() called (iOS only)');
  }

  Future<void> _setAdjustNothing() async {
    await KeyboardController.setInputMode(AndroidSoftInputMode.adjustNothing);
    _appendLog('setInputMode(adjustNothing) — Android only');
  }

  Future<void> _setAdjustResize() async {
    await KeyboardController.setDefaultMode();
    _appendLog('setDefaultMode() — restores adjustResize');
  }

  void _appendLog(String msg) {
    setState(() => _log = '${DateTime.now().toIso8601String().substring(11, 19)}  $msg\n$_log');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Keyboard State')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const TextField(
              decoration: InputDecoration(
                labelText: 'Focus me first, then tap buttons below',
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                    onPressed: _checkIsVisible,
                    child: const Text('isVisible()')),
                FilledButton(
                    onPressed: _checkState, child: const Text('state()')),
                FilledButton.tonal(
                    onPressed: _dismiss, child: const Text('dismiss()')),
                FilledButton.tonal(
                    onPressed: _dismissKeepFocus,
                    child: const Text('dismiss(keepFocus)')),
                OutlinedButton(
                    onPressed: _preload,
                    child: const Text('preload() iOS')),
                OutlinedButton(
                    onPressed: _setAdjustNothing,
                    child: const Text('adjustNothing Android')),
                OutlinedButton(
                    onPressed: _setAdjustResize,
                    child: const Text('setDefaultMode Android')),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Log', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _log,
                    style: const TextStyle(
                        fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
