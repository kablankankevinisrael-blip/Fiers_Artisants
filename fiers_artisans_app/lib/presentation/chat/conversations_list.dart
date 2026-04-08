import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../providers/chat_provider.dart';
import '../../core/utils/formatters.dart';
import '../common/empty_state.dart';

class ConversationsListScreen extends ConsumerStatefulWidget {
  const ConversationsListScreen({super.key});

  @override
  ConsumerState<ConversationsListScreen> createState() =>
      _ConversationsListScreenState();
}

class _ConversationsListScreenState
    extends ConsumerState<ConversationsListScreen> {
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(chatProvider.notifier).loadConversations();
      _startPolling();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted) return;
      if (ref.read(chatProvider).authRequired) return;
      ref.read(chatProvider.notifier).loadConversations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chatState = ref.watch(chatProvider);

    if (chatState.authRequired) {
      return Scaffold(
        appBar: AppBar(title: Text('chat.title'.tr())),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 34),
                const SizedBox(height: 12),
                Text(
                  'Session expiree. Veuillez vous reconnecter.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Se reconnecter'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('chat.title'.tr())),
      body: chatState.conversations.isEmpty
          ? EmptyState(
              icon: Icons.chat_bubble_outline,
              title: chatState.errorMessage ?? 'chat.empty'.tr(),
            )
          : ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: chatState.conversations.length,
              itemBuilder: (context, index) {
                final convo = chatState.conversations[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        theme.colorScheme.primary.withValues(alpha: 0.2),
                    child: Text(
                      convo.participantName.isNotEmpty
                          ? convo.participantName[0].toUpperCase()
                          : '?',
                      style: TextStyle(color: theme.colorScheme.primary),
                    ),
                  ),
                  title: Text(convo.participantName,
                      style: theme.textTheme.titleMedium),
                  subtitle: convo.lastMessage != null
                      ? Text(
                          Formatters.truncate(convo.lastMessage!, 40),
                          style: theme.textTheme.bodySmall,
                        )
                      : null,
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (convo.lastMessageAt != null)
                        Text(
                          Formatters.relativeDate(convo.lastMessageAt!),
                          style: theme.textTheme.labelSmall,
                        ),
                      if (convo.unreadCount > 0) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${convo.unreadCount}',
                            style: const TextStyle(
                                color: Colors.black, fontSize: 11),
                          ),
                        ),
                      ],
                    ],
                  ),
                  onTap: () => context.push('/chat/${convo.id}'),
                );
              },
            ),
    );
  }
}
