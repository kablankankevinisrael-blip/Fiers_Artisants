import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../common/empty_state.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('notifications.title'.tr())),
      body: EmptyState(
        icon: Icons.notifications_none_rounded,
        title: 'notifications.empty'.tr(),
      ),
    );
  }
}
