import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../theme/colors.dart';
import '../../../../core/constants/fabric_images.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../../core/providers/layout_provider.dart';
import '../../../../core/providers/style_preferences_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../../core/widgets/shell_app_bar.dart';

/// Style Preferences - Collects design preferences for a bespoke order.
/// Card-based UI for occasion and fabric, compact inputs for color/height/budget.
class MeasurementInputPage extends ConsumerStatefulWidget {
  const MeasurementInputPage({super.key});

  @override
  ConsumerState<MeasurementInputPage> createState() =>
      _MeasurementInputPageState();
}

class _MeasurementInputPageState extends ConsumerState<MeasurementInputPage> {
  String _gender = 'MALE';
  String _unit = 'Inches';
  bool _genderLocked = false;

  String _selectedOccasion = 'Casual';
  String _selectedColor = '#000000';
  String _selectedFabric = 'Cotton';
  double _budgetMin = 50000;
  double _budgetMax = 150000;

  final _heightController = TextEditingController();
  final _budgetMinController = TextEditingController();
  final _budgetMaxController = TextEditingController();

  static const Map<String, Color> _colorPalette = {
    'Black': Color(0xFF000000),
    'White': Color(0xFFFFFFFF),
    'Navy': Color(0xFF000080),
    'Brown': Color(0xFF8B4513),
    'Green': Color(0xFF008000),
    'Red': Color(0xFFFF0000),
    'Blue': Color(0xFF0000FF),
    'Beige': Color(0xFFF5F5DC),
    'Grey': Color(0xFF808080),
    'Gold': Color(0xFFFFD700),
    'Silver': Color(0xFFC0C0C0),
    'Pink': Color(0xFFFFC0CB),
    'Purple': Color(0xFF800080),
    'Orange': Color(0xFFFFA500),
    'Maroon': Color(0xFF800000),
    'Teal': Color(0xFF008080),
  };

  static const Map<String, IconData> _occasionIcons = {
    'Casual': Icons.weekend_rounded,
    'Corporate': Icons.business_center_rounded,
    'Wedding': Icons.favorite_rounded,
    'Cultural Event': Icons.celebration_rounded,
    'Party': Icons.party_mode_rounded,
    'Resort': Icons.beach_access_rounded,
    'Funeral': Icons.sentiment_dissatisfied_rounded,
    'Business Meeting': Icons.handshake_rounded,
  };

  static const Map<String, Color> _occasionColors = {
    'Casual': Color(0xFF4CAF50),
    'Corporate': Color(0xFF2196F3),
    'Wedding': Color(0xFFE91E63),
    'Cultural Event': Color(0xFFFF9800),
    'Party': Color(0xFF9C27B0),
    'Resort': Color(0xFF00BCD4),
    'Funeral': Color(0xFF607D8B),
    'Business Meeting': Color(0xFF3F51B5),
  };

  static const List<String> _occasions = [
    'Casual',
    'Corporate',
    'Wedding',
    'Cultural Event',
    'Party',
    'Resort',
    'Funeral',
    'Business Meeting',
  ];

  static const List<String> _fabrics = [
    'Cotton',
    'Linen',
    'Silk',
    'Wool',
    'Chiffon',
    'Lace',
    'Ankara',
    'Aso Oke',
    'George',
    'Denim',
    'Velvet',
  ];

  @override
  void initState() {
    super.initState();
    _budgetMinController.text = _budgetMin.toInt().toString();
    _budgetMaxController.text = _budgetMax.toInt().toString();
    _loadProfileAndPreferences();
  }

  void _loadProfileAndPreferences() async {
    // Load saved style preferences from Supabase
    final savedPrefs = await ref.read(savedStylePreferencesProvider.future);
    if (savedPrefs != null && mounted) {
      setState(() {
        _selectedOccasion = savedPrefs.occasion;
        _selectedFabric = savedPrefs.fabric;
        _selectedColor = savedPrefs.color;
        _gender = savedPrefs.gender;
        _unit = savedPrefs.unit;
        _budgetMin = savedPrefs.budgetMin;
        _budgetMax = savedPrefs.budgetMax;
        _budgetMinController.text = _budgetMin.toInt().toString();
        _budgetMaxController.text = _budgetMax.toInt().toString();
        if (savedPrefs.height != null) {
          _heightController.text = savedPrefs.height!.toInt().toString();
        }
      });
    }

    // Load user profile for gender and height pre-fill
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    if (userId.isEmpty) return;
    final profile = await ref.read(userProfileProvider(userId).future);
    if (profile == null || !mounted) return;

    setState(() {
      // Pre-select gender from profile (locked)
      if (profile.gender != null && profile.gender!.isNotEmpty) {
        _gender = profile.gender!.toUpperCase();
        _genderLocked = true;
      }

      // Pre-fill height from onboarding measurements
      if (_heightController.text.isEmpty &&
          profile.personalMeasurements != null) {
        final heightValue = profile.personalMeasurements!['height'];
        if (heightValue != null) {
          _heightController.text = heightValue.toString();
        }
      }

      // Pre-fill measurement unit
      if (profile.measurementUnit != null &&
          profile.measurementUnit!.isNotEmpty) {
        _unit = profile.measurementUnit!.toLowerCase().contains('cm')
            ? 'CM'
            : 'Inches';
      }
    });
  }

  @override
  void dispose() {
    _heightController.dispose();
    _budgetMinController.dispose();
    _budgetMaxController.dispose();
    super.dispose();
  }

  bool _isSaving = false;

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    final height = double.tryParse(_heightController.text);
    final prefs = StylePreferences(
      occasion: _selectedOccasion,
      fabric: _selectedFabric,
      color: _selectedColor,
      height: height,
      unit: _unit,
      gender: _gender,
      budgetMin: _budgetMin,
      budgetMax: _budgetMax,
    );
    ref.read(stylePreferencesProvider.notifier).state = prefs;
    // Wait for the Supabase write so the preferences survive navigation
    // away from this page and the next session.
    await saveStylePreferencesToSupabase(prefs);
    if (!mounted) return;
    ref.popShell();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDesktop = ref.watch(isDesktopProvider);

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: shellAppBar(context, title: 'STYLE PREFERENCES'),
      body: Column(
        children: [
          _buildToggles(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 48 : 20,
                vertical: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What are you making?',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pick an occasion and fabric to get started.',
                    style: TextStyle(color: colors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 28),
                  _buildSectionHeader('OCCASION'),
                  const SizedBox(height: 12),
                  _buildOccasionCards(),
                  const SizedBox(height: 28),
                  _buildSectionHeader('FABRIC'),
                  const SizedBox(height: 12),
                  _buildFabricCards(),
                  const SizedBox(height: 28),
                  _buildSectionHeader('COLOR'),
                  const SizedBox(height: 12),
                  _buildColorPicker(),
                  const SizedBox(height: 28),
                  _buildSectionHeader('YOUR HEIGHT'),
                  const SizedBox(height: 12),
                  _buildHeightInput(),
                  const SizedBox(height: 28),
                  _buildBudgetSlider(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          _buildBottomAction(),
        ],
      ),
    );
  }

  Widget _buildToggles() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _buildToggleGroup(
              ['MALE', 'FEMALE'],
              _gender,
              _genderLocked ? null : (v) => setState(() => _gender = v),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildToggleGroup(
              ['Inches', 'CM'],
              _unit,
              (v) => setState(() => _unit = v),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleGroup(
    List<String> items,
    String current,
    Function(String)? onSelect,
  ) {
    final colors = context.colors;
    final isLocked = onSelect == null;
    return Row(
      children: items.map((it) {
        final isSel = current == it;
        return Expanded(
          child: GestureDetector(
            onTap: isLocked ? null : () => onSelect(it),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: isSel ? AppColors.amber : colors.surface,
                borderRadius: BorderRadius.circular(12),
                border: isSel ? null : Border.all(color: colors.divider),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    it.toUpperCase(),
                    style: TextStyle(
                      color: isSel ? AppColors.darkNavy : colors.textSecondary,
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                    ),
                  ),
                  if (isLocked && isSel) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.lock, size: 8, color: AppColors.darkNavy),
                  ],
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionHeader(String label) {
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

  // ---------------------------------------------------------------------------
  // OCCASION CARDS — horizontal scrollable, with icon + color
  // ---------------------------------------------------------------------------

  Widget _buildOccasionCards() {
    final colors = context.colors;
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _occasions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final occasion = _occasions[index];
          final isSelected = _selectedOccasion == occasion;
          final icon = _occasionIcons[occasion] ?? Icons.category_rounded;
          final accentColor = _occasionColors[occasion] ?? AppColors.amber;

          return GestureDetector(
            onTap: () => setState(() => _selectedOccasion = occasion),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 100,
              decoration: BoxDecoration(
                color: isSelected
                    ? accentColor.withValues(alpha: 0.15)
                    : colors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? accentColor : colors.borderDefault,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? accentColor.withValues(alpha: 0.2)
                          : colors.surfaceHover,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: isSelected ? accentColor : colors.textMuted,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    occasion.toUpperCase(),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected ? colors.textPrimary : colors.textMuted,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // FABRIC CARDS — responsive grid with fabric images
  // ---------------------------------------------------------------------------

  Widget _buildFabricCards() {
    final colors = context.colors;
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 1200
        ? 5
        : screenWidth > 900
        ? 4
        : screenWidth > 600
        ? 3
        : 2;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.0,
      ),
      itemCount: _fabrics.length,
      itemBuilder: (context, index) {
        final fabric = _fabrics[index];
        final isSelected = _selectedFabric == fabric;
        final asset = FabricImages.getAsset(fabric);

        return GestureDetector(
          onTap: () => setState(() => _selectedFabric = fabric),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? AppColors.amber : colors.borderDefault,
                width: isSelected ? 2.5 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.amber.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Fabric image background
                  if (asset != null)
                    Image.asset(asset, fit: BoxFit.cover)
                  else
                    Container(
                      color: colors.surfaceHover,
                      child: Icon(
                        FabricImages.getIcon(fabric),
                        color: colors.textMuted,
                        size: 28,
                      ),
                    ),
                  // Neutral dark scrim so the fabric photo stays opaque and
                  // the label remains readable (fading into the page background
                  // made the cards look transparent).
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.75),
                        ],
                      ),
                    ),
                  ),
                  // Label
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        fabric.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isSelected ? AppColors.amber : Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  // Selected checkmark
                  if (isSelected)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: AppColors.amber,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // COLOR PICKER — compact swatch grid
  // ---------------------------------------------------------------------------

  Widget _buildColorPicker() {
    final colors = context.colors;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _colorPalette.entries.map((entry) {
        final isSelected =
            _selectedColor.toUpperCase() == entry.key.toUpperCase() ||
            _selectedColor.toUpperCase() ==
                '#${entry.value.toARGB32().toRadixString(16).toUpperCase()}';
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedColor =
                  '#${entry.value.toARGB32().toRadixString(16).toUpperCase()}';
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: entry.value,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? AppColors.amber : colors.textMuted,
                width: isSelected ? 3 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: entry.value.withValues(alpha: 0.5),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: isSelected
                ? Icon(
                    Icons.check,
                    color:
                        entry.value == Colors.white ||
                            entry.value == const Color(0xFFF5F5DC)
                        ? Colors.black
                        : Colors.white,
                    size: 16,
                  )
                : null,
          ),
        );
      }).toList(),
    );
  }

  // ---------------------------------------------------------------------------
  // HEIGHT INPUT — tap card to enter value via dialog
  // ---------------------------------------------------------------------------

  Widget _buildHeightInput() {
    final colors = context.colors;
    final heightText = _heightController.text.isNotEmpty
        ? '${_heightController.text} ${_unit == 'Inches' ? 'in' : 'cm'}'
        : 'Tap to enter';

    return GestureDetector(
      onTap: _showHeightDialog,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _heightController.text.isNotEmpty
                ? AppColors.amber
                : colors.borderDefault,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.height_rounded, color: colors.textMuted, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'HEIGHT',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    heightText,
                    style: TextStyle(
                      color: _heightController.text.isNotEmpty
                          ? colors.textPrimary
                          : colors.textMuted,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _unit == 'Inches' ? 'IN' : 'CM',
                style: TextStyle(
                  color: AppColors.amber,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHeightDialog() {
    final colors = context.colors;
    final dialogController = TextEditingController(
      text: _heightController.text,
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Enter Height',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
        content: TextField(
          controller: dialogController,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
          decoration: InputDecoration(
            hintText: 'e.g. ${_unit == 'Inches' ? '70' : '178'}',
            hintStyle: TextStyle(color: colors.textMuted),
            suffixText: _unit == 'Inches' ? 'in' : 'cm',
            suffixStyle: TextStyle(
              color: AppColors.amber,
              fontWeight: FontWeight.w900,
            ),
            filled: true,
            fillColor: colors.scaffoldBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colors.borderDefault),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.amber),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'CANCEL',
              style: TextStyle(
                color: colors.textMuted,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() => _heightController.text = dialogController.text);
              Navigator.pop(ctx);
            },
            child: const Text(
              'SAVE',
              style: TextStyle(
                color: AppColors.amber,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BUDGET SLIDER
  // ---------------------------------------------------------------------------

  Widget _buildBudgetSlider() {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'BUDGET',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              Text(
                '\u20A6${_budgetMin.toInt().toString()} — \u20A6${_budgetMax.toInt().toString()}',
                style: TextStyle(
                  color: AppColors.amber,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildBudgetInput(
                  'MIN',
                  _budgetMinController,
                  (v) => setState(() => _budgetMin = v),
                ),
              ),
              Icon(Icons.arrow_forward, color: colors.textMuted, size: 16),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBudgetInput(
                  'MAX',
                  _budgetMaxController,
                  (v) => setState(() => _budgetMax = v),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetInput(
    String label,
    TextEditingController controller,
    Function(double) onChanged,
  ) {
    final colors = context.colors;
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: TextStyle(
        color: colors.textPrimary,
        fontWeight: FontWeight.w900,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: colors.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
        prefixText: '\u20A6 ',
        prefixStyle: TextStyle(
          color: AppColors.amber,
          fontWeight: FontWeight.w900,
          fontSize: 14,
        ),
        filled: true,
        fillColor: colors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.borderDefault),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.borderDefault),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.amber),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),
      onChanged: (text) {
        final parsed = double.tryParse(text.replaceAll(RegExp(r'[^0-9.]'), ''));
        if (parsed != null) onChanged(parsed);
      },
    );
  }

  // ---------------------------------------------------------------------------
  // BOTTOM ACTION — "SAVE"
  // ---------------------------------------------------------------------------

  Widget _buildBottomAction() {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.scaffoldBg,
        border: Border(top: BorderSide(color: colors.borderSubtle)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 52,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.amber,
              foregroundColor: AppColors.darkNavy,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.darkNavy,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_rounded, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'SAVE',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
