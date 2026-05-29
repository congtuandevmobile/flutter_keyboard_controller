import 'package:flutter/material.dart';

/// Demonstrates Flutter's built-in keyboard avoidance using
/// [Scaffold.resizeToAvoidBottomInset] = true (the default).
///
/// Compare this with KeyboardAwareScrollView:
/// - Flutter built-in: Scaffold body shrinks when keyboard appears.
///   No auto-scroll to focused field — you must scroll manually.
/// - KeyboardAwareScrollView: viewport does NOT shrink.
///   Automatically scrolls so the focused field stays visible.
class FlutterBuiltinKeyboardDemo extends StatefulWidget {
  const FlutterBuiltinKeyboardDemo({super.key});

  @override
  State<FlutterBuiltinKeyboardDemo> createState() =>
      _FlutterBuiltinKeyboardDemoState();
}

class _FlutterBuiltinKeyboardDemoState
    extends State<FlutterBuiltinKeyboardDemo> {
  String? _country;

  Future<void> _pickCountry() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CountryPicker(selected: _country),
    );
    if (picked != null && mounted) setState(() => _country = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flutter Built-in Keyboard')),
      // TRUE = default Flutter behavior: Scaffold resizes body when keyboard appears.
      // Downside: no auto-scroll to focused field — field may still be hidden
      // if the remaining viewport is smaller than the scroll offset needed.
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'resizeToAvoidBottomInset: true (Flutter default)\n\n'
                  '✓ Scaffold body shrinks when keyboard opens\n'
                  '✓ TextField.scrollPadding auto-scrolls to focused field\n'
                  '✗ Body resize is instant — no smooth per-frame animation\n'
                  '✗ Scrolls to raw TextField bounds only, ignores label/error\n'
                  '✗ Setting resizeToAvoidBottomInset: false (needed for smooth\n'
                  '   animation) disables both shrink AND auto-scroll',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            _sectionLabel('Personal'),
            const SizedBox(height: 8),
            _card([
              const TextField(
                decoration: InputDecoration(labelText: 'Email *'),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              const TextField(
                decoration: InputDecoration(labelText: 'Full name *'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              // Birthday — bottom sheet
              _CountryDisplaySimple(
                label: 'Birthday *',
                value: null,
                icon: Icons.calendar_today_outlined,
                onTap: () {},
              ),
            ]),

            const SizedBox(height: 16),
            _sectionLabel('Health'),
            const SizedBox(height: 8),
            _card([
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(labelText: 'Height (cm)'),
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(labelText: 'Weight (kg)'),
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                ],
              ),
            ]),

            const SizedBox(height: 16),
            _sectionLabel('Contact'),
            const SizedBox(height: 8),
            _card([
              _CountryDisplaySimple(
                label: 'Country',
                value: _country,
                icon: Icons.arrow_drop_down,
                onTap: _pickCountry,
              ),
              const SizedBox(height: 12),
              const TextField(
                decoration: InputDecoration(labelText: 'City'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              const TextField(
                decoration: InputDecoration(labelText: 'Address'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              const TextField(
                decoration: InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
              ),
            ]),

            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => FocusScope.of(context).unfocus(),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(
          text,
          style: Theme.of(context)
              .textTheme
              .labelLarge
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      );

  Widget _card(List<Widget> children) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      );
}

class _CountryDisplaySimple extends StatelessWidget {
  const _CountryDisplaySimple({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String? value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: Icon(icon, size: 20),
        ),
        child: Text(value ?? '', style: Theme.of(context).textTheme.bodyLarge),
      ),
    );
  }
}

// ── Country picker (reused) ───────────────────────────────────────────────────

const _kAllCountries = [
  'Vietnam',
  'Afghanistan', 'Albania', 'Algeria', 'Argentina', 'Australia',
  'Austria', 'Bangladesh', 'Belgium', 'Bolivia', 'Brazil',
  'Cambodia', 'Canada', 'Chile', 'China', 'Colombia',
  'Croatia', 'Czech Republic', 'Denmark', 'Ecuador', 'Egypt',
  'Ethiopia', 'Finland', 'France', 'Germany', 'Ghana',
  'Greece', 'Hungary', 'India', 'Indonesia', 'Iran',
  'Iraq', 'Ireland', 'Israel', 'Italy', 'Japan',
  'Jordan', 'Kazakhstan', 'Kenya', 'South Korea', 'Kuwait',
  'Laos', 'Lebanon', 'Libya', 'Malaysia', 'Mexico',
  'Morocco', 'Myanmar', 'Nepal', 'Netherlands', 'New Zealand',
  'Nigeria', 'Norway', 'Pakistan', 'Peru', 'Philippines',
  'Poland', 'Portugal', 'Qatar', 'Romania', 'Russia',
  'Saudi Arabia', 'Singapore', 'South Africa', 'Spain', 'Sri Lanka',
  'Sweden', 'Switzerland', 'Taiwan', 'Thailand', 'Tunisia',
  'Turkey', 'Ukraine', 'United Arab Emirates', 'United Kingdom',
  'United States', 'Uruguay', 'Venezuela', 'Yemen', 'Zimbabwe',
];

class _CountryPicker extends StatefulWidget {
  const _CountryPicker({this.selected});
  final String? selected;

  @override
  State<_CountryPicker> createState() => _CountryPickerState();
}

class _CountryPickerState extends State<_CountryPicker> {
  final _search = TextEditingController();
  List<String> _filtered = _kAllCountries;

  @override
  void initState() {
    super.initState();
    _search.addListener(() {
      final q = _search.text.trim().toLowerCase();
      setState(() {
        _filtered = q.isEmpty
            ? _kAllCountries
            : _kAllCountries.where((c) => c.toLowerCase().contains(q)).toList();
      });
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, sc) => Column(
        children: [
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text('Country', style: Theme.of(context).textTheme.titleMedium),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _search,
              decoration: const InputDecoration(
                hintText: 'Search…',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              controller: sc,
              itemCount: _filtered.length,
              itemBuilder: (_, i) {
                final c = _filtered[i];
                return ListTile(
                  title: Text(c),
                  trailing: c == widget.selected
                      ? Icon(Icons.check,
                          color: Theme.of(context).colorScheme.primary)
                      : null,
                  onTap: () => Navigator.pop(context, c),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
