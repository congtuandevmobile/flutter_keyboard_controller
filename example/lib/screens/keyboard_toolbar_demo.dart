import 'package:flutter/material.dart';
import 'package:flutter_keyboard_controller/flutter_keyboard_controller.dart';

class KeyboardToolbarDemo extends StatefulWidget {
  const KeyboardToolbarDemo({super.key});

  @override
  State<KeyboardToolbarDemo> createState() => _KeyboardToolbarDemoState();
}

class _KeyboardToolbarDemoState extends State<KeyboardToolbarDemo> {
  Color _arrowColor = Colors.blue;
  Color _doneColor = Colors.blue;
  String _doneLabel = 'Done';

  static const _doneLabels = ['Done', 'Xong', 'Hoàn tất', 'Dismiss'];
  static const _colorOptions = {
    'Blue': Colors.blue,
    'Red': Colors.red,
    'Green': Colors.green,
    'Orange': Colors.orange,
  };

  @override
  Widget build(BuildContext context) {
    return KeyboardToolbarScaffold(
      appBar: AppBar(title: const Text('KeyboardToolbar')),
      toolbar: KeyboardToolbar(
        backgroundColor: Colors.white,
        arrowColor: _arrowColor,
        doneColor: _doneColor,
        doneLabel: _doneLabel,
        onPrev: () => FocusScope.of(context).previousFocus(),
        onNext: () => FocusScope.of(context).nextFocus(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Controls ──────────────────────────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Arrow color',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _colorOptions.entries.map((e) {
                        final selected = _arrowColor == e.value;
                        return ChoiceChip(
                          label: Text(e.key),
                          selected: selected,
                          selectedColor: e.value.withValues(alpha: 0.2),
                          onSelected: (_) =>
                              setState(() => _arrowColor = e.value),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    const Text('Done color',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _colorOptions.entries.map((e) {
                        final selected = _doneColor == e.value;
                        return ChoiceChip(
                          label: Text(e.key),
                          selected: selected,
                          selectedColor: e.value.withValues(alpha: 0.2),
                          onSelected: (_) =>
                              setState(() => _doneColor = e.value),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    const Text('Done label (multilang)',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _doneLabels.map((l) {
                        return ChoiceChip(
                          label: Text(l),
                          selected: _doneLabel == l,
                          onSelected: (_) => setState(() => _doneLabel = l),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Form fields ───────────────────────────────────────────────────
            const TextField(
              decoration: InputDecoration(labelText: 'First name'),
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(labelText: 'Last name'),
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(labelText: 'Phone'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Bio',
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              scrollPadding: EdgeInsets.only(bottom: 80),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => KeyboardController.dismiss(),
                child: const Text('Save'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
