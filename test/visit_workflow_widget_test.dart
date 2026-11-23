import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_frontend/app_state.dart';
import 'package:service_frontend/data/mock_data.dart';
import 'package:service_frontend/data/visit_request.dart';
import 'package:service_frontend/screens/customer_home_screen.dart';
import 'package:service_frontend/screens/mazdoor_flow.dart' show AppRoutes;
import 'package:service_frontend/screens/request_visit_screen.dart';
import 'package:service_frontend/screens/visit_requests_screen.dart';
import 'package:service_frontend/screens/worker_directory_screen.dart';
import 'package:service_frontend/services/visit_repository.dart';

const _worker = WorkerModel(
  id: 'selected-worker',
  name: 'Ali Plumber',
  category: 'Plumber',
  categoryKey: 'plumber',
  isApproved: true,
);

class _VisitFake implements VisitRepository {
  List<VisitRequest> visits = [];
  bool? watchedAsWorker;
  String? requestedWorkerId;
  VisitDraft? draft;
  VisitStatus? updatedTo;

  @override
  Stream<List<VisitRequest>> watchMyVisits({required bool asWorker}) {
    watchedAsWorker = asWorker;
    return Stream.value(visits);
  }

  @override
  Future<void> requestVisit({
    required String workerId,
    required VisitDraft draft,
  }) async {
    requestedWorkerId = workerId;
    this.draft = draft;
  }

  @override
  Future<void> changeStatus(VisitRequest visit, VisitStatus next) async {
    updatedTo = next;
  }
}

Widget _app(
  Widget home, {
  UserRole role = UserRole.customer,
  RouteFactory? routes,
}) {
  final controller = AppController(initialLocale: 'en')..role = role;
  addTearDown(controller.dispose);
  return AppScope(
    controller: controller,
    child: MaterialApp(home: home, onGenerateRoute: routes),
  );
}

void main() {
  testWidgets(
    'tapping a category opens the worker directory and preserves the selected worker',
    (tester) async {
      String? requestedCategory;
      WorkerModel? selected;
      await tester.pumpWidget(
        _app(
          CustomerHomeScreen(workers: Stream.value(const [])),
          routes: (settings) {
            if (settings.name == AppRoutes.workerDirectory) {
              requestedCategory = settings.arguments as String?;
              return MaterialPageRoute<void>(
                settings: settings,
                builder: (_) => WorkerDirectoryScreen(
                  category: serviceCategoryFor(settings.arguments)!,
                  workers: Stream.value(const [_worker]),
                ),
              );
            }
            if (settings.name == AppRoutes.workerPublicProfile) {
              selected = settings.arguments as WorkerModel;
              return MaterialPageRoute<void>(
                settings: settings,
                builder: (_) => Scaffold(body: Text(selected!.name)),
              );
            }
            return null;
          },
        ),
      );

      await tester.tap(find.text('Plumber'));
      await tester.pumpAndSettle();
      expect(requestedCategory, 'plumber');
      expect(find.text('Ali Plumber'), findsOneWidget);
      expect(find.textContaining('Offline · Accepting visits'), findsOneWidget);
      await tester.tap(find.text('Ali Plumber'));
      await tester.pumpAndSettle();
      expect(selected?.id, 'selected-worker');
    },
  );

  testWidgets(
    'visit form requires an address and time, then submits to the selected worker',
    (tester) async {
      final repository = _VisitFake();
      await tester.pumpWidget(
        _app(
          RequestVisitScreen(worker: _worker, repository: repository),
          routes: (settings) => settings.name == AppRoutes.visits
              ? MaterialPageRoute<void>(
                  settings: settings,
                  builder: (_) => const Scaffold(body: Text('Visits screen')),
                )
              : null,
        ),
      );
      final submit = find.text('Send Visit Request');
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(repository.requestedWorkerId, isNull);
      expect(find.text('Enter the address for the visit.'), findsOneWidget);
      expect(find.text('Choose a future date and time.'), findsOneWidget);

      await tester.enterText(
        find.byType(TextFormField).first,
        '  23 Example Street ',
      );
      await tester.tap(find.text('Choose preferred date & time'));
      await tester.pumpAndSettle();
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      tester
          .widget<CalendarDatePicker>(find.byType(CalendarDatePicker))
          .onDateChanged(tomorrow);
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();

      expect(repository.requestedWorkerId, 'selected-worker');
      expect(repository.draft?.address, '23 Example Street');
      expect(find.text('Visits screen'), findsOneWidget);
    },
  );

  testWidgets('workers see actionable visit requests', (tester) async {
    final repository = _VisitFake()
      ..visits = [
        VisitRequest(
          id: 'request',
          customerName: 'Sara',
          workerName: 'Ali Plumber',
          address: '23 Example Street',
          preferredAt: DateTime.now().add(const Duration(hours: 2)),
          note: '',
          status: VisitStatus.requested,
        ),
      ];
    await tester.pumpWidget(
      _app(VisitRequestsScreen(repository: repository), role: UserRole.worker),
    );
    await tester.pumpAndSettle();
    expect(repository.watchedAsWorker, isTrue);
    expect(find.text('Sara'), findsOneWidget);
    await tester.tap(find.text('Accept visit'));
    await tester.pumpAndSettle();
    expect(repository.updatedTo, VisitStatus.accepted);
    expect(find.text('Mark visit complete'), findsNothing);
  });
}
