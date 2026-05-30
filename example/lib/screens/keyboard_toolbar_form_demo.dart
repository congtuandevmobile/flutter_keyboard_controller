import 'package:flutter/material.dart';
import 'package:flutter_keyboard_controller/flutter_keyboard_controller.dart';

/// Tests [KeyboardToolbar] with a realistic multi-field form that includes
/// bottom sheets — the same scenario that exposed race conditions in
/// [KeyboardAwareScrollView].
///
/// Verifies:
/// - Prev/Next navigates correctly between all text fields
/// - Toolbar hides cleanly when a bottom sheet opens (country / birthday)
/// - Toolbar re-appears after bottom sheet closes and a text field is refocused
/// - Done dismisses keyboard + toolbar without artifacts
class KeyboardToolbarFormDemo extends StatefulWidget {
  const KeyboardToolbarFormDemo({super.key});

  @override
  State<KeyboardToolbarFormDemo> createState() =>
      _KeyboardToolbarFormDemoState();
}

class _KeyboardToolbarFormDemoState extends State<KeyboardToolbarFormDemo> {
  final _emailController    = TextEditingController();
  final _nameController     = TextEditingController();
  final _heightController   = TextEditingController();
  final _weightController   = TextEditingController();
  final _cityController     = TextEditingController();
  final _addressController  = TextEditingController();
  final _phoneController    = TextEditingController();

  String?   _country;
  DateTime? _birthday;
  bool      _submitted = false;

  Future<void> _pickCountry() async {
    await KeyboardController.dismiss();
    if (!mounted) return;
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CountryPicker(selected: _country),
    );
    if (picked != null && mounted) setState(() => _country = picked);
  }

  Future<void> _pickBirthday() async {
    await KeyboardController.dismiss();
    if (!mounted) return;
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _BirthdayPicker(initial: _birthday),
    );
    if (picked != null && mounted) setState(() => _birthday = picked);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardToolbarScaffold(
      appBar: AppBar(title: const Text('KeyboardToolbar — Form')),
      toolbar: KeyboardToolbar(
        margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        borderRadius: BorderRadius.circular(100),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        doneLabel: 'Done',
        arrowColor: Colors.indigo,
        doneColor: Colors.indigo,
        onPrev: () => FocusScope.of(context).previousFocus(),
        onNext: () => FocusScope.of(context).nextFocus(),
      ),
      resizeToAvoidBottomInset: false,
      body: KeyboardAwareScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Tests Prev/Next between text fields and bottom sheets.\n'
                  'Tap a text field → toolbar appears.\n'
                  'Tap Country or Birthday → bottom sheet opens, toolbar hides.\n'
                  'Close bottom sheet + tap a field → toolbar re-appears.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Personal ─────────────────────────────────────────────────────
            _sectionLabel('Personal'),
            const SizedBox(height: 8),
            _card([
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email *',
                  errorText: _submitted && _emailController.text.isEmpty
                      ? 'Required' : null,
                ),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full name *',
                  errorText: _submitted && _nameController.text.isEmpty
                      ? 'Required' : null,
                ),
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 12),
              // Bottom sheet — toolbar should hide, then re-appear
              _TappableField(
                label: 'Birthday *',
                value: _birthday == null
                    ? null
                    : '${_birthday!.day}/${_birthday!.month}/${_birthday!.year}',
                icon: Icons.calendar_today_outlined,
                error: _submitted && _birthday == null ? 'Required' : null,
                onTap: _pickBirthday,
              ),
            ]),

            const SizedBox(height: 16),

            // ── Health ────────────────────────────────────────────────────────
            _sectionLabel('Health'),
            const SizedBox(height: 8),
            _card([
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _heightController,
                      decoration: const InputDecoration(labelText: 'Height (cm)'),
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _weightController,
                      decoration: const InputDecoration(labelText: 'Weight (kg)'),
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                ],
              ),
            ]),

            const SizedBox(height: 16),

            // ── Contact ───────────────────────────────────────────────────────
            _sectionLabel('Contact'),
            const SizedBox(height: 8),
            _card([
              // Bottom sheet — toolbar should hide cleanly
              _TappableField(
                label: 'Country',
                value: _country,
                icon: Icons.arrow_drop_down,
                onTap: _pickCountry,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _cityController,
                decoration: const InputDecoration(labelText: 'City'),
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
              ),
            ]),

            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                setState(() => _submitted = true);
                KeyboardController.dismiss();
              },
              child: const Text('Save'),
            ),
        ],
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

// ── Shared tappable field (bottom-sheet trigger) ──────────────────────────────

class _TappableField extends StatelessWidget {
  const _TappableField({
    required this.label,
    required this.onTap,
    required this.icon,
    this.value,
    this.error,
  });

  final String label;
  final String? value;
  final IconData icon;
  final String? error;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          errorText: error,
          suffixIcon: Icon(icon, size: 20),
        ),
        child: Text(
          value ?? '',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}

// ── Country picker ────────────────────────────────────────────────────────────

const _kCountries = [
  'Vietnam', 'Afghanistan', 'Albania', 'Algeria', 'Argentina', 'Australia',
  'Austria', 'Bangladesh', 'Belgium', 'Brazil', 'Cambodia', 'Canada',
  'China', 'Colombia', 'Denmark', 'Egypt', 'France', 'Germany', 'India',
  'Indonesia', 'Italy', 'Japan', 'South Korea', 'Malaysia', 'Mexico',
  'Netherlands', 'New Zealand', 'Nigeria', 'Norway', 'Pakistan',
  'Philippines', 'Poland', 'Portugal', 'Russia', 'Saudi Arabia',
  'Singapore', 'South Africa', 'Spain', 'Sweden', 'Switzerland',
  'Taiwan', 'Thailand', 'Turkey', 'Ukraine', 'United Kingdom',
  'United States', 'Venezuela', 'Zimbabwe',
];

class _CountryPicker extends StatefulWidget {
  const _CountryPicker({this.selected});
  final String? selected;

  @override
  State<_CountryPicker> createState() => _CountryPickerState();
}

class _CountryPickerState extends State<_CountryPicker> {
  final _search = TextEditingController();
  List<String> _filtered = _kCountries;

  @override
  void initState() {
    super.initState();
    _search.addListener(() {
      final q = _search.text.trim().toLowerCase();
      setState(() {
        _filtered = q.isEmpty
            ? _kCountries
            : _kCountries.where((c) => c.toLowerCase().contains(q)).toList();
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
          _handle(context),
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

// ── Birthday picker ───────────────────────────────────────────────────────────

class _BirthdayPicker extends StatefulWidget {
  const _BirthdayPicker({this.initial});
  final DateTime? initial;

  @override
  State<_BirthdayPicker> createState() => _BirthdayPickerState();
}

class _BirthdayPickerState extends State<_BirthdayPicker> {
  late int _year, _month, _day;

  @override
  void initState() {
    super.initState();
    final d = widget.initial ?? DateTime(2000, 1, 1);
    _year = d.year; _month = d.month; _day = d.day;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _handle(context),
            Text('Birthday', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _drop('Month', _month, 1, 12, (v) => setState(() => _month = v))),
                const SizedBox(width: 8),
                Expanded(child: _drop('Day',   _day,   1, 31, (v) => setState(() => _day   = v))),
                const SizedBox(width: 8),
                Expanded(child: _drop('Year',  _year,  1920, DateTime.now().year - 10,
                    (v) => setState(() => _year = v))),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () =>
                    Navigator.pop(context, DateTime(_year, _month, _day)),
                child: const Text('Confirm'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drop(String label, int val, int min, int max, ValueChanged<int> cb) =>
      DropdownButtonFormField<int>(
        value: val,
        decoration: InputDecoration(labelText: label, isDense: true),
        items: [
          for (int i = min; i <= max; i++)
            DropdownMenuItem(value: i, child: Text('$i')),
        ],
        onChanged: (v) => v != null ? cb(v) : null,
      );
}

// ── Shared helpers ────────────────────────────────────────────────────────────

Widget _handle(BuildContext context) => Container(
      width: 40, height: 4,
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.outlineVariant,
        borderRadius: BorderRadius.circular(2),
      ),
    );
