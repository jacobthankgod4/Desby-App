import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../../theme/colors.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../../../core/widgets/shell_app_bar.dart';

class ShopSetupPage extends ConsumerStatefulWidget {
  const ShopSetupPage({super.key});

  @override
  ConsumerState<ShopSetupPage> createState() => _ShopSetupPageState();
}

class _ShopSetupPageState extends ConsumerState<ShopSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _shopNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();

  final _shopNameFocus = FocusNode();
  final _bioFocus = FocusNode();
  final _addressFocus = FocusNode();
  final _phoneFocus = FocusNode();

  bool _isLoading = false;
  bool _isInitialized = false;
  List<String> _selectedServices = [];
  List<String> _availableFabrics = [];

  final List<String> _serviceOptions = [
    'Custom Suits',
    'Traditional Wear',
    'Bridal',
    'Alterations',
    'Childrenswear',
    'Menswear',
    'Womenswear',
  ];

  final List<String> _fabricOptions = [
    'Cotton',
    'Silk',
    'Linen',
    'Wool',
    'Lace',
    'Ankara',
    'Cashmere',
    'Velvet',
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentProfile();
  }

  Future<void> _loadCurrentProfile() async {
    if (_isInitialized) return;

    final user = ref.read(currentUserProvider);
    if (user != null) {
      final profile = await ref.read(userProfileProvider(user.id).future);
      if (profile != null && mounted) {
        setState(() {
          _shopNameController.text = profile.businessName ?? '';
          _bioController.text = profile.bio ?? '';
          _addressController.text = profile.address ?? '';
          _phoneController.text = profile.phone ?? '';
          _selectedServices = profile.services ?? [];
          _availableFabrics = profile.availableFabrics ?? [];
          _isInitialized = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _bioController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _shopNameFocus.dispose();
    _bioFocus.dispose();
    _addressFocus.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  Future<void> _saveShop() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = ref.read(currentUserProvider);
      if (user == null || user.id.isEmpty) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Your session expired. Please sign in again.',
              ),
              backgroundColor: context.colors.statusError,
            ),
          );
        return;
      }
      {
        final currentProfile = await ref.read(
          userProfileProvider(user.id).future,
        );

        final updatedProfile =
            (currentProfile ??
                    UserProfile(
                      id: user.id,
                      email: user.email,
                      name: user.name,
                      userType: 'tailor',
                      createdAt: DateTime.now(),
                    ))
                .copyWith(
                  businessName: _shopNameController.text.trim(),
                  bio: _bioController.text.trim(),
                  address: _addressController.text.trim(),
                  phone: _phoneController.text.trim(),
                  services: _selectedServices,
                  availableFabrics: _availableFabrics,
                  userType: 'tailor',
                  updatedAt: DateTime.now(),
                );

        await ref.read(updateProfileUsecaseProvider)(updatedProfile);

        ref.invalidate(userProfileProvider(user.id));
        await ref.read(userProfileProvider(user.id).future);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Atelier configuration updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          ref.setShell('/product-list');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Could not save your shop settings. Please try again.',
            ),
            backgroundColor: context.colors.statusError,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: shellAppBar(context, title: 'Shop Setup'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Business Info'),
              _buildRawTextField(
                'BUSINESS NAME',
                _shopNameController,
                _shopNameFocus,
                (v) => v!.isEmpty ? 'Enter your business name' : null,
              ),
              const SizedBox(height: 16),
              _buildRawTextField(
                'About You (Bio)',
                _bioController,
                _bioFocus,
                null,
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              _buildSectionTitle('Contact Details'),
              _buildRawTextField(
                'Workshop Address',
                _addressController,
                _addressFocus,
                null,
                icon: Icons.location_on_rounded,
              ),
              const SizedBox(height: 16),
              _buildRawTextField(
                'Phone Number',
                _phoneController,
                _phoneFocus,
                null,
                type: TextInputType.phone,
                icon: Icons.phone_rounded,
              ),
              const SizedBox(height: 32),

              _buildSectionTitle('Services You Offer'),
              _buildChipSelection(_serviceOptions, _selectedServices, (val) {
                setState(() {
                  if (_selectedServices.contains(val)) {
                    _selectedServices.remove(val);
                  } else {
                    _selectedServices.add(val);
                  }
                });
              }),
              const SizedBox(height: 32),

              _buildSectionTitle('Fabrics You Work With'),
              _buildChipSelection(_fabricOptions, _availableFabrics, (val) {
                setState(() {
                  if (_availableFabrics.contains(val)) {
                    _availableFabrics.remove(val);
                  } else {
                    _availableFabrics.add(val);
                  }
                });
              }),
              const SizedBox(height: 48),

              CustomButton(
                text: 'Save',
                onPressed: _saveShop,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: TextStyle(
          color: AppColors.amber,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildRawTextField(
    String label,
    TextEditingController controller,
    FocusNode focusNode,
    String? Function(String?)? validator, {
    IconData? icon,
    TextInputType type = TextInputType.text,
    int maxLines = 1,
  }) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          validator: validator,
          keyboardType: type,
          maxLines: maxLines,
          style: TextStyle(color: colors.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: icon != null
                ? Icon(icon, color: AppColors.amber, size: 20)
                : null,
            filled: true,
            fillColor: colors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.amber, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChipSelection(
    List<String> options,
    List<String> selected,
    Function(String) onToggle,
  ) {
    final colors = context.colors;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = selected.contains(option);
        return InkWell(
          onTap: () => onToggle(option),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.amber : colors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.amber : colors.borderSubtle,
              ),
            ),
            child: Text(
              option.toUpperCase(),
              style: TextStyle(
                color: isSelected ? colors.scaffoldBg : colors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
