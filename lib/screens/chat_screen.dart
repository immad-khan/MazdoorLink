import 'package:flutter/material.dart';
import 'package:service_frontend/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../services/translation_service.dart';

class ChatMessage {
  final String textEn;
  final String textUr;
  final bool isFromMe;
  final DateTime timestamp;

  ChatMessage({
    required this.textEn,
    required this.textUr,
    required this.isFromMe,
    required this.timestamp,
  });
}

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final _controller = TextEditingController();
  final _translationService = TranslationService();
  final _scrollController = ScrollController();
  bool _translate = true;
  bool _showTranslation = true;
  late List<ChatMessage> _messages;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController =
        AnimationController(duration: Duration(milliseconds: 300), vsync: this);

    // Sample messages for demo
    _messages = [
      ChatMessage(
        textEn: 'Hi, I need Plumber repair',
        textUr: 'السلام علیکم، مجھے پلمبنگ کی مرمت کی ضرورت ہے',
        isFromMe: true,
        timestamp: DateTime.now().subtract(Duration(minutes: 5)),
      ),
      ChatMessage(
        textEn: 'I can help with that. What is the issue?',
        textUr: 'میں اس میں مدد کر سکتا ہوں۔ مسئلہ کیا ہے؟',
        isFromMe: false,
        timestamp: DateTime.now().subtract(Duration(minutes: 4)),
      ),
      ChatMessage(
        textEn: 'Water is leaking from the main tap',
        textUr: 'پانی مرکزی نل سے بہہ رہا ہے',
        isFromMe: true,
        timestamp: DateTime.now().subtract(Duration(minutes: 3)),
      ),
      ChatMessage(
        textEn: 'I can come tomorrow at 10 AM',
        textUr: 'میں کل صبح 10 بجے آ سکتا ہوں',
        isFromMe: false,
        timestamp: DateTime.now().subtract(Duration(minutes: 2)),
      ),
    ];
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    String urduText = text;
    if (_translate) {
      try {
        urduText = await _translationService.translate(
          text: text,
          sourceLang: 'en',
          targetLang: 'ur',
        );
      } catch (e) {
        urduText = text; // Fallback to English if translation fails
      }
    }

    setState(() {
      _messages.add(ChatMessage(
        textEn: text,
        textUr: urduText,
        isFromMe: true,
        timestamp: DateTime.now(),
      ));
    });

    _controller.clear();
    _fadeController.forward(from: 0);

    Future.delayed(Duration(milliseconds: 300), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Widget _buildMessageBubble(ChatMessage message, int index) {
    final isRtl = Localizations.localeOf(context).languageCode == 'ur';

    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1).animate(_fadeController),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Column(
          crossAxisAlignment:
              message.isFromMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Main message bubble
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isFromMe
                    ? Theme.of(context).primaryColor
                    : AppTheme.notWhite,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: message.isFromMe
                      ? Radius.circular(16)
                      : Radius.circular(4),
                  bottomRight: message.isFromMe
                      ? Radius.circular(4)
                      : Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha:0.08),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Primary text
                  Text(
                    message.textEn,
                    style: TextStyle(
                      fontSize: 15,
                      color: message.isFromMe ? Colors.white : AppTheme.darkerText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  // Translation if enabled
                  if (_showTranslation && message.textEn != message.textUr)
                    Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: message.isFromMe
                              ? Colors.white.withValues(alpha:0.2)
                              : (isRtl
                                  ? AppTheme.spacer
                                  : Colors.transparent),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          message.textUr,
                          style: TextStyle(
                            fontSize: 13,
                            color: message.isFromMe
                                ? Colors.white.withValues(alpha:0.9)
                                : AppTheme.lightText,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w400,
                          ),
                          textDirection:
                              isRtl ? TextDirection.rtl : TextDirection.ltr,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: 4),
            // Timestamp
            Text(
              _formatTime(message.timestamp),
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.deactivatedText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return 'now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${time.month}/${time.day}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = Localizations.localeOf(context).languageCode == 'ur';
    final t = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 1,
        backgroundColor: Theme.of(context).primaryColor,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Muhammad Ali',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              'Plumber • Online',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha:0.7),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() => _showTranslation = !_showTranslation);
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Icon(
                  _showTranslation ? Icons.translate : Icons.language,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Calling worker...')),
                );
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.call, color: Colors.white, size: 24),
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('More options opened')),
                );
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.more_vert, color: Colors.white, size: 24),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(vertical: 12),
              itemCount: _messages.length,
              itemBuilder: (context, index) =>
                  _buildMessageBubble(_messages[index], index),
            ),
          ),
          // Translation Banner
          if (_showTranslation)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: Color(0xFFF0F9FF),
              child: Row(
                children: [
                  Icon(Icons.info, color: Color(0xFF3B82F6), size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Messages are auto-translated for clarity',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF1E40AF),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Input Area
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppTheme.spacer)),
            ),
            child: Row(
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() => _translate = !_translate);
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(
                        Icons.mic,
                        color: _translate
                            ? Theme.of(context).primaryColor
                            : AppTheme.deactivatedText,
                        size: 24,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.notWhite,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppTheme.spacer),
                    ),
                    child: TextField(
                      controller: _controller,
                      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: _translate
                            ? t.t('type_auto_translate')
                            : t.t('type'),
                        hintStyle: TextStyle(color: AppTheme.deactivatedText),
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _send,
                    borderRadius: BorderRadius.circular(24),
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(
                        Icons.send,
                        color: Theme.of(context).primaryColor,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
