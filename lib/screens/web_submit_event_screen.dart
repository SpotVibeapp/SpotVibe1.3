import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../config/app_config.dart';
import '../theme/theme.dart';

/// Public, no-account event submission form for the Flutter web app
/// (`https://spotvibeapp.com/app/submit`). Posts go to the `submitWebEvent`
/// callable and wait in the server-only moderation queue. Nothing is written
/// to the public feed until an admin approves the submission.
class WebSubmitEventScreen extends StatefulWidget {
  const WebSubmitEventScreen({super.key});

  @override
  State<WebSubmitEventScreen> createState() => _WebSubmitEventScreenState();
}

class _WebSubmitEventScreenState extends State<WebSubmitEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _location = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController(text: 'El Paso');
  final _zip = TextEditingController();
  final _cost = TextEditingController();
  final _description = TextEditingController();
  final _eventUrl = TextEditingController();
  final _organizerName = TextEditingController();
  final _contactName = TextEditingController();
  final _contactEmail = TextEditingController();
  // Honeypot: hidden from the UI, never focused. Bots that fill it are dropped.
  final _website2 = TextEditingController();

  static const _categories = [
    'Community',
    'Music',
    'Food & Drink',
    'Arts',
    'Sports',
    'Family',
    'Health',
    'Fun & Games',
    'Tech',
    'Other',
  ];

  String _category = 'Community';
  DateTime? _start;
  DateTime? _end;
  bool _consent = false;
  bool _submitting = false;
  bool _success = false;
  String? _message;
  String _lang = 'en';

  @override
  void initState() {
    super.initState();
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    _lang = locale.languageCode.toLowerCase() == 'es' ? 'es' : 'en';
  }

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    _address.dispose();
    _city.dispose();
    _zip.dispose();
    _cost.dispose();
    _description.dispose();
    _eventUrl.dispose();
    _organizerName.dispose();
    _contactName.dispose();
    _contactEmail.dispose();
    _website2.dispose();
    super.dispose();
  }

  String _t(String en, String es) => _lang == 'es' ? es : en;

  String _fmt(DateTime? value) {
    if (value == null) return '';
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    final h = value.hour.toString().padLeft(2, '0');
    final min = value.minute.toString().padLeft(2, '0');
    return '${value.year}-$m-$d $h:$min';
  }

  Future<void> _pickDateTime({required bool start}) async {
    final now = DateTime.now();
    final initial = (start ? _start : _end) ?? now.add(const Duration(days: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now.subtract(const Duration(hours: 1)),
      lastDate: now.add(const Duration(days: 400)),
    );
    if (!mounted || date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (!mounted || time == null) return;
    final picked = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (start) {
        _start = picked;
      } else {
        _end = picked;
      }
    });
  }

  Future<void> _submit() async {
    setState(() => _message = null);
    if (_website2.text.trim().isNotEmpty) {
      // Honeypot hit: pretend to succeed.
      setState(() {
        _success = true;
        _message = _t(
          'Thanks! We will email you when it is live.',
          '¡Gracias! Te avisaremos por correo cuando esté publicado.',
        );
      });
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    if (_start == null) {
      setState(() => _message = _t('Please choose a start time.', 'Elige una hora de inicio.'));
      return;
    }
    if (!_consent) {
      setState(() => _message = _t(
            'Please confirm you are authorized to post this event.',
            'Confirma que tienes permiso para publicar este evento.',
          ));
      return;
    }
    setState(() => _submitting = true);
    try {
      final callable = FirebaseFunctions.instance.httpsCallableFromUrl(
        AppConfig.submitWebEventFunctionUrl,
      );
      await callable.call(<String, dynamic>{
        'title': _title.text.trim(),
        'location': _location.text.trim(),
        'address': _address.text.trim(),
        'city': _city.text.trim(),
        'zipCode': _zip.text.trim(),
        'category': _category,
        'cost': _cost.text.trim(),
        'description': _description.text.trim(),
        'eventUrl': _eventUrl.text.trim(),
        'organizerName': _organizerName.text.trim(),
        'contactName': _contactName.text.trim(),
        'contactEmail': _contactEmail.text.trim(),
        'website2': _website2.text,
        'consent': true,
        'startMs': _start!.millisecondsSinceEpoch,
        'endMs': _end?.millisecondsSinceEpoch,
      });
      if (!mounted) return;
      _formKey.currentState!.reset();
      setState(() {
        _success = true;
        _consent = false;
        _start = null;
        _end = null;
        _message = _t(
          'Thanks! We will email you when it is live.',
          '¡Gracias! Te avisaremos por correo cuando esté publicado.',
        );
      });
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      setState(() {
        _success = false;
        _message = e.message ?? e.code;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _success = false;
        _message = e.toString();
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(_t('Post your event', 'Publica tu evento')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => setState(() => _lang = _lang == 'en' ? 'es' : 'en'),
            child: Text(_lang == 'en' ? 'Español' : 'English'),
          ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            children: [
              Text(
                _t(
                  'Free. No app or account needed. We review every event before it goes live, usually within a day.',
                  'Gratis. Sin app ni cuenta. Revisamos cada evento antes de publicarlo, normalmente en un día.',
                ),
                style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: AppTheme.spacingLg),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _label(_t('Event name *', 'Nombre del evento *')),
                    TextFormField(
                      controller: _title,
                      maxLength: 120,
                      decoration: const InputDecoration(counterText: ''),
                      validator: (v) => (v == null || v.trim().length < 3)
                          ? _t('Enter the event name.', 'Escribe el nombre del evento.')
                          : null,
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    Row(
                      children: [
                        Expanded(
                          child: _DateField(
                            label: _t('Starts *', 'Empieza *'),
                            value: _fmt(_start),
                            onTap: () => _pickDateTime(start: true),
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingMd),
                        Expanded(
                          child: _DateField(
                            label: _t('Ends', 'Termina'),
                            value: _fmt(_end),
                            onTap: () => _pickDateTime(start: false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    _label(_t('Venue *', 'Lugar *')),
                    TextFormField(
                      controller: _location,
                      maxLength: 120,
                      decoration: const InputDecoration(counterText: ''),
                      validator: (v) => (v == null || v.trim().length < 2)
                          ? _t('Enter the venue.', 'Escribe el lugar.')
                          : null,
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    _label(_t('Address', 'Dirección')),
                    TextFormField(controller: _address, maxLength: 200, decoration: const InputDecoration(counterText: '')),
                    const SizedBox(height: AppTheme.spacingMd),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _label(_t('City', 'Ciudad')),
                              TextFormField(controller: _city, maxLength: 60, decoration: const InputDecoration(counterText: '')),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingMd),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text('ZIP', style: TextStyle(fontWeight: FontWeight.w600)),
                              TextFormField(
                                controller: _zip,
                                maxLength: 10,
                                decoration: const InputDecoration(counterText: ''),
                                validator: (v) {
                                  final value = v?.trim() ?? '';
                                  if (value.isEmpty) return null;
                                  if (!RegExp(r'^\d{5}(-\d{4})?$').hasMatch(value)) {
                                    return _t('Use a 5-digit ZIP.', 'Usa un ZIP de 5 dígitos.');
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    _label(_t('Category', 'Categoría')),
                    InputDecorator(
                      decoration: const InputDecoration(),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _category,
                          isExpanded: true,
                          items: _categories
                              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                              .toList(),
                          onChanged: (v) => setState(() => _category = v ?? 'Community'),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    _label(_t('Price (USD, blank = free)', 'Precio (USD, vacío = gratis)')),
                    TextFormField(
                      controller: _cost,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    _label(_t('Description', 'Descripción')),
                    TextFormField(
                      controller: _description,
                      maxLength: 2000,
                      minLines: 4,
                      maxLines: 8,
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    _label(_t('Event or ticket link', 'Enlace del evento o boletos')),
                    TextFormField(
                      controller: _eventUrl,
                      keyboardType: TextInputType.url,
                      maxLength: 300,
                      decoration: const InputDecoration(counterText: ''),
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    _label(_t('Organizer / business name *', 'Organizador / negocio *')),
                    TextFormField(
                      controller: _organizerName,
                      maxLength: 80,
                      decoration: const InputDecoration(counterText: ''),
                      validator: (v) => (v == null || v.trim().length < 2)
                          ? _t('Enter the organizer name.', 'Escribe el organizador.')
                          : null,
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    _label(_t('Your name', 'Tu nombre')),
                    TextFormField(controller: _contactName, maxLength: 80, decoration: const InputDecoration(counterText: '')),
                    const SizedBox(height: AppTheme.spacingMd),
                    _label(_t(
                      'Your email * (not shown publicly; used to let you claim the listing)',
                      'Tu correo * (no se muestra; sirve para reclamar el evento)',
                    )),
                    TextFormField(
                      controller: _contactEmail,
                      keyboardType: TextInputType.emailAddress,
                      maxLength: 120,
                      decoration: const InputDecoration(counterText: ''),
                      validator: (v) {
                        final value = v?.trim() ?? '';
                        if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value)) {
                          return _t('Enter a valid email.', 'Escribe un correo válido.');
                        }
                        return null;
                      },
                    ),
                    Offstage(
                      offstage: true,
                      child: TextFormField(
                        controller: _website2,
                        decoration: const InputDecoration(labelText: 'Leave empty'),
                        autofillHints: const [],
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    CheckboxListTile(
                      value: _consent,
                      onChanged: (v) => setState(() => _consent = v ?? false),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      title: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(_t(
                            'I organize this event or am authorized to post it, and I agree to the ',
                            'Organizo este evento o tengo permiso para publicarlo, y acepto los ',
                          )),
                          GestureDetector(
                            onTap: () => context.push('/terms'),
                            child: Text(
                              _t('Terms.', 'Términos.'),
                              style: TextStyle(color: colors.primary, decoration: TextDecoration.underline),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingLg),
                    FilledButton(
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_t('Submit for review', 'Enviar a revisión')),
                    ),
                    if (_message != null) ...[
                      const SizedBox(height: AppTheme.spacingMd),
                      Text(
                        _message!,
                        style: text.bodyMedium?.copyWith(
                          color: _success ? colors.primary : colors.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
      );
}

class _DateField extends StatelessWidget {
  const _DateField({required this.label, required this.value, required this.onTap});

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(value.isEmpty ? '—' : value),
      ),
    );
  }
}
