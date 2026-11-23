import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data/mock_data.dart';
import '../data/visit_request.dart';
import '../services/visit_repository.dart';
import '../widgets/visit_labels.dart';
import 'mazdoor_flow.dart' show AppRoutes, MzScaffold, bilingual;

class RequestVisitScreen extends StatefulWidget {
  const RequestVisitScreen({
    super.key,
    required this.worker,
    this.repository = const FirestoreVisitRepository(),
  });

  final WorkerModel worker;
  final VisitRepository repository;

  @override
  State<RequestVisitScreen> createState() => _RequestVisitScreenState();
}

class _RequestVisitScreenState extends State<RequestVisitScreen> {
  final _form = GlobalKey<FormState>();
  final _address = TextEditingController();
  final _note = TextEditingController();
  DateTime? _preferredAt;
  String? _timeError;
  bool _sending = false;

  @override
  void dispose() {
    _address.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final current = _preferredAt;
    final lastDate = DateTime(
      today.year,
      today.month,
      today.day + VisitDraft.schedulingDays,
    );
    final selectedDay = DateUtils.dateOnly(current ?? today);
    final day = await showDatePicker(
      context: context,
      firstDate: today,
      lastDate: lastDate,
      initialDate: selectedDay.isBefore(today) || selectedDay.isAfter(lastDate)
          ? today
          : selectedDay,
    );
    if (day == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        current ?? DateTime.now().add(const Duration(hours: 1)),
      ),
    );
    if (time == null || !mounted) return;
    final preferred = DateTime(
      day.year,
      day.month,
      day.day,
      time.hour,
      time.minute,
    );
    setState(() {
      _preferredAt = preferred;
      _timeError = VisitDraft.validTime(preferred, DateTime.now())
          ? null
          : bilingual(
              context,
              'Choose a time in the future.',
              'مستقبل کا وقت منتخب کریں۔',
            );
    });
  }

  Future<void> _submit() async {
    if (_sending || !widget.worker.canRequestVisit) return;
    final validForm = _form.currentState?.validate() ?? false;
    final time = _preferredAt;
    if (time == null || !VisitDraft.validTime(time, DateTime.now())) {
      setState(
        () => _timeError = bilingual(
          context,
          'Choose a future date and time.',
          'مستقبل کی تاریخ اور وقت منتخب کریں۔',
        ),
      );
      return;
    }
    if (!validForm) return;

    FocusScope.of(context).unfocus();
    setState(() => _sending = true);
    try {
      await widget.repository.requestVisit(
        workerId: widget.worker.id!,
        draft: VisitDraft(
          address: _address.text,
          preferredAt: time,
          note: _note.text,
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            bilingual(
              context,
              'Visit request sent. Wait for the worker to confirm.',
              'معائنے کی درخواست بھیج دی گئی ہے۔ ورکر کی تصدیق کا انتظار کریں۔',
            ),
          ),
        ),
      );
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.visits,
        (_) => false,
      );
    } on VisitException catch (error) {
      if (mounted) _showError(visitErrorMessage(context, error));
    } catch (_) {
      if (mounted) {
        _showError(
          bilingual(
            context,
            'Could not send the visit request. Please try again.',
            'معائنے کی درخواست نہیں بھیجی جا سکی۔ دوبارہ کوشش کریں۔',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final worker = widget.worker;
    final isUrdu = AppScope.of(context).isUrdu;
    return MzScaffold(
      title: bilingual(context, 'Request a Visit', 'معائنے کی درخواست'),
      showBottomNav: false,
      enableExitPopScope: false,
      child: PopScope(
        canPop: !_sending,
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                title: Text(worker.name),
                subtitle: Text(worker.categoryLabel(isUrdu)),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(
                    bilingual(context, 'Free inspection visit', 'مفت معائنہ'),
                  ),
                  subtitle: Text(
                    bilingual(
                      context,
                      'This books a visit only. No repair work is booked.',
                      'یہ صرف معائنے کی درخواست ہے۔ مرمت کا کام بک نہیں ہوگا۔',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _address,
                enabled: !_sending,
                decoration: InputDecoration(
                  labelText: bilingual(
                    context,
                    'Visit address',
                    'معائنے کا پتہ',
                  ),
                  hintText: bilingual(
                    context,
                    'House, street, area and city',
                    'مکان، گلی، علاقہ اور شہر',
                  ),
                  prefixIcon: const Icon(Icons.location_on_outlined),
                ),
                maxLength: VisitDraft.maxAddressLength,
                maxLines: 2,
                validator: (value) => VisitDraft.validAddress(value ?? '')
                    ? null
                    : bilingual(
                        context,
                        'Enter the address for the visit.',
                        'معائنے کے لیے پتہ درج کریں۔',
                      ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _sending ? null : _pickTime,
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(
                  _preferredAt == null
                      ? bilingual(
                          context,
                          'Choose preferred date & time',
                          'مطلوبہ تاریخ اور وقت منتخب کریں',
                        )
                      : formatVisitTime(context, _preferredAt!),
                ),
              ),
              if (_timeError != null)
                Text(
                  _timeError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _note,
                enabled: !_sending,
                decoration: InputDecoration(
                  labelText: bilingual(
                    context,
                    'Note for the worker (optional)',
                    'ورکر کے لیے نوٹ (اختیاری)',
                  ),
                  hintText: bilingual(
                    context,
                    'For example, water is leaking under the sink',
                    'مثال: سنک کے نیچے پانی ٹپک رہا ہے',
                  ),
                ),
                maxLength: VisitDraft.maxNoteLength,
                minLines: 2,
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _sending || !worker.canRequestVisit ? null : _submit,
                icon: _sending
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_outlined),
                label: Text(
                  bilingual(
                    context,
                    'Send Visit Request',
                    'معائنے کی درخواست بھیجیں',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
