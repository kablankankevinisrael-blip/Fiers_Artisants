import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/theme.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../data/models/portfolio_model.dart';
import '../../data/repositories/artisan_repository.dart';
import '../common/empty_state.dart';
import 'package:dio/dio.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  final ArtisanRepository _repo = ArtisanRepository();
  final ApiClient _api = ApiClient();

  List<PortfolioModel> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPortfolio();
  }

  Future<void> _loadPortfolio() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await _api.get(ApiEndpoints.portfolio);
      final list =
          response.data is List ? response.data : response.data['data'] ?? [];
      setState(() {
        _items =
            (list as List).map((e) => PortfolioModel.fromJson(e)).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _showAddDialog() async {
    final result = await showModalBottomSheet<_AddPortfolioResult>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => const _AddPortfolioSheet(),
    );
    if (result == null) return;

    setState(() => _loading = true);
    try {
      // Upload images
      final imageUrls = <String>[];
      for (final path in result.imagePaths) {
        final formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(path),
        });
        final uploadResponse = await _api.dio.post(
          ApiEndpoints.upload,
          data: formData,
          queryParameters: {'bucket': 'portfolio'},
        );
        imageUrls.add(uploadResponse.data['url'] as String);
      }

      // Create portfolio item
      await _repo.addPortfolioItem(
        title: result.title,
        description: result.description,
        price: result.price,
        imageUrls: imageUrls,
      );
      await _loadPortfolio();
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('portfolio.add_error'.tr()),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteItem(PortfolioModel item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('portfolio.delete_confirm_title'.tr()),
        content: Text('portfolio.delete_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('common.delete'.tr(),
                style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _api.delete('${ApiEndpoints.portfolio}/${item.id}');
      await _loadPortfolio();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('portfolio.delete_error'.tr()),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('portfolio.title'.tr())),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('error.generic'.tr()),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: _loadPortfolio,
                        child: Text('common.retry'.tr()),
                      ),
                    ],
                  ),
                )
              : _items.isEmpty
                  ? EmptyState(
                      icon: Icons.photo_library_outlined,
                      title: 'portfolio.empty'.tr(),
                      actionLabel: 'portfolio.add'.tr(),
                      onAction: _showAddDialog,
                    )
                  : RefreshIndicator(
                      onRefresh: _loadPortfolio,
                      child: GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          return _PortfolioCard(
                            item: item,
                            onDelete: () => _deleteItem(item),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: theme.colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}

// ─── Portfolio card widget ───────────────────────────────────
class _PortfolioCard extends StatelessWidget {
  final PortfolioModel item;
  final VoidCallback onDelete;

  const _PortfolioCard({required this.item, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: item.imageUrls.isNotEmpty
                ? Image.network(
                    item.imageUrls.first,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, e, s) => Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.broken_image_outlined, size: 40),
                    ),
                  )
                : Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const Center(
                      child: Icon(Icons.photo_outlined, size: 40),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: theme.textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.price != null)
                  Text(
                    '${item.price!.toInt()} FCFA',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: Icon(Icons.delete_outline, size: 18, color: AppTheme.error),
              onPressed: onDelete,
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Add portfolio item bottom sheet ─────────────────────────
class _AddPortfolioResult {
  final String title;
  final String? description;
  final double? price;
  final List<String> imagePaths;

  _AddPortfolioResult({
    required this.title,
    this.description,
    this.price,
    required this.imagePaths,
  });
}

class _AddPortfolioSheet extends StatefulWidget {
  const _AddPortfolioSheet();

  @override
  State<_AddPortfolioSheet> createState() => _AddPortfolioSheetState();
}

class _AddPortfolioSheetState extends State<_AddPortfolioSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final List<String> _imagePaths = [];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage(imageQuality: 80);
    if (picked.isNotEmpty) {
      setState(() {
        _imagePaths.addAll(picked.map((e) => e.path));
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_imagePaths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('portfolio.images_required'.tr())),
      );
      return;
    }

    final price = _priceController.text.isNotEmpty
        ? double.tryParse(_priceController.text)
        : null;

    Navigator.pop(
      context,
      _AddPortfolioResult(
        title: _titleController.text.trim(),
        description: _descController.text.trim().isNotEmpty
            ? _descController.text.trim()
            : null,
        price: price,
        imagePaths: _imagePaths,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: bottomInset + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'portfolio.add'.tr(),
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 20),

              // Title
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'portfolio.item_title'.tr(),
                  border: const OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'portfolio.item_title'.tr() : null,
              ),
              const SizedBox(height: 12),

              // Description
              TextFormField(
                controller: _descController,
                decoration: InputDecoration(
                  labelText: 'portfolio.item_description'.tr(),
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),

              // Price
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(
                  labelText: 'portfolio.item_price'.tr(),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              // Image picker
              Text('portfolio.item_images'.tr(),
                  style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._imagePaths.asMap().entries.map((entry) {
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            io.File(entry.value),
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                            errorBuilder: (_, e, s) => Container(
                              width: 72,
                              height: 72,
                              color: theme.colorScheme.surfaceContainerHighest,
                              child: const Icon(Icons.image, size: 24),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () => setState(
                                () => _imagePaths.removeAt(entry.key)),
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close,
                                  size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                  GestureDetector(
                    onTap: _pickImages,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.dividerColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.add_photo_alternate_outlined,
                          color: theme.colorScheme.primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Submit
              FilledButton(
                onPressed: _submit,
                child: Text('portfolio.add'.tr()),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
