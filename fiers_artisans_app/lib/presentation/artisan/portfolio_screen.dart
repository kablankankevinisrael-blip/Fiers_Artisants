import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../common/empty_state.dart';

class PortfolioScreen extends StatelessWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('portfolio.title'.tr())),
      body: EmptyState(
        icon: Icons.photo_library_outlined,
        title: 'portfolio.empty'.tr(),
        actionLabel: 'portfolio.add'.tr(),
        onAction: () {
          // TODO: Navigate to add portfolio item
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to add portfolio item
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}
