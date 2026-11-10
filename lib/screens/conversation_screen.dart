import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:url_launcher/url_launcher.dart';

import '../app_state.dart';
import '../data/mock_data.dart' show WorkerModel;
import '../services/workers_service.dart';
import 'mazdoor_flow.dart'
    show
        bilingual,
        showToast,
        showExitMazdoorlinkDialog,
        MzScaffold,
        AppRoutes,
        ConversationArguments,
        ProfileArguments,
        JobPostingArguments;

class ChatHistoryScreen extends StatefulWidget {
  const ChatHistoryScreen({super.key});
  @override
  State<ChatHistoryScreen> createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends State<ChatHistoryScreen> {
  String _conversationPreview(
    BuildContext context,
    Map<String, dynamic> data,
    String lastMsg,
  ) {
    if (lastMsg.isEmpty) {
      return bilingual(context, 'Say hello to start', 'سلام کہہ کر شروع کریں');
    }
    final lastEn = data['lastMessageEn'] as String? ?? '';
    final lastUr = data['lastMessageUr'] as String? ?? '';
    if (AppScope.of(context).isUrdu) {
      return lastUr.isNotEmpty ? lastUr : lastMsg;
    }
    return lastEn.isNotEmpty ? lastEn : lastMsg;
  }

  @override
  Widget build(BuildContext context) {
    return MzScaffold(
      showBack: true,
      showBottomNav: true,
      title: bilingual(context, 'Chat History', 'چیٹ ہسٹری'),
      child: StreamBuilder<QuerySnapshot>(
        stream: streamConversations(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.amber),
                    const SizedBox(height: 12),
                    Text(
                      bilingual(
                        context,
                        'Could not load conversations. Please try again.',
                        'گفتگو لوڈ نہیں ہو سکی۔ براہ کرم دوبارہ کوشش کریں۔',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          final rawDocs = snapshot.data?.docs ?? [];
          final conversations = rawDocs.toList()
            ..sort((a, b) {
              final aData = a.data() as Map<String, dynamic>?;
              final bData = b.data() as Map<String, dynamic>?;
              final aTime = aData?['lastTimestamp'] as Timestamp? ?? aData?['createdAt'] as Timestamp?;
              final bTime = bData?['lastTimestamp'] as Timestamp? ?? bData?['createdAt'] as Timestamp?;
              if (aTime == null && bTime == null) return 0;
              if (aTime == null) return 1;
              if (bTime == null) return -1;
              return bTime.compareTo(aTime);
            });
          if (conversations.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  bilingual(
                    context,
                    'No conversations yet. Start a chat with a worker to see it here.',
                    'ابھی تک کوئی گفتگو نہیں۔ کسی ورکر کے ساتھ چیٹ شروع کریں۔',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: conversations.length,
            itemBuilder: (_, i) {
              final doc = conversations[i];
              final data = doc.data() as Map<String, dynamic>;
              final participants = List<String>.from(
                data['participants'] ?? [],
              );
              final participantNames =
                  data['participantNames'] as Map<String, dynamic>?;
              final participantImages =
                  data['participantImages'] as Map<String, dynamic>?;
              final lastMsg = data['lastMessage'] as String? ?? '';
              final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
              final otherId =
                  participants.where((p) => p != currentUid).firstOrNull ?? '';
              final rawName = participantNames?[otherId] as String? ?? '';
              final rawImage = participantImages?[otherId] as String? ?? '';
              final unreadCounts =
                  data['unreadCounts'] as Map<String, dynamic>?;
              final unread = (unreadCounts?[currentUid] as num?)?.toInt() ?? 0;

              final isGeneric = rawName.trim().isEmpty ||
                  rawName.trim().toLowerCase() == 'user' ||
                  rawName.trim().toLowerCase() == 'customer' ||
                  rawName.trim() == 'صارف';

              Widget buildTile(String displayName, String displayImage) {
                final safeName = displayName.trim().isNotEmpty
                    ? displayName
                    : bilingual(context, 'User', 'صارف');
                final hasImage = displayImage.isNotEmpty;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF0D9488).withOpacity(0.15),
                    backgroundImage: hasImage ? NetworkImage(displayImage) : null,
                    child: hasImage
                        ? null
                        : Text(
                            safeName.isNotEmpty
                                ? safeName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D9488),
                            ),
                          ),
                  ),
                  title: Text(
                    safeName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    _conversationPreview(context, data, lastMsg),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: unread > 0
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D9488),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            unread > 99 ? '99+' : '$unread',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: Colors.grey,
                        ),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.sharedConversation,
                      arguments: ConversationArguments(
                        conversationId: doc.id,
                        otherName: safeName,
                        otherImage: displayImage,
                      ),
                    );
                  },
                );
              }

              if (otherId.isNotEmpty && isGeneric) {
                return StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(otherId)
                      .snapshots(),
                  builder: (context, userSnap) {
                    final uData =
                        userSnap.data?.data() as Map<String, dynamic>?;
                    final realName = uData?['name']?.toString() ??
                        uData?['fullName']?.toString() ??
                        uData?['displayName']?.toString() ??
                        '';
                    final realImage = uData?['profileImage']?.toString() ??
                        uData?['profilePicUrl']?.toString() ??
                        uData?['photoUrl']?.toString() ??
                        '';
                    return buildTile(
                      realName.isNotEmpty ? realName : rawName,
                      realImage.isNotEmpty ? realImage : rawImage,
                    );
                  },
                );
              }

              return buildTile(rawName, rawImage);
            },
          );
        },
      ),
    );
  }
}

class ConversationScreen extends StatefulWidget {
  final String conversationId;
  final String otherName;
  final String? otherImage;
  const ConversationScreen({
    super.key,
    required this.conversationId,
    required this.otherName,
    this.otherImage,
  });
  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  String _otherId = '';
  String? _otherName;
  String? _otherImage;
  Map<String, dynamic>? _otherUserData;
  StreamSubscription<DocumentSnapshot>? _otherUserSub;

  bool _otherOnline = false;
  bool _otherTyping = false;
  bool _isTyping = false;
  bool _sending = false;
  bool? _showUrduOverride;
  bool get _showUrdu => _showUrduOverride ?? AppScope.of(context).isUrdu;
  int _lastMsgCount = 0;

  StreamSubscription<DocumentSnapshot>? _convSub;
  StreamSubscription<DocumentSnapshot>? _presenceSub;
  Timer? _typingTimer;
  Timer? _typingHeartbeat;
  Timer? _presenceHeartbeat;
  Timer? _markReadDebounce;

  String get _displayName {
    final name = _otherName?.trim() ?? '';
    if (name.isNotEmpty &&
        name.toLowerCase() != 'user' &&
        name.toLowerCase() != 'customer' &&
        name != 'صارف') {
      return name;
    }
    final wName = widget.otherName.trim();
    if (wName.isNotEmpty &&
        wName.toLowerCase() != 'user' &&
        wName.toLowerCase() != 'customer' &&
        wName != 'صارف') {
      return wName;
    }
    return bilingual(context, 'User', 'صارف');
  }

  String get _displayImage {
    if (_otherImage != null && _otherImage!.isNotEmpty) {
      return _otherImage!;
    }
    return widget.otherImage ?? '';
  }

  @override
  void initState() {
    super.initState();
    _otherName = widget.otherName;
    _otherImage = widget.otherImage;
    setPresence(online: true);
    _presenceHeartbeat = Timer.periodic(
      const Duration(seconds: 30),
      (_) => setPresence(online: true),
    );
    _listenConversation();
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _typingHeartbeat?.cancel();
    _presenceHeartbeat?.cancel();
    _markReadDebounce?.cancel();
    _convSub?.cancel();
    _presenceSub?.cancel();
    _otherUserSub?.cancel();
    setPresence(online: false);
    if (_isTyping) setTyping(widget.conversationId, false);
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _listenConversation() {
    _convSub = FirebaseFirestore.instance
        .collection('conversations')
        .doc(widget.conversationId)
        .snapshots()
        .listen((doc) {
          if (!mounted) return;
          final data = doc.data() ?? const {};
          final me = FirebaseAuth.instance.currentUser?.uid ?? '';
          final otherId =
              List<String>.from(
                data['participants'] ?? [],
              ).where((p) => p != me).firstOrNull ??
              '';
          setState(() {
            if (otherId.isNotEmpty && otherId != _otherId) {
              _otherId = otherId;
              _presenceSub?.cancel();
              _presenceSub = streamPresence(otherId).listen((p) {
                if (!mounted) return;
                setState(
                  () => _otherOnline = _isOnline(
                    p.data() as Map<String, dynamic>?,
                  ),
                );
              });
              _subscribeOtherUser(otherId);
            }
            final typingMap = Map<String, dynamic>.from(
              data['typing'] as Map? ?? {},
            );
            _otherTyping = _isTypingFresh(typingMap[otherId]);
          });
          final unread = Map<String, dynamic>.from(
            data['unreadCounts'] as Map? ?? {},
          );
          if (((unread[me] as num?)?.toInt() ?? 0) > 0) {
            _scheduleMarkRead();
          }
        });
  }

  void _subscribeOtherUser(String otherId) {
    _otherUserSub?.cancel();
    _otherUserSub = FirebaseFirestore.instance
        .collection('users')
        .doc(otherId)
        .snapshots()
        .listen((snap) {
      if (!mounted) return;
      final data = snap.data();
      if (data != null) {
        final realName = data['name']?.toString() ??
            data['fullName']?.toString() ??
            data['displayName']?.toString() ??
            '';
        final realImage = data['profileImage']?.toString() ??
            data['profilePicUrl']?.toString() ??
            data['photoUrl']?.toString() ??
            '';
        setState(() {
          _otherUserData = data;
          if (realName.isNotEmpty) {
            _otherName = realName;
          }
          if (realImage.isNotEmpty) {
            _otherImage = realImage;
          }
        });

        if (realName.isNotEmpty &&
            realName.toLowerCase() != 'user' &&
            realName.toLowerCase() != 'customer' &&
            realName != 'صارف') {
          FirebaseFirestore.instance
              .collection('conversations')
              .doc(widget.conversationId)
              .set({
            'participantNames': {otherId: realName},
            if (realImage.isNotEmpty) 'participantImages': {otherId: realImage},
          }, SetOptions(merge: true)).catchError((_) {});
        }
      }
    });
  }

  Future<void> _openOtherUserProfile() async {
    if (_otherId.isEmpty) return;

    Map<String, dynamic>? data = _otherUserData;
    if (data == null) {
      try {
        final snap = await FirebaseFirestore.instance
            .collection('users')
            .doc(_otherId)
            .get();
        data = snap.data();
      } catch (_) {}
    }

    if (!mounted) return;
    if (data == null) {
      showToast(
        bilingual(
          context,
          'User profile details not available',
          'صارف کے پروفائل کی تفصیلات دستیاب نہیں ہیں',
        ),
      );
      return;
    }

    final role = (data['role']?.toString() ?? '').toLowerCase();
    final isWorker = role == 'worker' ||
        data.containsKey('category') ||
        data.containsKey('categoryKey') ||
        data.containsKey('skills');

    if (isWorker) {
      final worker = WorkerModel.fromFirestore(data, docId: _otherId);
      Navigator.pushNamed(
        context,
        AppRoutes.workerProfile,
        arguments: ProfileArguments(
          worker: worker,
          job: JobPostingArguments(
            descriptionEn: '',
            descriptionUr: '',
            price: 0,
            categoryKey: worker.category,
          ),
        ),
      );
    } else {
      _showCustomerProfileSheet(context, data);
    }
  }

  void _showCustomerProfileSheet(BuildContext context, Map<String, dynamic> data) {
    final name = _displayName;
    final phone = data['phone']?.toString() ?? '';
    final email = data['email']?.toString() ?? '';
    final totalJobs = (data['completedJobs'] as num?)?.toInt() ?? 0;
    final address = data['address']?.toString() ?? data['city']?.toString() ?? '';
    final hasImg = _displayImage.isNotEmpty;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              CircleAvatar(
                radius: 36,
                backgroundColor: const Color(0xFF0D9488).withOpacity(0.15),
                backgroundImage: hasImg ? NetworkImage(_displayImage) : null,
                child: hasImg
                    ? null
                    : Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D9488),
                        ),
                      ),
              ),
              const SizedBox(height: 12),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D9488).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.person,
                      size: 14,
                      color: Color(0xFF0D9488),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      bilingual(context, 'Customer', 'گاہک'),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0D9488),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),
              if (phone.isNotEmpty)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE0F2FE),
                    child: Icon(Icons.phone, color: Color(0xFF0284C7), size: 20),
                  ),
                  title: Text(
                    bilingual(context, 'Phone Number', 'فون نمبر'),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  subtitle: Text(
                    phone,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.call, color: Color(0xFF0D9488)),
                    tooltip: bilingual(context, 'Call', 'کال کریں'),
                    onPressed: () async {
                      final uri = Uri(scheme: 'tel', path: phone);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    },
                  ),
                ),
              if (email.isNotEmpty)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFEF3C7),
                    child: Icon(Icons.email, color: Color(0xFFD97706), size: 20),
                  ),
                  title: Text(
                    bilingual(context, 'Email', 'ای میل'),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  subtitle: Text(
                    email,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              if (address.isNotEmpty)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFF3E8FF),
                    child: Icon(Icons.location_on, color: Color(0xFF7E22CE), size: 20),
                  ),
                  title: Text(
                    bilingual(context, 'Location', 'مقام'),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  subtitle: Text(
                    address,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              if (totalJobs > 0)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFDCFCE7),
                    child: Icon(Icons.work, color: Color(0xFF16A34A), size: 20),
                  ),
                  title: Text(
                    bilingual(context, 'Completed Jobs', 'مکمل شدہ کام'),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  subtitle: Text(
                    '$totalJobs ${bilingual(context, 'jobs', 'کام')}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(bilingual(context, 'Close', 'بند کریں')),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  bool _isOnline(Map<String, dynamic>? data) {
    if (data == null || data['online'] != true) return false;
    final last = data['lastSeen'];
    if (last is Timestamp) {
      return DateTime.now().difference(last.toDate()).inMinutes < 2;
    }
    return false;
  }

  bool _isTypingFresh(Object? t) {
    if (t is Timestamp) {
      return DateTime.now().difference(t.toDate()).inSeconds < 10;
    }
    return false;
  }

  void _scheduleMarkRead() {
    _markReadDebounce?.cancel();
    _markReadDebounce = Timer(const Duration(milliseconds: 600), () {
      markConversationRead(widget.conversationId);
    });
  }

  void _onTypingChanged() {
    if (_msgCtrl.text.trim().isEmpty) {
      _stopTyping();
      return;
    }
    if (!_isTyping) {
      _isTyping = true;
      setTyping(widget.conversationId, true);
    }
    _typingHeartbeat?.cancel();
    _typingHeartbeat = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_isTyping && _msgCtrl.text.trim().isNotEmpty) {
        setTyping(widget.conversationId, true);
      }
    });
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 5), _stopTyping);
  }

  void _stopTyping() {
    _typingTimer?.cancel();
    _typingHeartbeat?.cancel();
    if (_isTyping) {
      _isTyping = false;
      setTyping(widget.conversationId, false);
    }
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    await sendMessage(widget.conversationId, text);
    if (!mounted) return;
    setState(() => _sending = false);
    _msgCtrl.clear();
    _stopTyping();
  }

  void _onMessagesChanged(int count) {
    if (count > _lastMsgCount && count > 0) {
      _lastMsgCount = count;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scrollCtrl.hasClients) {
          _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
        }
      });
    } else {
      _lastMsgCount = count;
    }
  }

  String _formatTime(Timestamp? ts) {
    if (ts == null) return '';
    return DateFormat('hh:mm a').format(ts.toDate().toLocal());
  }

  Widget _buildJobScheduleBanner(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (me.isEmpty || _otherId.isEmpty) return const SizedBox.shrink();

    final isCustomer = AppScope.of(context).role == UserRole.customer;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('jobs')
          .where(isCustomer ? 'customerId' : 'workerId', isEqualTo: me)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final docs = snapshot.data!.docs;
        QueryDocumentSnapshot? jobDoc;
        for (final doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final otherMatch =
              (isCustomer ? data['workerId'] : data['customerId']) == _otherId;
          if (otherMatch && data['status'] == 'scheduled') {
            jobDoc = doc;
            break;
          }
        }

        if (jobDoc == null) return const SizedBox.shrink();

        final data = jobDoc.data() as Map<String, dynamic>;
        final isConfirmed = data['scheduleConfirmed'] as bool? ?? false;
        final scheduledRaw = data['scheduledReminderAt'];
        String timeStr = '';
        if (scheduledRaw is Timestamp) {
          timeStr = DateFormat('hh:mm a, d MMM').format(scheduledRaw.toDate());
        }
        final price = data['price'];
        final priceStr = price != null
            ? 'Rs. ${(price as num).toStringAsFixed(0)}'
            : '';
        final isUrdu = AppScope.of(context).isUrdu;
        final title = isUrdu
            ? (data['descriptionUr']?.toString() ??
                  data['categoryKey']?.toString() ??
                  'کام')
            : (data['descriptionEn']?.toString() ??
                  data['categoryKey']?.toString() ??
                  'Job');

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isConfirmed
                ? const Color(0xFFF0FDF4)
                : const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isConfirmed
                  ? const Color(0xFF22C55E)
                  : const Color(0xFFF59E0B),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isConfirmed
                          ? const Color(0xFFDCFCE7)
                          : const Color(0xFFFDE68A),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isConfirmed ? Icons.check_circle : Icons.schedule,
                      size: 18,
                      color: isConfirmed
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFB45309),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (timeStr.isNotEmpty)
                          Text(
                            timeStr,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isConfirmed
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFF92400E),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (priceStr.isNotEmpty)
                    Text(
                      priceStr,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Color(0xFF0D9488),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (isConfirmed) ...[
                Row(
                  children: [
                    const Icon(
                      Icons.verified,
                      size: 14,
                      color: Color(0xFF16A34A),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      bilingual(
                        context,
                        'Schedule Confirmed',
                        'شیڈول منظور شدہ',
                      ),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                if (isCustomer) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          bilingual(
                            context,
                            'Worker proposed this schedule. Accept when ready:',
                            'ورکر نے یہ وقت تجویز کیا ہے۔ تیار ہونے پر منظور کریں:',
                          ),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF92400E),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF0D9488),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: const Icon(Icons.check, size: 14),
                        label: Text(
                          bilingual(context, 'Accept', 'منظور کریں'),
                          style: const TextStyle(fontSize: 12),
                        ),
                        onPressed: () async {
                          final currentJobId = jobDoc!.id;
                          await acceptScheduledJob(currentJobId);
                          await sendMessage(
                            widget.conversationId,
                            'I have accepted the scheduled time: $timeStr.',
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  bilingual(
                                    context,
                                    'Schedule accepted successfully!',
                                    'شیڈول کامیابی سے منظور ہو گیا!',
                                  ),
                                ),
                                backgroundColor: const Color(0xFF0D9488),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ] else ...[
                  Row(
                    children: [
                      const Icon(
                        Icons.hourglass_top,
                        size: 14,
                        color: Color(0xFFB45309),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          bilingual(
                            context,
                            'Waiting for customer to accept schedule...',
                            'گاہک کی جانب سے شیڈول قبول کرنے کا انتظار...',
                          ),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF92400E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MzScaffold(
      showBack: true,
      showBottomNav: false,
      titleWidget: _buildHeader(context),
      child: Column(
        children: [
          _buildJobScheduleBanner(context),
          Expanded(child: _buildMessages(context)),
          if (_otherTyping) _buildTypingBanner(context),
          _buildInput(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final displayName = _displayName;
    final displayImage = _displayImage;
    final hasImage = displayImage.isNotEmpty;

    return InkWell(
      onTap: _otherId.isNotEmpty ? _openOtherUserProfile : null,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFF0D9488).withOpacity(0.15),
                  backgroundImage: hasImage
                      ? NetworkImage(displayImage)
                      : null,
                  child: hasImage
                      ? null
                      : Text(
                          displayName.isNotEmpty
                              ? displayName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D9488),
                          ),
                        ),
                ),
                if (_otherId.isNotEmpty)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _otherOnline
                            ? const Color(0xFF22C55E)
                            : Colors.grey.shade400,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.info_outline,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                    ],
                  ),
                  Text(
                    _otherId.isEmpty
                        ? ''
                        : (_otherOnline
                            ? bilingual(context, 'Online', 'آن لائن')
                            : bilingual(context, 'Offline', 'آف لائن')),
                    style: TextStyle(
                      fontSize: 12,
                      color: _otherOnline ? const Color(0xFF22C55E) : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessages(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: streamMessages(widget.conversationId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                bilingual(
                  context,
                  'Failed to load messages. Please check your connection.',
                  'پیغامات لوڈ کرنے میں ناکامی۔ براہ کرم اپنا کنکشن چیک کریں۔',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }
        final rawDocs = snapshot.data?.docs ?? [];
        final docs = rawDocs.toList()
          ..sort((a, b) {
            final aData = a.data() as Map<String, dynamic>?;
            final bData = b.data() as Map<String, dynamic>?;
            final aTime = aData?['timestamp'] as Timestamp?;
            final bTime = bData?['timestamp'] as Timestamp?;
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return aTime.compareTo(bTime);
          });
        _onMessagesChanged(docs.length);
        if (docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                bilingual(
                  context,
                  'Say hello to start the conversation',
                  'گفتگو شروع کرنے کے لیے سلام کہیں',
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return ListView.builder(
          controller: _scrollCtrl,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          itemCount: docs.length,
          itemBuilder: (_, i) =>
              _buildBubble(context, docs[i].data() as Map<String, dynamic>),
        );
      },
    );
  }

  Widget _buildBubble(BuildContext context, Map<String, dynamic> data) {
    final me = FirebaseAuth.instance.currentUser?.uid ?? '';
    final senderId = data['senderId'] as String? ?? '';
    final raw = data['text'] as String? ?? '';
    final textUr = data['textUr'] as String? ?? '';
    final textEn = data['textEn'] as String? ?? '';
    final text = _showUrdu
        ? (textUr.isNotEmpty ? textUr : raw)
        : (textEn.isNotEmpty ? textEn : raw);
    final isMe = senderId == me;
    final ts = data['timestamp'] as Timestamp?;
    final readBy = List<String>.from(data['readBy'] as List? ?? []);
    final isRead = isMe && _otherId.isNotEmpty && readBy.contains(_otherId);
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: const BoxConstraints(maxWidth: 300),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF0D9488) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(ts),
                  style: TextStyle(
                    color: isMe ? Colors.white70 : Colors.black45,
                    fontSize: 10,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    isRead ? Icons.done_all : Icons.done,
                    size: 14,
                    color: isRead ? const Color(0xFFA7F3D0) : Colors.white70,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingBanner(BuildContext context) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF0D9488),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$_displayName ${bilingual(context, 'is typing...', 'ٹائپ کر رہے ہیں...')}',
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => setState(() => _showUrduOverride = !_showUrdu),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Text(
                _showUrdu ? 'UR' : 'EN',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1D4ED8),
                ),
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: _msgCtrl,
              textInputAction: TextInputAction.send,
              onChanged: (_) => _onTypingChanged(),
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                hintText: bilingual(
                  context,
                  'Type a message...',
                  'پیغام لکھیں...',
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _sending
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Color(0xFF0D9488),
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFF0D9488)),
                  onPressed: _send,
                ),
        ],
      ),
    );
  }
}
