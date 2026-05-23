import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/entities/user_profile.dart';
import '../../../../theme/colors.dart';
import '../../../../core/services/image_upload_service.dart';
import '../../../../core/constants/tailor_data.dart';
import '../providers/profile_provider.dart';

class ProfileEditPage extends ConsumerStatefulWidget {
  final String userId;

  const ProfileEditPage({super.key, required this.userId});

  @override
  ConsumerState<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends ConsumerState<ProfileEditPage> {
  final ImageUploadService _imageService = ImageUploadService();
  XFile? _pickedImage;

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _bioController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _businessNameController;
  late TextEditingController _businessPhoneController;
  late TextEditingController _businessAddressController;
  
  // Onboarding-specific fields for tailors
  List<String> _selectedServices = [];
  String? _selectedState;
  bool _isSubmitting = false;
  List<String> _selectedFabrics = [];

  // Operating hours for each day
  final Map<String, bool> _dayOpen = {
    'monday': true, 'tuesday': true, 'wednesday': true, 'thursday': true, 'friday': true, 'saturday': true, 'sunday': false,
  };
  final Map<String, TimeOfDay> _openTimes = {
    'monday': const TimeOfDay(hour: 9, minute: 0), 'tuesday': const TimeOfDay(hour: 9, minute: 0), 'wednesday': const TimeOfDay(hour: 9, minute: 0), 'thursday': const TimeOfDay(hour: 9, minute: 0), 'friday': const TimeOfDay(hour: 9, minute: 0), 'saturday': const TimeOfDay(hour: 9, minute: 0), 'sunday': const TimeOfDay(hour: 10, minute: 0),
  };
  final Map<String, TimeOfDay> _closeTimes = {
    'monday': const TimeOfDay(hour: 18, minute: 0), 'tuesday': const TimeOfDay(hour: 18, minute: 0), 'wednesday': const TimeOfDay(hour: 18, minute: 0), 'thursday': const TimeOfDay(hour: 18, minute: 0), 'friday': const TimeOfDay(hour: 18, minute: 0), 'saturday': const TimeOfDay(hour: 18, minute: 0), 'sunday': const TimeOfDay(hour: 17, minute: 0),
  };

  // Nigerian states for profile
  static const List<String> _nigerianStates = [
    'Abia', 'Adamawa', 'Akwa Ibom', 'Anambra', 'Bauchi', 'Bayelsa', 'Benue',
    'Borno', 'Cross River', 'Delta', 'Ebonyi', 'Edo', 'Ekiti', 'Enugu', 'Gombe',
    'Imo', 'Jigawa', 'Kaduna', 'Kano', 'Katsina', 'Kebbi', 'Kogi', 'Kwara',
    'Lagos', 'Nasarawa', 'Niger', 'Ogun', 'Ondo', 'Osun', 'Oyo', 'Plateau',
    'Sokoto', 'Taraba', 'Yobe', 'Zamfara',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _bioController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _businessNameController = TextEditingController();
    _businessPhoneController = TextEditingController();
    _businessAddressController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _businessNameController.dispose();
    _businessPhoneController.dispose();
    _businessAddressController.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A1921),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('SELECT IMAGE SOURCE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSourceOption(Icons.photo_library_rounded, 'GALLERY', () async {
                  final file = await _imageService.pickImageFromGallery();
                  if (file != null) setState(() => _pickedImage = file);
                }),
                _buildSourceOption(Icons.camera_alt_rounded, 'CAMERA', () async {
                  final file = await _imageService.pickImageFromCamera();
                  if (file != null) setState(() => _pickedImage = file);
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: () { Navigator.pop(context); onTap(); },
      child: Column(
        children: [
          Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), shape: BoxShape.circle), child: Icon(icon, color: AppColors.amber, size: 28)),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
        ],
      ),
    );
  }

  void _initializeControllers(UserProfile profile) {
    _nameController.text = profile.name;
    _emailController.text = profile.email;
    _bioController.text = profile.bio ?? '';
    _phoneController.text = profile.phone ?? '';
    _addressController.text = profile.address ?? '';
    _businessNameController.text = profile.businessName ?? '';
    _businessPhoneController.text = profile.businessPhone ?? '';
    _businessAddressController.text = profile.businessAddress ?? '';
    _selectedState = profile.state ?? profile.businessState;
    
    // Initialize working hours from existing profile data
    if (profile.workingHoursByDay != null) {
      final wh = profile.workingHoursByDay!;
      _dayOpen['monday'] = wh.mondayOpen != null;
      _dayOpen['tuesday'] = wh.tuesdayOpen != null;
      _dayOpen['wednesday'] = wh.wednesdayOpen != null;
      _dayOpen['thursday'] = wh.thursdayOpen != null;
      _dayOpen['friday'] = wh.fridayOpen != null;
      _dayOpen['saturday'] = wh.saturdayOpen != null;
      _dayOpen['sunday'] = wh.sundayOpen != null;
      
      if (wh.mondayOpen != null) _openTimes['monday'] = _parseTime(wh.mondayOpen!);
      if (wh.tuesdayOpen != null) _openTimes['tuesday'] = _parseTime(wh.tuesdayOpen!);
      if (wh.wednesdayOpen != null) _openTimes['wednesday'] = _parseTime(wh.wednesdayOpen!);
      if (wh.thursdayOpen != null) _openTimes['thursday'] = _parseTime(wh.thursdayOpen!);
      if (wh.fridayOpen != null) _openTimes['friday'] = _parseTime(wh.fridayOpen!);
      if (wh.saturdayOpen != null) _openTimes['saturday'] = _parseTime(wh.saturdayOpen!);
      if (wh.sundayOpen != null) _openTimes['sunday'] = _parseTime(wh.sundayOpen!);
      
      if (wh.mondayClose != null) _closeTimes['monday'] = _parseTime(wh.mondayClose!);
      if (wh.tuesdayClose != null) _closeTimes['tuesday'] = _parseTime(wh.tuesdayClose!);
      if (wh.wednesdayClose != null) _closeTimes['wednesday'] = _parseTime(wh.wednesdayClose!);
      if (wh.thursdayClose != null) _closeTimes['thursday'] = _parseTime(wh.thursdayClose!);
      if (wh.fridayClose != null) _closeTimes['friday'] = _parseTime(wh.fridayClose!);
      if (wh.saturdayClose != null) _closeTimes['saturday'] = _parseTime(wh.saturdayClose!);
      if (wh.sundayClose != null) _closeTimes['sunday'] = _parseTime(wh.sundayClose!);
    }
    _selectedServices = List<String>.from(profile.services ?? []);
    _selectedFabrics = List<String>.from(profile.availableFabrics ?? []);
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider(widget.userId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: const Color(0xFF0A1921),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.amber, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: const Color(0xFF0A1921),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(
              child: Text('Profile not found. Please complete onboarding first.',
                style: TextStyle(color: Colors.white)),
            );
          }
          
          if (_nameController.text.isEmpty && _emailController.text.isEmpty) {
            _initializeControllers(profile);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: InkWell(
                    onTap: _pickProfileImage,
                    borderRadius: BorderRadius.circular(60),
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: AppColors.amber.withValues(alpha: 0.1),
                          backgroundImage: _pickedImage != null 
                              ? null // Handled by child for memory support
                              : profile.profileImage != null
                                  ? NetworkImage(profile.profileImage!)
                                  : null,
                          child: _pickedImage != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(60),
                                  child: FutureBuilder<Uint8List>(
                                    future: _pickedImage!.readAsBytes(),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData) return Image.memory(snapshot.data!, fit: BoxFit.cover, width: 120, height: 120);
                                      return const CircularProgressIndicator();
                                    },
                                  ),
                                )
                              : (profile.profileImage == null)
                                  ? const Icon(Icons.person, size: 60, color: AppColors.amber)
                                  : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppColors.amber,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, 
                              size: 20, color: Color(0xFF0A1921)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                _buildSectionTitle('Personal Information'),
                const SizedBox(height: 16),
                _buildTextField(
                  label: 'Full Name',
                  controller: _nameController,
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  label: 'Email',
                  controller: _emailController,
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  enabled: false,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  label: 'Phone Number',
                  controller: _phoneController,
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  label: 'Bio',
                  controller: _bioController,
                  icon: Icons.info_outline,
                  maxLines: 3,
                  hint: 'Tell us about yourself...',
                ),
                const SizedBox(height: 32),

                _buildSectionTitle('Address'),
                const SizedBox(height: 16),
                _buildTextField(
                  label: 'Home Address',
                  controller: _addressController,
                  icon: Icons.home_outlined,
                ),
                const SizedBox(height: 16),
                _buildDropdown(
                  label: 'State',
                  value: _selectedState,
                  items: _nigerianStates,
                  onChanged: (value) => setState(() => _selectedState = value),
                ),
                const SizedBox(height: 32),

                if (profile.userType == 'tailor') ...[
                  _buildSectionTitle('Services You Offer'),
                  const SizedBox(height: 16),
                  _buildServicesSelection(),
                  const SizedBox(height: 32),
                ],

                if (profile.userType == 'tailor') ...[
                  _buildSectionTitle('Fabrics You Master'),
                  const SizedBox(height: 16),
                  _buildFabricsSelection(),
                  const SizedBox(height: 32),
                ],

                if (profile.userType == 'tailor' || profile.userType == 'fabric_seller') ...[
                  _buildSectionTitle('Business Information'),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'Business Name',
                    controller: _businessNameController,
                    icon: Icons.business_center_outlined,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'Business Phone',
                    controller: _businessPhoneController,
                    icon: Icons.phone_in_talk_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'Business Address',
                    controller: _businessAddressController,
                    icon: Icons.storefront_outlined,
                  ),
                  const SizedBox(height: 16),
                  _buildWorkingHoursSection(),
                  const SizedBox(height: 32),
                ],

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : () => _saveProfile(profile),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.amber,
                      foregroundColor: const Color(0xFF0A1921),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'SAVE CHANGES',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.amber),
        ),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error',
                style: const TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        color: AppColors.amber,
        fontSize: 12,
        fontWeight: FontWeight.w900,
        letterSpacing: 2,
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? hint,
    bool enabled = true,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      enabled: enabled,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Colors.white54),
        hintStyle: const TextStyle(color: Colors.white24),
        prefixIcon: Icon(icon, color: AppColors.amber, size: 20),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.amber),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.amber, size: 20),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      dropdownColor: const Color(0xFF1A2B3C),
      style: const TextStyle(color: Colors.white),
      items: items.map((state) => DropdownMenuItem(
        value: state,
        child: Text(state),
      )).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildServicesSelection() {
    final services = TailorServices.all;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: services.map((service) {
        final isSelected = _selectedServices.contains(service);
        return FilterChip(
          label: Text(service),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedServices.add(service);
              } else {
                _selectedServices.remove(service);
              }
            });
          },
          selectedColor: AppColors.amber.withValues(alpha: 0.3),
          checkmarkColor: AppColors.amber,
          backgroundColor: Colors.white.withValues(alpha: 0.05),
          labelStyle: TextStyle(
            color: isSelected ? AppColors.amber : Colors.white70,
            fontSize: 12,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFabricsSelection() {
    final fabrics = FabricTypes.all;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: fabrics.map((fabric) {
        final isSelected = _selectedFabrics.contains(fabric);
        return FilterChip(
          label: Text(fabric),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedFabrics.add(fabric);
              } else {
                _selectedFabrics.remove(fabric);
              }
            });
          },
          selectedColor: Colors.blue.withValues(alpha: 0.3),
          checkmarkColor: Colors.blue.shade300,
          backgroundColor: Colors.white.withValues(alpha: 0.05),
          labelStyle: TextStyle(
            color: isSelected ? Colors.blue.shade300 : Colors.white70,
            fontSize: 12,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWorkingHoursSection() {
    final days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Operating Hours'),
        const SizedBox(height: 16),
        ...days.map((d) => _buildDayRow(d)),
      ],
    );
  }

  Widget _buildDayRow(String day) {
    final isOpen = _dayOpen[day] ?? false;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Switch.adaptive(value: isOpen, activeTrackColor: AppColors.amber, onChanged: (v) => setState(() => _dayOpen[day] = v)),
          const SizedBox(width: 8),
          Text(day.toUpperCase().substring(0, 3), style: TextStyle(color: isOpen ? Colors.white : Colors.white24, fontWeight: FontWeight.w900, fontSize: 12)),
          const Spacer(),
          if (isOpen) ...[
            _buildTimeChip(day, true),
            const Text(' - ', style: TextStyle(color: Colors.white24)),
            _buildTimeChip(day, false),
          ] else const Text('CLOSED', style: TextStyle(color: Colors.white12, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTimeChip(String day, bool isStart) {
    final time = isStart ? _openTimes[day] : _closeTimes[day];
    if (time == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () async {
        final picked = await showTimePicker(context: context, initialTime: time);
        if (picked != null) {
          setState(() {
            if (isStart) {
              _openTimes[day] = picked;
            } else {
              _closeTimes[day] = picked;
            }
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: AppColors.amber.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
        child: Text(time.format(context), style: const TextStyle(color: AppColors.amber, fontWeight: FontWeight.w900, fontSize: 11)),
      ),
    );
  }

  TimeOfDay _parseTime(String timeStr) {
    try {
      final format = timeStr.toLowerCase();
      final isPm = format.contains('pm');
      final isAm = format.contains('am');
      var hour = int.parse(format.split(':').first.replaceAll(RegExp(r'[^0-9]'), ''));
      final minute = int.parse(format.split(':').last.replaceAll(RegExp(r'[^0-9]'), ''));
      if (isPm && hour != 12) hour += 12;
      if (isAm && hour == 12) hour = 0;
      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      return const TimeOfDay(hour: 9, minute: 0);
    }
  }

  String _getHoursSummary() {
    final openDays = _dayOpen.entries.where((e) => e.value).map((e) => e.key).toList();
    if (openDays.isEmpty) return 'Closed';
    if (openDays.length == 7) return 'Mon-Sun (Daily)';
    return openDays.map((d) => d.substring(0, 3).toUpperCase()).join(', ');
  }

  Future<void> _saveProfile(UserProfile originalProfile) async {
    setState(() => _isSubmitting = true);

    try {
      final monO = _dayOpen['monday']! ? _openTimes['monday']!.format(context) : null;
      final monC = _dayOpen['monday']! ? _closeTimes['monday']!.format(context) : null;
      final tueO = _dayOpen['tuesday']! ? _openTimes['tuesday']!.format(context) : null;
      final tueC = _dayOpen['tuesday']! ? _closeTimes['tuesday']!.format(context) : null;
      final wedO = _dayOpen['wednesday']! ? _openTimes['wednesday']!.format(context) : null;
      final wedC = _dayOpen['wednesday']! ? _closeTimes['wednesday']!.format(context) : null;
      final thuO = _dayOpen['thursday']! ? _openTimes['thursday']!.format(context) : null;
      final thuC = _dayOpen['thursday']! ? _closeTimes['thursday']!.format(context) : null;
      final friO = _dayOpen['friday']! ? _openTimes['friday']!.format(context) : null;
      final friC = _dayOpen['friday']! ? _closeTimes['friday']!.format(context) : null;
      final satO = _dayOpen['saturday']! ? _openTimes['saturday']!.format(context) : null;
      final satC = _dayOpen['saturday']! ? _closeTimes['saturday']!.format(context) : null;
      final sunO = _dayOpen['sunday']! ? _openTimes['sunday']!.format(context) : null;
      final sunC = _dayOpen['sunday']! ? _closeTimes['sunday']!.format(context) : null;

      final whMap = BusinessHours(
        mondayOpen: monO, mondayClose: monC,
        tuesdayOpen: tueO, tuesdayClose: tueC,
        wednesdayOpen: wedO, wednesdayClose: wedC,
        thursdayOpen: thuO, thursdayClose: thuC,
        fridayOpen: friO, fridayClose: friC,
        saturdayOpen: satO, saturdayClose: satC,
        sundayOpen: sunO, sundayClose: sunC,
      );

      String? imageUrl = originalProfile.profileImage;
      if (_pickedImage != null) {
        imageUrl = await _imageService.uploadImage(_pickedImage!, originalProfile.id, 'profiles');
      }

      final updatedProfile = originalProfile.copyWith(
        name: _nameController.text.trim(),
        profileImage: imageUrl,
        phone: _phoneController.text.trim(),
        bio: _bioController.text.trim(),
        address: _addressController.text.trim(),
        state: _selectedState,
        businessName: _businessNameController.text.trim(),
        businessPhone: _businessPhoneController.text.trim(),
        businessAddress: _businessAddressController.text.trim(),
        businessState: _selectedState,
        services: _selectedServices,
        availableFabrics: _selectedFabrics,
        workingHours: _getHoursSummary(),
        workingHoursByDay: whMap,
      );

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);

      final usecase = ref.read(updateProfileUsecaseProvider);
      final result = await usecase(updatedProfile);
      
      result.fold(
        (failure) {
          messenger.showSnackBar(
            SnackBar(
              content: Text('Error: $failure'),
              backgroundColor: Colors.red,
            ),
          );
        },
        (_) {
          ref.invalidate(userProfileProvider(widget.userId));
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully'),
              backgroundColor: AppColors.amber,
            ),
          );
          navigator.pop();
        },
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
