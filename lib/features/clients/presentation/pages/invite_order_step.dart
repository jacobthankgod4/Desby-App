import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:desby_app/theme/colors.dart';

import '../providers/invite_provider.dart';

class InviteOrderStep extends ConsumerStatefulWidget {
  const InviteOrderStep({super.key});

  @override
  ConsumerState<InviteOrderStep> createState() => _InviteOrderStepState();
}

class _InviteOrderStepState extends ConsumerState<InviteOrderStep> {
  final _garmentController = TextEditingController();
  final _colorController = TextEditingController();
  DateTime? _dueDate;
  String? _selectedFabric;
  String? _materialPhotoUrl;
  bool _initialized = false;
  bool _uploadingPhoto = false;

  static const List<String> _commonFabrics = [
    'Cotton',
    'Silk',
    'Linen',
    'Wool',
    'Chiffon',
    'Lace',
    'Ankara',
    'Aso Oke',
    'George',
    'Denim',
    'Velvet',
    'Crepe',
    'Satin',
    'Tulle',
    'Organza',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _loadExistingData();
    }
  }

  void _loadExistingData() {
    final orderDetails = ref.read(inviteNotifierProvider).orderDetails;
    if (orderDetails != null) {
      _garmentController.text = orderDetails['garment_type'] as String? ?? '';
      _colorController.text = orderDetails['fabric_color'] as String? ?? '';
      _selectedFabric = orderDetails['fabric_type'] as String?;
      _materialPhotoUrl = orderDetails['material_photo_url'] as String?;
      final dueDateStr = orderDetails['due_date'] as String?;
      if (dueDateStr != null) {
        _dueDate = DateTime.tryParse(dueDateStr);
      }
    } else {
      final selectedProduct = ref.read(inviteNotifierProvider).selectedProduct;
      if (selectedProduct != null) {
        _garmentController.text = selectedProduct['name'] as String? ?? '';
      }
    }
  }

  @override
  void dispose() {
    _garmentController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  bool _isValid() {
    return _garmentController.text.isNotEmpty &&
        _dueDate != null &&
        _selectedFabric != null &&
        _colorController.text.isNotEmpty;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 14)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.amber,
              onPrimary: AppColors.darkNavy,
              surface: Color(0xFF1A1F36),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _uploadPhoto() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: context.colors.bottomSheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.colors.textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'ADD MATERIAL PHOTO',
                style: TextStyle(
                  color: context.colors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.amber),
                title: Text(
                  'Take Photo',
                  style: TextStyle(color: context.colors.textPrimary),
                ),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: AppColors.amber,
                ),
                title: Text(
                  'Choose from Gallery',
                  style: TextStyle(color: context.colors.textPrimary),
                ),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    setState(() => _uploadingPhoto = true);
    try {
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (pickedFile == null) {
        setState(() => _uploadingPhoto = false);
        return;
      }

      final bytes = kIsWeb
          ? await pickedFile.readAsBytes()
          : await File(pickedFile.path).readAsBytes();
      final fileName = 'material_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final supabase = Supabase.instance.client;
      await supabase.storage
          .from('avatars')
          .uploadBinary(
            'material_photos/$fileName',
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );

      final url = supabase.storage
          .from('avatars')
          .getPublicUrl('material_photos/$fileName');

      setState(() {
        _materialPhotoUrl = url;
        _uploadingPhoto = false;
      });
    } catch (e) {
      setState(() => _uploadingPhoto = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (!_isValid()) return;

    final token = ref.read(inviteNotifierProvider).client?.inviteToken ?? '';
    final selectedProduct = ref.read(inviteNotifierProvider).selectedProduct;

    final orderData = {
      'garment_type': _garmentController.text.trim(),
      'due_date': _dueDate!.toIso8601String(),
      'fabric_type': _selectedFabric,
      'fabric_color': _colorController.text.trim(),
      'material_photo_url': _materialPhotoUrl,
      if (selectedProduct != null) 'product_id': selectedProduct['id'],
      if (selectedProduct != null) 'base_price': selectedProduct['price'],
    };

    await ref
        .read(inviteNotifierProvider.notifier)
        .updateOrderDetails(token, orderData);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final inviteState = ref.watch(inviteNotifierProvider);
    final selectedProduct = inviteState.selectedProduct;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'ORDER DETAILS',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'What would you like to order?',
            style: TextStyle(color: colors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 32),

          if (selectedProduct != null) ...[
            _buildSelectedProductSummary(selectedProduct),
            const SizedBox(height: 24),
          ],

          _buildFieldLabel('GARMENT TYPE'),
          const SizedBox(height: 12),
          TextField(
            controller: _garmentController,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              hintText: 'e.g., Agbada, Kaftan, Suit, Gown',
              hintStyle: TextStyle(color: colors.textMuted, fontSize: 14),
              filled: true,
              fillColor: colors.containerFill,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: colors.borderDefault),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: colors.borderDefault),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: colors.textPrimary),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 24),

          _buildFieldLabel('WHEN DO YOU NEED THIS?'),
          const SizedBox(height: 12),
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: colors.containerFill,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.borderDefault),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    color: _dueDate != null
                        ? AppColors.amber
                        : colors.textMuted,
                    size: 20,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    _dueDate != null
                        ? _formatDate(_dueDate!)
                        : 'Select due date',
                    style: TextStyle(
                      color: _dueDate != null
                          ? colors.textPrimary
                          : colors.textMuted,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  if (_dueDate != null)
                    Icon(Icons.check_circle, color: AppColors.amber, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          _buildFieldLabel('WHAT FABRIC?'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _commonFabrics.map((fabric) {
              final isSelected = _selectedFabric == fabric;
              return InkWell(
                onTap: () => setState(() => _selectedFabric = fabric),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.amber : colors.containerFill,
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? null
                        : Border.all(color: colors.borderDefault),
                  ),
                  child: Text(
                    fabric.toUpperCase(),
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.darkNavy
                          : colors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          _buildFieldLabel('WHAT COLOR?'),
          const SizedBox(height: 12),
          TextField(
            controller: _colorController,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              hintText: 'e.g., Navy Blue, Gold, Wine',
              hintStyle: TextStyle(color: colors.textMuted, fontSize: 14),
              filled: true,
              fillColor: colors.containerFill,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: colors.borderDefault),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: colors.borderDefault),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: colors.textPrimary),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 24),

          _buildFieldLabel('MATERIAL PHOTO (OPTIONAL)'),
          const SizedBox(height: 12),
          InkWell(
            onTap: _uploadingPhoto ? null : _uploadPhoto,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                color: colors.containerFill,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colors.borderDefault,
                  style: _materialPhotoUrl != null
                      ? BorderStyle.none
                      : BorderStyle.solid,
                ),
                image: _materialPhotoUrl != null
                    ? DecorationImage(
                        image: NetworkImage(_materialPhotoUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _uploadingPhoto
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.amber),
                    )
                  : _materialPhotoUrl == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_a_photo_outlined,
                          color: colors.textMuted,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap to add photo of your fabric',
                          style: TextStyle(
                            color: colors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    )
                  : Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        onPressed: () =>
                            setState(() => _materialPhotoUrl = null),
                        icon: Icon(
                          Icons.close_rounded,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 32),

          if (inviteState.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                inviteState.error!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),

          Row(
            children: [
              Expanded(
                flex: 1,
                child: SizedBox(
                  height: 56,
                  child: OutlinedButton(
                    onPressed: () => ref
                        .read(inviteNotifierProvider.notifier)
                        .previousStep(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.textSecondary,
                      side: BorderSide(color: colors.borderSubtle),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'BACK',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isValid() && !inviteState.isLoading
                        ? _submit
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.amber,
                      foregroundColor: AppColors.darkNavy,
                      disabledBackgroundColor: colors.borderSubtle,
                      disabledForegroundColor: colors.textMuted,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: inviteState.isLoading
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: colors.textOnAmber,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'CONTINUE',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSelectedProductSummary(Map<String, dynamic> product) {
    final colors = context.colors;
    final name = product['name'] as String? ?? '';
    final price = (product['price'] as num?)?.toDouble() ?? 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Row(
        children: [
          Icon(Icons.checkroom, color: AppColors.amber, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.toUpperCase(),
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '₦${price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: AppColors.amber,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    final colors = context.colors;
    return Text(
      label,
      style: TextStyle(
        color: colors.textSecondary,
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
