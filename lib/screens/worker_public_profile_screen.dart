import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data/mock_data.dart';
import '../services/workers_service.dart';
import 'mazdoor_flow.dart' show AppRoutes, ConversationArguments, bilingual;
import 'worker_directory_screen.dart' show visitAvailabilityLabel;

class WorkerPublicProfileScreen extends StatefulWidget {
  const WorkerPublicProfileScreen({
    super.key,
    this.initialWorker,
    this.workerId,
  });

  final WorkerModel? initialWorker;
  final String? workerId;

  @override
  State<WorkerPublicProfileScreen> createState() =>
      _WorkerPublicProfileScreenState();
}

class _WorkerPublicProfileScreenState extends State<WorkerPublicProfileScreen> {
  bool _initialized = false;
  bool _openingChat = false;
  bool _savingFavourite = false;
  WorkerModel? _initialWorker;
  Stream<WorkerModel?>? _profile;
  Stream<QuerySnapshot>? _reviews;
  late final _favourites = streamFavouriteWorkerIds();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    _initialWorker =
        widget.initialWorker ?? (args is WorkerModel ? args : null);
    final id =
        widget.workerId ?? _initialWorker?.id ?? (args is String ? args : null);
    if (id == null || id.isEmpty) return;

    _profile = FirebaseFirestore.instance
        .collection('users')
        .doc(id)
        .snapshots()
        .map((doc) {
          final data = doc.data();
          return data == null
              ? null
              : WorkerModel.fromFirestore(data, docId: doc.id);
        });
    _reviews = streamWorkerReviews(id);
  }

  Future<void> _openChat(WorkerModel worker) async {
    final id = worker.id;
    if (_openingChat || id == null) return;
    setState(() => _openingChat = true);
    try {
      final conversationId =
          await findExistingConversation(id) ??
          await createConversation(
            otherUserId: id,
            otherUserName: worker.name,
            otherUserImage: worker.image,
          );
      if (mounted) {
        Navigator.pushNamed(
          context,
          AppRoutes.sharedConversation,
          arguments: ConversationArguments(
            conversationId: conversationId,
            otherName: worker.name,
            otherImage: worker.image,
          ),
        );
      }
    } catch (_) {
      if (mounted)
        _showError(
          bilingual(context, 'Could not open chat.', 'چیٹ نہیں کھل سکی۔'),
        );
    } finally {
      if (mounted) setState(() => _openingChat = false);
    }
  }

  Future<void> _toggleFavourite(String workerId, bool isFavourite) async {
    if (_savingFavourite) return;
    setState(() => _savingFavourite = true);
    try {
      if (isFavourite) {
        await removeFavouriteWorker(workerId);
      } else {
        await addFavouriteWorker(workerId);
      }
    } catch (_) {
      if (mounted)
        _showError(
          bilingual(
            context,
            'Could not update favorites.',
            'پسندیدہ فہرست تبدیل نہیں ہو سکی۔',
          ),
        );
    } finally {
      if (mounted) setState(() => _savingFavourite = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return Directionality(
      textDirection: scope.isUrdu ? TextDirection.rtl : TextDirection.ltr,
      child: StreamBuilder<WorkerModel?>(
        stream: _profile,
        initialData: _initialWorker,
        builder: (context, snapshot) {
          final worker = snapshot.data;
          final id = worker?.id;
          final uid = FirebaseAuth.instance.currentUser?.uid;
          final peerId = uid == null || id == uid ? null : id;
          final isCustomer = scope.role == UserRole.customer;
          return Scaffold(
            backgroundColor: const Color(0xFFF9FAFB),
            appBar: AppBar(
              title: Text(bilingual(context, 'Worker Profile', 'ورکر پروفائل')),
              actions: [
                if (isCustomer && peerId != null)
                  StreamBuilder<List<String>>(
                    stream: _favourites,
                    builder: (context, snapshot) {
                      final isFavourite =
                          snapshot.data?.contains(peerId) ?? false;
                      return IconButton(
                        tooltip: isFavourite
                            ? bilingual(
                                context,
                                'Remove from favorites',
                                'پسندیدہ فہرست سے ہٹائیں',
                              )
                            : bilingual(
                                context,
                                'Add to favorites',
                                'پسندیدہ فہرست میں شامل کریں',
                              ),
                        icon: Icon(
                          isFavourite ? Icons.favorite : Icons.favorite_border,
                          color: isFavourite ? Colors.red : null,
                        ),
                        onPressed: _savingFavourite || !snapshot.hasData
                            ? null
                            : () => _toggleFavourite(peerId, isFavourite),
                      );
                    },
                  ),
              ],
            ),
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: worker == null
                    ? snapshot.connectionState == ConnectionState.waiting
                          ? const Center(child: CircularProgressIndicator())
                          : Padding(
                              padding: const EdgeInsets.all(20),
                              child: Text(
                                bilingual(
                                  context,
                                  'Could not load this worker profile.',
                                  'ورکر کا پروفائل لوڈ نہیں ہو سکا۔',
                                ),
                                textAlign: TextAlign.center,
                              ),
                            )
                    : _profileBody(context, worker, scope.isUrdu),
              ),
            ),
            bottomNavigationBar: worker != null && peerId != null
                ? SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _openingChat
                                ? null
                                : () => _openChat(worker),
                            icon: const Icon(Icons.chat_bubble_outline),
                            label: Text(bilingual(context, 'Chat', 'چیٹ')),
                          ),
                          if (isCustomer) ...[
                            const SizedBox(width: 12),
                            Flexible(
                              child: FilledButton.icon(
                                onPressed: worker.canRequestVisit
                                    ? () => Navigator.pushNamed(
                                        context,
                                        AppRoutes.requestVisit,
                                        arguments: worker,
                                      )
                                    : null,
                                icon: const Icon(
                                  Icons.event_available_outlined,
                                ),
                                label: Text(
                                  bilingual(
                                    context,
                                    'Request a Visit',
                                    'معائنے کی درخواست',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                : null,
          );
        },
      ),
    );
  }

  Widget _profileBody(BuildContext context, WorkerModel worker, bool isUrdu) {
    final name = worker.name.isNotEmpty
        ? worker.name
        : bilingual(context, 'Worker', 'ورکر');
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 42,
                  foregroundImage: worker.image.isNotEmpty
                      ? NetworkImage(worker.image)
                      : null,
                  onForegroundImageError: worker.image.isNotEmpty
                      ? (_, _) {}
                      : null,
                  child: Text(
                    name.characters.first,
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  name,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                Text(worker.categoryLabel(isUrdu)),
                if (worker.area.isNotEmpty) Text(worker.area),
                const SizedBox(height: 8),
                if (worker.isApproved)
                  Chip(
                    avatar: const Icon(Icons.verified_outlined, size: 18),
                    label: Text(
                      bilingual(context, 'Approved worker', 'منظور شدہ ورکر'),
                    ),
                  ),
                Text(
                  visitAvailabilityLabel(context, worker),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(
              bilingual(context, 'Inspection visits only', 'صرف معائنہ'),
            ),
            subtitle: Text(
              bilingual(
                context,
                'An inspection visit is free. Repair work is not included.',
                'معائنہ مفت ہے۔ مرمت کا کام شامل نہیں ہے۔',
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          bilingual(context, 'Customer Reviews', 'گاہکوں کے جائزے'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (worker.reviews > 0)
          Text('★ ${worker.rating.toStringAsFixed(1)} (${worker.reviews})'),
        const SizedBox(height: 8),
        StreamBuilder<QuerySnapshot>(
          stream: _reviews,
          builder: (context, snapshot) {
            if (snapshot.hasError)
              return Text(
                bilingual(
                  context,
                  'Could not load reviews.',
                  'جائزے لوڈ نہیں ہو سکے۔',
                ),
              );
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty)
              return Text(
                bilingual(context, 'No reviews yet.', 'ابھی کوئی جائزہ نہیں۔'),
              );
            return Column(
              children: [
                for (final doc in docs.take(6))
                  _review(context, doc.data() as Map<String, dynamic>),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _review(BuildContext context, Map<String, dynamic> data) {
    final name =
        data['customerName']?.toString() ??
        bilingual(context, 'Customer', 'گاہک');
    final rating = data['rating'];
    final review = data['review']?.toString() ?? '';
    final jobTitle = data['jobTitle']?.toString() ?? '';
    final date = data['createdAt'];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
            if (rating is num) Text('★ ${rating.toStringAsFixed(0)}/5'),
            if (review.isNotEmpty) Text(review),
            if (jobTitle.isNotEmpty)
              Text(jobTitle, style: Theme.of(context).textTheme.bodySmall),
            if (date is Timestamp)
              Text(
                MaterialLocalizations.of(
                  context,
                ).formatMediumDate(date.toDate()),
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }
}
