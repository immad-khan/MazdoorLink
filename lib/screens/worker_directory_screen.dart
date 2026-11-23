import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data/mock_data.dart';
import '../services/workers_service.dart';
import 'mazdoor_flow.dart' show AppRoutes, MzScaffold, bilingual;

class WorkerDirectoryScreen extends StatefulWidget {
  const WorkerDirectoryScreen({
    super.key,
    required this.category,
    this.workers,
  });

  final ServiceCategory category;
  final Stream<List<WorkerModel>>? workers;

  @override
  State<WorkerDirectoryScreen> createState() => _WorkerDirectoryScreenState();
}

class _WorkerDirectoryScreenState extends State<WorkerDirectoryScreen> {
  late Stream<List<WorkerModel>> _workers = _loadWorkers();

  Stream<List<WorkerModel>> _loadWorkers() =>
      widget.workers ?? streamApprovedWorkers(categoryKey: widget.category.key);

  @override
  Widget build(BuildContext context) {
    final category = widget.category;
    return MzScaffold(
      showBack: true,
      showBottomNav: false,
      title: bilingual(context, category.en, category.ur),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              bilingual(
                context,
                'Choose an approved worker for an inspection visit. No repair work is booked.',
                'معائنے کے لیے کسی منظور شدہ ورکر کو منتخب کریں۔ مرمت کا کام بک نہیں ہوگا۔',
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<WorkerModel>>(
              stream: _workers,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          bilingual(
                            context,
                            'Could not load workers.',
                            'ورکرز کی فہرست لوڈ نہیں ہو سکی۔',
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              setState(() => _workers = _loadWorkers()),
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
                final workers = snapshot.data!;
                if (workers.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        bilingual(
                          context,
                          'No approved workers in this category yet.',
                          'اس زمرے میں ابھی کوئی منظور شدہ ورکر نہیں ہے۔',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: workers.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) =>
                      Card(child: DirectoryWorkerTile(worker: workers[index])),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

String visitAvailabilityLabel(BuildContext context, WorkerModel worker) {
  if (!worker.canRequestVisit) {
    return bilingual(
      context,
      'Not accepting visits',
      'ابھی معائنے کی درخواستیں نہیں لے رہے',
    );
  }
  return worker.isOnline
      ? bilingual(
          context,
          'Online · Accepting visits',
          'آن لائن · معائنے کی درخواستیں لے رہے ہیں',
        )
      : bilingual(
          context,
          'Offline · Accepting visits',
          'آف لائن · معائنے کی درخواستیں لے رہے ہیں',
        );
}

class DirectoryWorkerTile extends StatelessWidget {
  const DirectoryWorkerTile({super.key, required this.worker});
  final WorkerModel worker;

  @override
  Widget build(BuildContext context) {
    final isUrdu = AppScope.of(context).isUrdu;
    final rating = worker.reviews > 0 && worker.rating > 0
        ? '★ ${worker.rating.toStringAsFixed(1)} (${worker.reviews})'
        : bilingual(context, 'No reviews yet', 'ابھی کوئی جائزہ نہیں');
    final details = [worker.categoryLabel(isUrdu), worker.area, rating];

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      leading: CircleAvatar(
        foregroundImage: worker.image.isNotEmpty
            ? NetworkImage(worker.image)
            : null,
        onForegroundImageError: worker.image.isNotEmpty ? (_, _) {} : null,
        child: Text(worker.name.isEmpty ? '?' : worker.name.characters.first),
      ),
      title: Text(
        worker.name.isNotEmpty
            ? worker.name
            : bilingual(context, 'Worker', 'ورکر'),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        '${details.where((value) => value.isNotEmpty).join(' · ')}\n'
        '${visitAvailabilityLabel(context, worker)}',
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.workerPublicProfile,
        arguments: worker,
      ),
    );
  }
}
