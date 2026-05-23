import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../../../theme/colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';

class MeasurementProfilePage extends ConsumerStatefulWidget {
  const MeasurementProfilePage({super.key});

  @override
  ConsumerState<MeasurementProfilePage> createState() => _MeasurementProfilePageState();
}

class _MeasurementProfilePageState extends ConsumerState<MeasurementProfilePage> {
  final _numberOnlyFormatter = FilteringTextInputFormatter.allow(RegExp(r'[\d.]'));
  bool _isEditing = false;
  String _unit = 'Inches';

  final Map<String, TextEditingController> _controllers = {};
  
  final List<String> _maleMeasurements = [
    'Shoulder', 'Neck Round', 'Chest Round', 'Stomach Round', 'Waist Round', 
    'Half Length', 'Full Top Length', 'Across Back', 'Across Chest', 'Hip Round', 
    'Thigh Round', 'Knee Round', 'Calf Round', 'Ankle Round', 'Trouser Waist', 
    'Trouser Length', 'Inseam', 'Crotch Depth'
  ];
  
  final List<String> _femaleMeasurements = [
    'Shoulder', 'Neck Round', 'Bust Round', 'High Bust', 'Under Bust', 
    'Bust Point', 'Shoulder to Bust Point', 'Shoulder to Under Bust', 
    'Shoulder to Waist', 'Front Waist Length', 'Back Waist Length', 
    'Across Chest', 'Across Back', 'Armhole Round', 'Sleeve Length', 
    'Bicep Round', 'Elbow Round', 'Wrist Round', 'Waist Round', 
    'Half Length', 'Waist to Hip', 'Upper Hip', 'Hip Round', 
    'Thigh Round', 'Knee Round', 'Calf Round', 'Ankle Round'
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadProfileData();
  }

  void _initializeControllers() {
    final allParams = [..._maleMeasurements, ..._femaleMeasurements];
    for (var p in allParams.toSet()) {
      _controllers[p] = TextEditingController();
    }
  }

  void _loadProfileData() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final profileAsync = ref.read(userProfileProvider(user.id));
    profileAsync.whenData((profile) {
      if (profile != null) {
        _unit = profile.measurementUnit ?? 'Inches';
        final measurements = profile.personalMeasurements;
        if (measurements != null) {
          measurements.forEach((key, value) {
            if (_controllers.containsKey(key)) {
              _controllers[key]!.text = value;
            }
          });
        }
        if (mounted) setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _controllers.forEach((_, c) => c.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      appBar: AppBar(
        title: const Text('PROFESSIONAL DOSSIER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 2)),
        backgroundColor: Colors.transparent, elevation: 0,
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.amber, size: 18), onPressed: () => Navigator.pop(context)),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_note_rounded, color: AppColors.amber),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildUnitSelector(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCard(),
                  const SizedBox(height: 32),
                  _buildGenderTabs(),
                ],
              ),
            ),
          ),
          if (_isEditing) _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildUnitSelector() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: ['Inches', 'Centimeters'].map((u) {
          final isSelected = _unit == u;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () { if (_isEditing) setState(() => _unit = u); },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.amber : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isSelected ? AppColors.amber : Colors.white10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    u.toUpperCase(),
                    style: TextStyle(
                      color: isSelected ? AppColors.darkNavy : Colors.white24,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.straighten_rounded, color: AppColors.amber, size: 28),
          const SizedBox(width: 20),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('FIT INTELLIGENCE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1)),
                SizedBox(height: 4),
                Text('Accurate metrics ensure a masterpiece finish. Keep your profile updated for a perfect drape.', 
                  style: TextStyle(color: Colors.white38, fontSize: 11, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderTabs() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(18),
            ),
            child: TabBar(
              indicator: BoxDecoration(color: AppColors.amber, borderRadius: BorderRadius.circular(16)),
              labelColor: AppColors.darkNavy,
              unselectedLabelColor: Colors.white38,
              labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1),
              tabs: const [
                Tab(text: 'MALE METRICS'),
                Tab(text: 'FEMALE METRICS'),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 600,
            child: TabBarView(
              children: [
                _buildMeasurementGrid(_maleMeasurements),
                _buildMeasurementGrid(_femaleMeasurements),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementGrid(List<String> fields) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2.2,
      ),
      itemCount: fields.length,
      itemBuilder: (context, index) => _buildMeasurementField(fields[index]),
    );
  }

  Widget _buildMeasurementField(String label) {
    final controller = _controllers[label];
    if (controller == null) return const SizedBox.shrink();
    
    return TextField(
      controller: controller,
      enabled: _isEditing,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [_numberOnlyFormatter],
      textAlign: TextAlign.center,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
      decoration: InputDecoration(
        labelText: label.toUpperCase(),
        labelStyle: const TextStyle(color: Colors.white24, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1),
        suffixText: _unit == 'Inches' ? 'IN' : 'CM',
        suffixStyle: const TextStyle(color: AppColors.amber, fontSize: 8, fontWeight: FontWeight.w900),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.03),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.amber)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.darkNavy,
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 64,
          child: ElevatedButton(
            onPressed: _saveMeasurements,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.amber,
              foregroundColor: AppColors.darkNavy,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 0,
            ),
            child: const Text('SYNCHRONIZE DOSSIER', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          ),
        ),
      ),
    );
  }

  Future<void> _saveMeasurements() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final measurements = <String, String>{};
    _controllers.forEach((key, controller) {
      if (controller.text.isNotEmpty) measurements[key] = controller.text;
    });

    try {
      final profile = await ref.read(userProfileProvider(user.id).future);
      if (profile != null) {
        final updatedProfile = profile.copyWith(
          measurementUnit: _unit,
          personalMeasurements: measurements,
          updatedAt: DateTime.now(),
        );
        await ref.read(updateProfileUsecaseProvider)(updatedProfile);
        ref.invalidate(userProfileProvider(user.id));
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('DOSSIER SYNCHRONIZED!'), backgroundColor: Color(0xFF00FF7F)),
        );
        setState(() => _isEditing = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sync Error: $e'), backgroundColor: Colors.redAccent));
      }
    }
  }
}
