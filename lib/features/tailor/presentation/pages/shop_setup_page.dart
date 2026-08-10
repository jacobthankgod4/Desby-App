import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../../theme/colors.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../../../core/providers/navigation_provider.dart';

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
  
  // FOCUS NODES: Explicit management for desktop stability
  final _shopNameFocus = FocusNode();
  final _bioFocus = FocusNode();
  final _addressFocus = FocusNode();
  final _phoneFocus = FocusNode();
  
  bool _isLoading = false;
  bool _isInitialized = false; // GUARD: Only load from DB once
  List<String> _selectedServices = [];
  List<String> _availableFabrics = [];

  final List<String> _serviceOptions = [
    'Custom Suits', 'Traditional Wear', 'Bridal', 'Alterations', 'Childrenswear', 'Menswear', 'Womenswear'
  ];

  final List<String> _fabricOptions = [
    'Cotton', 'Silk', 'Linen', 'Wool', 'Lace', 'Ankara', 'Cashmere', 'Velvet'
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
      if (user != null) {
        final currentProfile = await ref.read(userProfileProvider(user.id).future);
        
        final updatedProfile = (currentProfile ?? UserProfile(
          id: user.id,
          email: user.email,
          name: user.name,
          userType: 'tailor',
          createdAt: DateTime.now(),
        )).copyWith(
          businessName: _shopNameController.text.trim(),
          bio: _bioController.text.trim(),
          address: _addressController.text.trim(),
          phone: _phoneController.text.trim(),
          services: _selectedServices,
          availableFabrics: _availableFabrics,
          userType: 'tailor', // ENSURE role is forced to tailor
          updatedAt: DateTime.now(),
        );

        await ref.read(updateProfileUsecaseProvider)(updatedProfile);
        
        // REFRESH: Force provider to clear cached empty profile
        ref.invalidate(userProfileProvider(user.id));
        await ref.read(userProfileProvider(user.id).future);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Atelier configuration updated successfully!'), backgroundColor: Colors.green),
          );
          
          if (ref.read(navigationProvider).route != '/main') {
            ref.read(navigationProvider.notifier).state = const NavigationState('/main');
          } else {
            Navigator.maybePop(context);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Configuration Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      appBar: AppBar(
        title: const Text('ATELIER CONFIG', 
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.amber, size: 20),
          onPressed: () {
            if (ref.read(navigationProvider).route != '/main') {
              ref.read(navigationProvider.notifier).state = const NavigationState('/main');
            } else {
              Navigator.maybePop(context);
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('BUSINESS IDENTITY'),
              _buildRawTextField('BUSINESS NAME', _shopNameController, _shopNameFocus, (v) => v!.isEmpty ? 'Enter your atelier name' : null),
              const SizedBox(height: 16),
              _buildRawTextField('CRAFT NARRATIVE (BIO)', _bioController, _bioFocus, null, maxLines: 3),
              const SizedBox(height: 32),

              _buildSectionTitle('CONTACT & LOGISTICS'),
              _buildRawTextField('PHYSICAL ATELIER ADDRESS', _addressController, _addressFocus, null, icon: Icons.location_on_rounded),
              const SizedBox(height: 16),
              _buildRawTextField('BUSINESS HOTLINE', _phoneController, _phoneFocus, null, type: TextInputType.phone, icon: Icons.phone_rounded),
              const SizedBox(height: 32),

              _buildSectionTitle('MASTERED SERVICES'),
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

              _buildSectionTitle('AVAILABLE TEXTILES'),
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
                text: 'SAVE CONFIGURATION',
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
      child: Text(title, style: const TextStyle(color: AppColors.amber, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
    );
  }

  Widget _buildRawTextField(String label, TextEditingController controller, FocusNode focusNode, String? Function(String?)? validator, {IconData? icon, TextInputType type = TextInputType.text, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          validator: validator,
          keyboardType: type,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: icon != null ? Icon(icon, color: AppColors.amber, size: 20) : null,
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.amber, width: 1.5)),
          ),
        ),
      ],
    );
  }

  Widget _buildChipSelection(List<String> options, List<String> selected, Function(String) onToggle) {
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
              color: isSelected ? AppColors.amber : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isSelected ? AppColors.amber : Colors.white10),
            ),
            child: Text(
              option.toUpperCase(),
              style: TextStyle(
                color: isSelected ? AppColors.darkNavy : Colors.white70,
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
