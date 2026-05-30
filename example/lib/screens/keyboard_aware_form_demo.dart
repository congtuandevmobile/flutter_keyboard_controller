import 'package:flutter/material.dart';
import 'package:flutter_keyboard_controller/flutter_keyboard_controller.dart';

/// Demonstrates [KeyboardAwareScrollView] with a realistic multi-field form.
///
/// Key differences from the basic demo:
/// - Fields are nested inside Cards (like real app forms)
/// - Custom input widgets include a label + error text below the input
/// - [KeyboardScrollBoundary] wraps the outermost widget of each custom input
///   so the scroll target includes the full widget height (label + error)
/// - Switching between fields while keyboard is visible works correctly
class KeyboardAwareFormDemo extends StatefulWidget {
  const KeyboardAwareFormDemo({super.key});

  @override
  State<KeyboardAwareFormDemo> createState() => _KeyboardAwareFormDemoState();
}

class _KeyboardAwareFormDemoState extends State<KeyboardAwareFormDemo> {
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();

  DateTime? _birthday;
  String? _country;
  bool _submitted = false;

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
    // Dismiss keyboard before showing bottom sheet —
    // same pattern as AppDatePicker in a real app.
    await KeyboardController.dismiss();
    if (!mounted) return;

    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _BirthdayPicker(initial: _birthday),
    );
    if (picked != null && mounted) {
      setState(() => _birthday = picked);
    }
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
    return Scaffold(
      appBar: AppBar(title: const Text('KeyboardAwareScrollView — Form')),
      resizeToAvoidBottomInset: false,
      body: KeyboardAwareScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Fields are wrapped with KeyboardScrollBoundary so the scroll '
                'target includes labels and error messages below the input — '
                'not just the raw text field.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Personal ─────────────────────────────────────────────────────
          _SectionLabel('Personal information'),
          const SizedBox(height: 8),
          _Card(children: [
            _FormField(
              label: 'Email *',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              action: TextInputAction.done,
              error: _submitted && _emailController.text.isEmpty
                  ? 'Email is required'
                  : null,
            ),
            const SizedBox(height: 12),
            _FormField(
              label: 'Full name *',
              controller: _nameController,
              action: TextInputAction.done,
              error: _submitted && _nameController.text.isEmpty
                  ? 'Name is required'
                  : null,
            ),
            const SizedBox(height: 12),
            // Birthday — opens a bottom sheet (no keyboard).
            // Demonstrates ModalRoute.isCurrent guard: focusing this field
            // while a text field has the keyboard should not trigger a scroll.
            _BirthdayDisplay(
              value: _birthday,
              error: _submitted && _birthday == null ? 'Birthday is required' : null,
              onTap: _pickBirthday,
            ),
          ]),

          const SizedBox(height: 16),

          // ── Health ────────────────────────────────────────────────────────
          _SectionLabel('Health'),
          const SizedBox(height: 8),
          _Card(children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _FormField(
                    label: 'Height (cm)',
                    controller: _heightController,
                    keyboardType: TextInputType.number,
                    action: TextInputAction.next,
                    error: _submitted &&
                            _heightController.text.isNotEmpty &&
                            int.tryParse(_heightController.text) == null
                        ? 'Invalid number'
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _FormField(
                    label: 'Weight (kg)',
                    controller: _weightController,
                    keyboardType: TextInputType.number,
                    action: TextInputAction.next,
                    error: _submitted &&
                            _weightController.text.isNotEmpty &&
                            int.tryParse(_weightController.text) == null
                        ? 'Invalid number'
                        : null,
                  ),
                ),
              ],
            ),
          ]),

          const SizedBox(height: 16),

          // ── Contact ───────────────────────────────────────────────────────
          _SectionLabel('Contact'),
          const SizedBox(height: 8),
          _Card(children: [
            _CountryDisplay(
              value: _country,
              error: _submitted && _country == null ? 'Country is required' : null,
              onTap: _pickCountry,
            ),
            const SizedBox(height: 12),
            _FormField(
              label: 'City',
              controller: _cityController,
              action: TextInputAction.done,
            ),
            const SizedBox(height: 12),
            _FormField(
              label: 'Address',
              controller: _addressController,
              action: TextInputAction.next,
              error: _submitted &&
                      _addressController.text.length > 100
                  ? 'Max 100 characters'
                  : null,
            ),
            const SizedBox(height: 12),
            _FormField(
              label: 'Phone',
              controller: _phoneController,
              action: TextInputAction.done,
            ),
          ]),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                setState(() => _submitted = true);
                KeyboardController.dismiss();
              },
              child: const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .labelLarge
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}

/// Custom input widget that includes a label + optional error text below
/// the actual [TextField]. Wrapped in [KeyboardScrollBoundary] so
/// [KeyboardAwareScrollView] measures the full widget height.
class _FormField extends StatelessWidget {
  const _FormField({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.action = TextInputAction.next,
    this.error,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final TextInputAction action;
  final String? error;

  @override
  Widget build(BuildContext context) {
    // KeyboardScrollBoundary tells KeyboardAwareScrollView to use THIS
    // widget's bounds (label + input + error) as the scroll target,
    // not just the raw TextField bounds.
    return KeyboardScrollBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            textInputAction: action,
            decoration: InputDecoration(
              labelText: label,
              errorText: error,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Country constants ─────────────────────────────────────────────────────────

const _kCountries = [
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
  'United States', 'Uruguay', 'Venezuela', 'Yemen',
  'Zimbabwe',
];

// ── Country display / picker ──────────────────────────────────────────────────

class _CountryDisplay extends StatelessWidget {
  const _CountryDisplay({required this.value, required this.onTap, this.error});
  final String? value;
  final VoidCallback onTap;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return KeyboardScrollBoundary(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'Country *',
            errorText: error,
            suffixIcon: const Icon(Icons.arrow_drop_down),
          ),
          child: Text(
            value ?? '',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ),
    );
  }
}

class _CountryPicker extends StatefulWidget {
  const _CountryPicker({this.selected});
  final String? selected;

  @override
  State<_CountryPicker> createState() => _CountryPickerState();
}

class _CountryPickerState extends State<_CountryPicker> {
  final _searchController = TextEditingController();
  List<String> _filtered = _kCountries;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearch);
  }

  void _onSearch() {
    final q = _searchController.text.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _kCountries
          : _kCountries.where((c) => c.toLowerCase().contains(q)).toList();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearch);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) {
        return Column(
          children: [
            // Handle
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
                controller: _searchController,
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
                controller: scrollController,
                itemCount: _filtered.length,
                itemBuilder: (_, i) {
                  final country = _filtered[i];
                  final isSelected = country == widget.selected;
                  return ListTile(
                    title: Text(country),
                    trailing: isSelected
                        ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                        : null,
                    selected: isSelected,
                    onTap: () => Navigator.pop(context, country),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Birthday display / picker ─────────────────────────────────────────────────

/// Tappable birthday row that opens a bottom sheet (no keyboard).
/// Wrapped in [KeyboardScrollBoundary] like other custom inputs.
class _BirthdayDisplay extends StatelessWidget {
  const _BirthdayDisplay({
    required this.value,
    required this.onTap,
    this.error,
  });

  final DateTime? value;
  final VoidCallback onTap;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return KeyboardScrollBoundary(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'Birthday *',
            errorText: error,
            suffixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
          ),
          child: Text(
            value == null
                ? ''
                : '${value!.day}/${value!.month}/${value!.year}',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ),
    );
  }
}

/// Simple bottom-sheet date picker — simulates AppDatePicker in a real app.
class _BirthdayPicker extends StatefulWidget {
  const _BirthdayPicker({this.initial});
  final DateTime? initial;

  @override
  State<_BirthdayPicker> createState() => _BirthdayPickerState();
}

class _BirthdayPickerState extends State<_BirthdayPicker> {
  late int _year;
  late int _month;
  late int _day;

  @override
  void initState() {
    super.initState();
    final d = widget.initial ?? DateTime(2000, 1, 1);
    _year = d.year;
    _month = d.month;
    _day = d.day;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text('Birthday', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _Picker(label: 'Month', value: _month, min: 1, max: 12, onChanged: (v) => setState(() => _month = v))),
                const SizedBox(width: 8),
                Expanded(child: _Picker(label: 'Day',   value: _day,   min: 1, max: 31, onChanged: (v) => setState(() => _day   = v))),
                const SizedBox(width: 8),
                Expanded(child: _Picker(label: 'Year',  value: _year,  min: 1920, max: DateTime.now().year - 10, onChanged: (v) => setState(() => _year  = v))),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, DateTime(_year, _month, _day)),
                child: const Text('Confirm'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Picker extends StatelessWidget {
  const _Picker({required this.label, required this.value, required this.min, required this.max, required this.onChanged});
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      value: value,
      decoration: InputDecoration(labelText: label, isDense: true),
      items: [for (int i = min; i <= max; i++) DropdownMenuItem(value: i, child: Text('$i'))],
      onChanged: (v) => v != null ? onChanged(v) : null,
    );
  }
}
