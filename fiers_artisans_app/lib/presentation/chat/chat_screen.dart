import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../config/constants.dart';
import '../../data/models/message_model.dart';
import '../../providers/chat_provider.dart';
import '../../core/storage/secure_storage.dart';
import '../../core/utils/formatters.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;
  const ChatScreen({super.key, required this.conversationId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      _currentUserId = await SecureStorage.getUserId();
      if (!mounted) return;
      setState(() {});
      final notifier = ref.read(chatProvider.notifier);
      await notifier.loadMessages(widget.conversationId);
      notifier.markAsRead(widget.conversationId);
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chatState = ref.watch(chatProvider);
    final messages = chatState.messages;

    return Scaffold(
      appBar: AppBar(
        title: Text('chat.title'.tr()),
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Text('Aucun message',
                        style: theme.textTheme.bodySmall))
                : ListView.builder(
                    controller: _scrollCtrl,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isMine = msg.senderId == _currentUserId;
                      return Align(
                        alignment: isMine
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: AnimatedSlide(
                          offset: Offset.zero,
                          duration: AppConstants.animFast,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.75,
                            ),
                            decoration: BoxDecoration(
                              color: isMine
                                  ? theme.colorScheme.primary
                                  : theme.cardTheme.color,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft:
                                    Radius.circular(isMine ? 16 : 4),
                                bottomRight:
                                    Radius.circular(isMine ? 4 : 16),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  msg.content,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color:
                                        isMine ? Colors.black : null,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  Formatters.relativeDate(msg.createdAt),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isMine
                                        ? Colors.black54
                                        : theme.textTheme.bodySmall?.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Message input
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              border: Border(top: BorderSide(color: theme.dividerColor)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageCtrl,
                      decoration: InputDecoration(
                        hintText: 'chat.type_message'.tr(),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send_rounded,
                        color: theme.colorScheme.primary),
                    onPressed: _send,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _send() {
    final text = _messageCtrl.text.trim();
    if (text.isEmpty || _currentUserId == null) return;
    _messageCtrl.clear();

    // Optimistic: add message to local list immediately
    final optimistic = MessageModel(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: widget.conversationId,
      senderId: _currentUserId!,
      content: text,
      createdAt: DateTime.now(),
    );
    ref.read(chatProvider.notifier).addMessage(optimistic);
    _scrollToBottom();

    // Send via REST (fire-and-forget, optimistic message already shown)
    ref
        .read(chatProvider.notifier)
        .sendMessage(
          conversationId: widget.conversationId,
          content: text,
        )
        .ignore();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }
}
