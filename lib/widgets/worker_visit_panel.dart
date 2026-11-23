import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../screens/mazdoor_flow.dart' show AppRoutes, bilingual;

class WorkerVisitPanel extends StatefulWidget {
  const WorkerVisitPanel({super.key});

  @override
  State<WorkerVisitPanel> createState() => _WorkerVisitPanelState();
}

class _WorkerVisitPanelState extends State<WorkerVisitPanel> {
  late final _uid = FirebaseAuth.instance.currentUser?.uid;
  late final _user = _uid == null
      ? null
      : FirebaseFirestore.instance.collection('users').doc(_uid);
  late final _profile = _user?.snapshots();
  bool _saving = false;

  Future<void> _setAvailable(bool acceptsVisits) async {
    final user = _user;
    if (_saving || user == null) return;
    setState(() => _saving = true);
    try {
      await user.update({'acceptsVisits': acceptsVisits});
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              bilingual(
                context,
                'Could not update visit availability.',
                'معائنے کے لیے دستیابی تبدیل نہیں ہو سکی۔',
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Card(
    child: Column(
      children: [
        ListTile(
          leading: const Icon(Icons.event_available_outlined),
          title: Text(
            bilingual(context, 'Visit Requests', 'معائنے کی درخواستیں'),
          ),
          subtitle: Text(
            bilingual(
              context,
              'Accept, decline or complete inspection visits',
              'معائنہ قبول، رد یا مکمل کریں',
            ),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.pushNamed(context, AppRoutes.visits),
        ),
        const Divider(height: 1),
        StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _profile,
          builder: (context, snapshot) {
            final data = snapshot.data?.data();
            return SwitchListTile(
              value: data != null && canReceiveVisits(data),
              onChanged: _saving || data == null || !isApprovedWorker(data)
                  ? null
                  : _setAvailable,
              title: Text(
                bilingual(
                  context,
                  'Accept new visit requests',
                  'معائنے کی نئی درخواستیں وصول کریں',
                ),
              ),
              subtitle: Text(
                bilingual(
                  context,
                  'Requests can arrive while you are offline.',
                  'آف لائن ہونے پر بھی درخواستیں موصول ہو سکتی ہیں۔',
                ),
              ),
            );
          },
        ),
      ],
    ),
  );
}
