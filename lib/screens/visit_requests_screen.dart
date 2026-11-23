import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data/visit_request.dart';
import '../services/visit_repository.dart';
import '../widgets/visit_labels.dart';
import 'mazdoor_flow.dart' show AppRoutes, MzScaffold, bilingual;

class VisitRequestsScreen extends StatefulWidget {
  const VisitRequestsScreen({
    super.key,
    this.repository = const FirestoreVisitRepository(),
  });

  final VisitRepository repository;

  @override
  State<VisitRequestsScreen> createState() => _VisitRequestsScreenState();
}

class _VisitRequestsScreenState extends State<VisitRequestsScreen> {
  bool? _asWorker;
  late Stream<List<VisitRequest>> _visits;
  final _updating = <String>{};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final asWorker = AppScope.of(context).role == UserRole.worker;
    if (_asWorker != asWorker) {
      _asWorker = asWorker;
      _visits = widget.repository.watchMyVisits(asWorker: asWorker);
    }
  }

  Future<void> _changeStatus(VisitRequest visit, VisitStatus next) async {
    if (_updating.contains(visit.id)) return;
    setState(() => _updating.add(visit.id));
    try {
      if (next == VisitStatus.cancelled || next == VisitStatus.completed) {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(
              next == VisitStatus.cancelled
                  ? bilingual(
                      context,
                      'Cancel this visit?',
                      'یہ معائنہ منسوخ کریں؟',
                    )
                  : bilingual(
                      context,
                      'Mark the inspection visit as complete?',
                      'کیا معائنہ مکمل ہو گیا ہے؟',
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(bilingual(context, 'Go back', 'واپس جائیں')),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(bilingual(context, 'Confirm', 'تصدیق کریں')),
              ),
            ],
          ),
        );
        if (confirm != true || !mounted) return;
      }
      await widget.repository.changeStatus(visit, next);
    } on VisitException catch (error) {
      if (mounted) _showError(visitErrorMessage(context, error));
    } catch (_) {
      if (mounted) {
        _showError(
          bilingual(
            context,
            'Could not update this visit. Please try again.',
            'معائنے کی حیثیت تبدیل نہیں ہو سکی۔ دوبارہ کوشش کریں۔',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _updating.remove(visit.id));
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final asWorker = _asWorker!;
    return MzScaffold(
      showBack: asWorker,
      showBottomNav: !asWorker,
      enableExitPopScope: !asWorker,
      title: asWorker
          ? bilingual(context, 'Visit Requests', 'معائنے کی درخواستیں')
          : bilingual(context, 'My Visits', 'میرے معائنے'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!asWorker)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.sharedHistory),
                icon: const Icon(Icons.history),
                label: Text(
                  bilingual(
                    context,
                    'Repair booking history',
                    'مرمت کی بکنگ کی ہسٹری',
                  ),
                ),
              ),
            ),
          Expanded(
            child: StreamBuilder<List<VisitRequest>>(
              stream: _visits,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          bilingual(
                            context,
                            'Could not load your visits.',
                            'معائنے کی فہرست لوڈ نہیں ہو سکی۔',
                          ),
                        ),
                        TextButton(
                          onPressed: () => setState(() {
                            _visits = widget.repository.watchMyVisits(
                              asWorker: asWorker,
                            );
                          }),
                          child: Text(
                            bilingual(context, 'Retry', 'دوبارہ کوشش کریں'),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final visits = snapshot.data!;
                if (visits.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        asWorker
                            ? bilingual(
                                context,
                                'No visit requests yet. New requests from customers will appear here.',
                                'ابھی کوئی درخواست نہیں ہے۔ گاہکوں کی نئی درخواستیں یہاں دکھائی دیں گی۔',
                              )
                            : bilingual(
                                context,
                                'No visits yet. Choose a category on Home to request a visit.',
                                'ابھی کوئی معائنہ نہیں ہے۔ درخواست کے لیے ہوم پر زمرہ منتخب کریں۔',
                              ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                bool active(VisitRequest visit) =>
                    visit.status == VisitStatus.requested ||
                    visit.status == VisitStatus.accepted;
                final ordered = [
                  ...visits.where(active),
                  ...visits.where((visit) => !active(visit)),
                ];
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: ordered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final visit = ordered[index];
                    return _VisitCard(
                      visit: visit,
                      asWorker: asWorker,
                      updating: _updating.contains(visit.id),
                      onChange: (next) => _changeStatus(visit, next),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _VisitCard extends StatelessWidget {
  const _VisitCard({
    required this.visit,
    required this.asWorker,
    required this.updating,
    required this.onChange,
  });

  final VisitRequest visit;
  final bool asWorker;
  final bool updating;
  final ValueChanged<VisitStatus> onChange;

  @override
  Widget build(BuildContext context) {
    final name = asWorker ? visit.customerName : visit.workerName;
    final timePassed = !visit.preferredAt.isAfter(DateTime.now());
    final actions = visit.status
        .nextStatuses(asWorker: asWorker)
        .where((status) => !timePassed || status != VisitStatus.accepted);
    final statusLabel = switch (visit.status) {
      VisitStatus.requested =>
        asWorker
            ? bilingual(context, 'Requested', 'درخواست موصول ہوئی')
            : bilingual(context, 'Awaiting confirmation', 'تصدیق کا انتظار ہے'),
      VisitStatus.accepted => bilingual(context, 'Confirmed', 'تصدیق ہو گئی'),
      VisitStatus.declined => bilingual(context, 'Declined', 'مسترد'),
      VisitStatus.cancelled => bilingual(context, 'Cancelled', 'منسوخ'),
      VisitStatus.completed => bilingual(context, 'Completed', 'مکمل'),
    };
    final timeLabel = switch (visit.status) {
      VisitStatus.accepted || VisitStatus.completed => bilingual(
        context,
        'Visit time',
        'معائنے کا وقت',
      ),
      _ => bilingual(context, 'Preferred time', 'مطلوبہ وقت'),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name.isNotEmpty
                  ? name
                  : asWorker
                  ? bilingual(context, 'Customer', 'گاہک')
                  : bilingual(context, 'Worker', 'ورکر'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Chip(label: Text(statusLabel)),
            Text('$timeLabel: ${formatVisitTime(context, visit.preferredAt)}'),
            const SizedBox(height: 6),
            Text('${bilingual(context, 'Address', 'پتہ')}: ${visit.address}'),
            if (visit.note.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('${bilingual(context, 'Note', 'نوٹ')}: ${visit.note}'),
            ],
            if (visit.status == VisitStatus.requested && timePassed) ...[
              const SizedBox(height: 6),
              Text(
                bilingual(
                  context,
                  'The requested time has passed.',
                  'درخواست میں دیا گیا وقت گزر چکا ہے۔',
                ),
              ),
            ],
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final action in actions)
                    if (action == VisitStatus.accepted ||
                        action == VisitStatus.completed)
                      FilledButton(
                        onPressed: updating ? null : () => onChange(action),
                        child: Text(_actionLabel(context, action)),
                      )
                    else
                      OutlinedButton(
                        onPressed: updating ? null : () => onChange(action),
                        child: Text(_actionLabel(context, action)),
                      ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _actionLabel(BuildContext context, VisitStatus action) =>
      switch (action) {
        VisitStatus.accepted => bilingual(
          context,
          'Accept visit',
          'معائنہ قبول کریں',
        ),
        VisitStatus.declined => bilingual(context, 'Decline', 'رد کریں'),
        VisitStatus.cancelled => bilingual(
          context,
          'Cancel visit',
          'معائنہ منسوخ کریں',
        ),
        VisitStatus.completed => bilingual(
          context,
          'Mark visit complete',
          'معائنہ مکمل کریں',
        ),
        VisitStatus.requested => throw ArgumentError.value(action),
      };
}
