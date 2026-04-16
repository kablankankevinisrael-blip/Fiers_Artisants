import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/categories_provider.dart';
import '../../data/models/category_model.dart';
import '../common/app_button.dart';
import '../common/pin_code_field.dart';
import '../common/app_text_field.dart';

class RegisterArtisanScreen extends ConsumerStatefulWidget {
  const RegisterArtisanScreen({super.key});

  @override
  ConsumerState<RegisterArtisanScreen> createState() =>
      _RegisterArtisanScreenState();
}

class _RegisterArtisanScreenState extends ConsumerState<RegisterArtisanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  final _confirmPinCtrl = TextEditingController();
  final _professionCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _communeCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _experienceCtrl = TextEditingController();
  String? _selectedCategoryId;
  String? _selectedSubcategoryId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(categoriesProvider.notifier).load());
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _pinCtrl.dispose();
    _confirmPinCtrl.dispose();
    _professionCtrl.dispose();
    _cityCtrl.dispose();
    _communeCtrl.dispose();
    _emailCtrl.dispose();
    _descriptionCtrl.dispose();
    _experienceCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final success = await ref
        .read(authProvider.notifier)
        .registerArtisan(
          phone: _phoneCtrl.text.trim(),
          pinCode: _pinCtrl.text,
          firstName: _firstNameCtrl.text.trim(),
          lastName: _lastNameCtrl.text.trim(),
          profession: _professionCtrl.text.trim(),
          city: _cityCtrl.text.trim(),
          commune: _communeCtrl.text.trim(),
          email: _emailCtrl.text.trim().isNotEmpty
              ? _emailCtrl.text.trim()
              : null,
          description: _descriptionCtrl.text.trim().isNotEmpty
              ? _descriptionCtrl.text.trim()
              : null,
          experienceYears: int.tryParse(_experienceCtrl.text),
          categoryId: _selectedCategoryId,
          subcategoryId: _selectedSubcategoryId,
        );
    setState(() => _isLoading = false);

    if (success && mounted) {
      final phone = _phoneCtrl.text.trim();
      context.push('/otp', extra: phone);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ref.read(authProvider).error ?? 'error.generic'.tr()),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider).categories;
    CategoryModel? selectedCategory;
    if (_selectedCategoryId != null) {
      for (final category in categories) {
        if (category.id == _selectedCategoryId) {
          selectedCategory = category;
          break;
        }
      }
    }
    final List<SubcategoryModel> subcategories =
        selectedCategory?.subcategories ?? const [];

    return Scaffold(
      appBar: AppBar(title: Text('auth.artisan'.tr())),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          physics: const BouncingScrollPhysics(),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name row
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _firstNameCtrl,
                        label: 'auth.first_name'.tr(),
                        prefixIcon: Icons.person_outline,
                        textInputAction: TextInputAction.next,
                        validator: (v) => v!.isEmpty ? 'Requis' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        controller: _lastNameCtrl,
                        label: 'auth.last_name'.tr(),
                        textInputAction: TextInputAction.next,
                        validator: (v) => v!.isEmpty ? 'Requis' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                AppTextField(
                  controller: _phoneCtrl,
                  label: 'auth.phone'.tr(),
                  hint: '07 XX XX XX XX',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  validator: (v) => v!.isEmpty ? 'Requis' : null,
                ),
                const SizedBox(height: 16),

                AppTextField(
                  controller: _professionCtrl,
                  label: 'auth.profession'.tr(),
                  hint: 'Plombier, Électricien...',
                  prefixIcon: Icons.work_outline,
                  textInputAction: TextInputAction.next,
                  validator: (v) => v!.isEmpty ? 'Requis' : null,
                ),
                const SizedBox(height: 16),

                // Category dropdown
                if (categories.isNotEmpty) ...[
                  Text(
                    'Catégorie',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategoryId,
                    items: categories
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      setState(() {
                        _selectedCategoryId = v;
                        _selectedSubcategoryId = null;
                      });
                    },
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.category_outlined, size: 20),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    initialValue: _selectedSubcategoryId,
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text('search.all_trades'.tr()),
                      ),
                      ...subcategories.map(
                        (s) => DropdownMenuItem<String?>(
                          value: s.id,
                          child: Text(s.name),
                        ),
                      ),
                    ],
                    onChanged: _selectedCategoryId == null
                        ? null
                        : (v) => setState(() => _selectedSubcategoryId = v),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.handyman_outlined, size: 20),
                      labelText: 'search.filter'.tr(),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Location
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _cityCtrl,
                        label: 'auth.city'.tr(),
                        hint: 'Abidjan',
                        prefixIcon: Icons.location_city_outlined,
                        textInputAction: TextInputAction.next,
                        validator: (v) => v!.isEmpty ? 'Requis' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        controller: _communeCtrl,
                        label: 'auth.commune'.tr(),
                        hint: 'Cocody',
                        textInputAction: TextInputAction.next,
                        validator: (v) => v!.isEmpty ? 'Requis' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                AppTextField(
                  controller: _experienceCtrl,
                  label: 'auth.experience_years'.tr(),
                  hint: '5',
                  prefixIcon: Icons.timeline_outlined,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                AppTextField(
                  controller: _descriptionCtrl,
                  label: 'auth.description'.tr(),
                  maxLines: 3,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                AppTextField(
                  controller: _emailCtrl,
                  label: 'auth.email'.tr(),
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                PinCodeField(
                  controller: _pinCtrl,
                  label: 'auth.pin'.tr(),
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'auth.pin'.tr();
                    if (v.length != 5) return 'auth.pin_5_digits'.tr();
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                PinCodeField(
                  controller: _confirmPinCtrl,
                  label: 'auth.confirm_pin'.tr(),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _register(),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'auth.confirm_pin'.tr();
                    if (v != _pinCtrl.text) return 'auth.pin_mismatch'.tr();
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                AppButton(
                  text: 'auth.register'.tr(),
                  isLoading: _isLoading,
                  onPressed: _register,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
