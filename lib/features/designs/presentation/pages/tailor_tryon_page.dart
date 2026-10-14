import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../theme/colors.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../../core/services/image_upload_service.dart';
import '../../../../core/services/ai_credit_service.dart';
import '../../../../core/network/magic_hour_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../clients/presentation/providers/client_provider.dart';
import '../../../designs/presentation/providers/design_provider.dart';
import '../../../designs/domain/entities/design.dart';
import '../../../../core/widgets/shell_app_bar.dart';
import '../../../../core/widgets/app_network_image.dart';

/// Tailor-initiated virtual try-on flow:
/// 1. Select a client
/// 2. Pick a garment from tailor's own shop
/// 3. Upload client photo (or use existing body scan photo)
/// 4. Generate AI try-on preview
/// 5. Share via chat / "Get This Made" CTA
class TailorTryOnPage extends ConsumerStatefulWidget {
  const TailorTryOnPage({super.key});

  @override
  ConsumerState<TailorTryOnPage> createState() => _TailorTryOnPageState();
}

class _TailorTryOnPageState extends ConsumerState<TailorTryOnPage> {
  int _step =
      0; // 0=select client, 1=select garment, 2=upload photo, 3=processing, 4=result

  // Selected data
  String? _selectedClientId;
  String? _selectedClientName;
  String? _selectedClientPhoto;
  Design? _selectedDesign;
  Uint8List? _clientPhotoBytes;
  String? _uploadedPhotoUrl;
  String? _resultUrl;
  bool _isProcessing = false;
  String? _error;

  // Client's existing body scan photo
  String? _clientBodyScanPhoto;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: shellAppBar(
        context,
        title: 'VIRTUAL TRY-ON',
        foregroundColor: colors.textPrimary,
      ),
      body: _buildBody(user?.id, colors),
    );
  }

  Widget _buildBody(String? tailorId, DesbyThemeColors colors) {
    if (tailorId == null) return const SizedBox.shrink();

    switch (_step) {
      case 0:
        return _buildClientSelector(tailorId, colors);
      case 1:
        return _buildGarmentSelector(tailorId, colors);
      case 2:
        return _buildPhotoStep(colors);
      case 3:
        return _buildProcessing(colors);
      case 4:
        return _buildResult(colors);
      default:
        return const SizedBox.shrink();
    }
  }

  // ── Step 0: Select Client ──

  Widget _buildClientSelector(String tailorId, DesbyThemeColors colors) {
    final clientsAsync = ref.watch(
      clientsProvider((tailorId: tailorId, query: null)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(
          'Select Client',
          'Choose who this try-on is for',
          1,
          4,
          colors,
        ),
        Expanded(
          child: clientsAsync.when(
            data: (clients) {
              if (clients.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.people_outline_rounded,
                        color: colors.textMuted,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No clients yet',
                        style: TextStyle(
                          color: colors.textMuted,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add a client first to create try-on previews',
                        style: TextStyle(
                          color: colors.textMuted.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: clients.length,
                itemBuilder: (context, index) {
                  final client = clients[index];
                  final isSelected = client.id == _selectedClientId;
                  return GestureDetector(
                    onTap: () async {
                      setState(() {
                        _selectedClientId = client.id;
                        _selectedClientName = client.name;
                        _selectedClientPhoto = client.profileImage;
                      });
                      // Check for existing body scan photo
                      await _checkBodyScan(client.name);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.amber.withValues(alpha: 0.08)
                            : colors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.amber
                              : colors.borderSubtle,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: AppColors.amber.withValues(
                              alpha: 0.15,
                            ),
                            backgroundImage: client.profileImage != null
                                ? NetworkImage(client.profileImage!)
                                : null,
                            child: client.profileImage == null
                                ? Text(
                                    client.name[0].toUpperCase(),
                                    style: const TextStyle(
                                      color: AppColors.amber,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  client.name,
                                  style: TextStyle(
                                    color: colors.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  client.email,
                                  style: TextStyle(
                                    color: colors.textMuted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.amber,
                              size: 20,
                            )
                          else
                            Icon(
                              Icons.chevron_right_rounded,
                              color: colors.textMuted,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.amber),
            ),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ),
        if (_selectedClientId != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => setState(() => _step = 1),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.amber,
                  foregroundColor: AppColors.darkNavy,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'NEXT: SELECT GARMENT',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _checkBodyScan(String clientName) async {
    try {
      final scans = await Supabase.instance.client
          .from('body_scans')
          .select('front_image_url')
          .eq('client_name', clientName)
          .order('created_at', ascending: false)
          .limit(1);
      if (scans.isNotEmpty && mounted) {
        setState(() {
          _clientBodyScanPhoto = scans[0]['front_image_url'];
        });
      }
    } catch (_) {}
  }

  // ── Step 1: Select Garment ──

  Widget _buildGarmentSelector(String tailorId, DesbyThemeColors colors) {
    final designsAsync = ref.watch(tailorDesignsProvider(tailorId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(
          'Select Garment',
          'Pick from your shop designs',
          2,
          4,
          colors,
        ),
        Expanded(
          child: designsAsync.when(
            data: (designs) {
              if (designs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.checkroom_rounded,
                        color: colors.textMuted,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No designs in your shop',
                        style: TextStyle(
                          color: colors.textMuted,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Upload a design to your shop first',
                        style: TextStyle(
                          color: colors.textMuted.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.75,
                ),
                itemCount: designs.length,
                itemBuilder: (context, index) {
                  final design = designs[index];
                  final isSelected = design.id == _selectedDesign?.id;
                  final hasImage = design.imageUrls.isNotEmpty;

                  return GestureDetector(
                    onTap: () => setState(() {
                      _selectedDesign = design;
                    }),
                    child: Container(
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.amber
                              : colors.borderSubtle,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(13),
                              ),
                              child: hasImage
                                  ? AppNetworkImage(
                                      url: design.imageUrls.first,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      color: colors.surfaceHover,
                                      child: Icon(
                                        Icons.checkroom_rounded,
                                        color: colors.textMuted,
                                        size: 32,
                                      ),
                                    ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  design.title,
                                  style: TextStyle(
                                    color: colors.textPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '₦${design.price.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    color: AppColors.amber,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.amber),
            ),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _step = 0),
                  child: const Text('BACK'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _selectedDesign != null
                      ? () => setState(() => _step = 2)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.amber,
                    foregroundColor: AppColors.darkNavy,
                    disabledBackgroundColor: colors.surfaceHover,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'NEXT: UPLOAD PHOTO',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Step 2: Upload Client Photo ──

  Widget _buildPhotoStep(DesbyThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            'Client Photo',
            'Upload or use existing body scan',
            3,
            4,
            colors,
          ),
          const SizedBox(height: 24),

          // Existing body scan photo option
          if (_clientBodyScanPhoto != null) ...[
            Text(
              'EXISTING BODY SCAN',
              style: TextStyle(
                color: colors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                setState(() {
                  _uploadedPhotoUrl = _clientBodyScanPhoto;
                  _clientPhotoBytes = null;
                });
                await _generateTryOn();
              },
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  color: AppColors.amber.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.amber.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(14),
                      ),
                      child: AppNetworkImage(
                        url: _clientBodyScanPhoto!,
                        fit: BoxFit.cover,
                        width: 140,
                        height: 180,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            color: AppColors.amber,
                            size: 24,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Use Body Scan Photo',
                            style: TextStyle(
                              color: AppColors.amber,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Already have a body scan on file',
                            style: TextStyle(
                              color: colors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: Divider(color: colors.borderSubtle)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'OR',
                    style: TextStyle(
                      color: colors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: colors.borderSubtle)),
              ],
            ),
            const SizedBox(height: 24),
          ],

          // Upload new photo
          Text(
            'UPLOAD NEW PHOTO',
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickClientPhoto,
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.borderSubtle),
              ),
              child: _clientPhotoBytes != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.memory(
                        _clientPhotoBytes!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_a_photo_rounded,
                          color: colors.textMuted,
                          size: 40,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Tap to upload client photo',
                          style: TextStyle(
                            color: colors.textMuted,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'JPG, PNG up to 10MB',
                          style: TextStyle(
                            color: colors.textMuted.withValues(alpha: 0.6),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          const Spacer(),

          if (_error != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.redAccent,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() {
                    _step = 1;
                    _clientPhotoBytes = null;
                    _uploadedPhotoUrl = null;
                    _error = null;
                  }),
                  child: const Text('BACK'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed:
                      (_clientPhotoBytes != null || _uploadedPhotoUrl != null)
                      ? _generateTryOn
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.amber,
                    foregroundColor: AppColors.darkNavy,
                    disabledBackgroundColor: colors.surfaceHover,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'GENERATE TRY-ON',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickClientPhoto() async {
    final service = ImageUploadService();
    final xFile = await service.pickImageFromGallery();
    if (xFile != null && mounted) {
      final bytes = await xFile.readAsBytes();
      setState(() {
        _clientPhotoBytes = bytes;
        _uploadedPhotoUrl = null;
        _error = null;
      });
    }
  }

  // ── Generate Try-On ──

  Future<void> _generateTryOn() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() {
      _step = 3;
      _isProcessing = true;
      _error = null;
    });

    try {
      // 1. Upload client photo if needed
      String? photoUrl = _uploadedPhotoUrl;
      if (photoUrl == null && _clientPhotoBytes != null) {
        final fileName =
            'tryon_photos/${user.id}/${DateTime.now().millisecondsSinceEpoch}.jpg';
        await Supabase.instance.client.storage
            .from('images')
            .uploadBinary(
              fileName,
              _clientPhotoBytes!,
              fileOptions: const FileOptions(
                contentType: 'image/jpeg',
                upsert: true,
              ),
            );
        photoUrl = Supabase.instance.client.storage
            .from('images')
            .getPublicUrl(fileName);
      }

      if (photoUrl == null) {
        throw Exception('Failed to upload client photo');
      }

      // 2. Get garment URL from selected design
      final garmentUrl = _selectedDesign!.imageUrls.first;

      // 3. Deduct credit
      final creditService = ref.read(aiCreditServiceProvider);
      final canUse = await creditService.canUseCredits();
      if (!canUse) {
        throw Exception('No AI credits remaining');
      }
      await creditService.deductCredit(feature: 'virtual_tryon');

      // 4. Call MagicHour API
      final magicHour = MagicHourClient();
      final predictionId = await magicHour.createPrediction(
        humanImg: photoUrl,
        garmImg: garmentUrl,
        description: _selectedDesign!.title,
        category: _mapDesignCategory(_selectedDesign!.category),
      );

      if (predictionId == null) throw Exception('Failed to create prediction');

      // 5. Poll for result
      final result = await magicHour.waitForResult(predictionId);
      if (result.status == 'complete' && result.output != null) {
        // 6. Save to virtual_tryons table
        await Supabase.instance.client.from('virtual_tryons').insert({
          'user_id': user.id,
          'client_id': _selectedClientId,
          'design_id': _selectedDesign!.id,
          'result_url': result.output,
          'garment_url': garmentUrl,
          'photo_url': photoUrl,
          'category': _selectedDesign!.category,
          'status': 'complete',
          'metadata': {
            'tailor_initiated': true,
            'tailor_id': user.id,
            'tailor_name': user.name,
          },
        });

        if (mounted) {
          setState(() {
            _resultUrl = result.output;
            _isProcessing = false;
            _step = 4;
          });
        }
      } else {
        throw Exception(result.error ?? 'Try-on generation failed');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _error = e.toString().replaceAll('Exception: ', '');
          _step = 2; // Go back to photo step
        });
      }
    }
  }

  String _mapDesignCategory(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('pant') ||
        lower.contains('trouser') ||
        lower.contains('skirt')) {
      return 'lower_body';
    }
    if (lower.contains('dress') || lower.contains('gown')) {
      return 'dresses';
    }
    return 'upper_body';
  }

  // ── Step 3: Processing ──

  Widget _buildProcessing(DesbyThemeColors colors) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              color: AppColors.amber,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'AI TRY-ON IN PROGRESS',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Generating preview for ${_selectedClientName ?? 'client'}',
            style: TextStyle(color: colors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            'Using ${_selectedDesign?.title ?? 'design'}',
            style: TextStyle(
              color: AppColors.amber,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 32),
          if (_error != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  // ── Step 4: Result ──

  Widget _buildResult(DesbyThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Client & garment info
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.borderSubtle),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.amber.withValues(alpha: 0.15),
                  backgroundImage: _selectedClientPhoto != null
                      ? NetworkImage(_selectedClientPhoto!)
                      : null,
                  child: _selectedClientPhoto == null
                      ? Text(
                          (_selectedClientName ?? 'C')[0].toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.amber,
                            fontWeight: FontWeight.w900,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedClientName ?? 'Client',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        _selectedDesign?.title ?? '',
                        style: TextStyle(color: colors.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Result image
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: _resultUrl != null
                  ? AppNetworkImage(
                      url: _resultUrl!,
                      fit: BoxFit.contain,
                      width: double.infinity,
                    )
                  : Container(
                      color: colors.surface,
                      child: Center(
                        child: Icon(
                          Icons.checkroom_rounded,
                          color: colors.textMuted,
                          size: 64,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // Action buttons
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _shareViaChat,
              icon: const Icon(Icons.chat_rounded, size: 18),
              label: const Text(
                'SHARE VIA CHAT',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.amber,
                foregroundColor: AppColors.darkNavy,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _shareExternally,
                  icon: const Icon(Icons.share_rounded, size: 16),
                  label: const Text('Share'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _downloadResult,
                  icon: const Icon(Icons.download_rounded, size: 16),
                  label: const Text('Download'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                setState(() {
                  _step = 0;
                  _selectedClientId = null;
                  _selectedClientName = null;
                  _selectedClientPhoto = null;
                  _selectedDesign = null;
                  _clientPhotoBytes = null;
                  _uploadedPhotoUrl = null;
                  _resultUrl = null;
                  _error = null;
                  _clientBodyScanPhoto = null;
                });
              },
              child: Text(
                'NEW TRY-ON',
                style: TextStyle(
                  color: AppColors.amber,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareViaChat() async {
    if (_selectedClientId == null || _resultUrl == null) return;

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) return;

      // Find or create chat channel with this client
      final channels = await Supabase.instance.client
          .from('chat_channels')
          .select('id')
          .or(
            'and(sender_id.eq.${user.id},receiver_id.eq.${_selectedClientId}),and(sender_id.eq.${_selectedClientId},receiver_id.eq.${user.id})',
          )
          .limit(1);

      String channelId;
      if (channels.isNotEmpty) {
        channelId = channels[0]['id'];
      } else {
        // Create new channel
        final newChannel = await Supabase.instance.client
            .from('chat_channels')
            .insert({
              'sender_id': user.id,
              'receiver_id': _selectedClientId,
              'sender_type': 'tailor',
              'receiver_type': 'client',
            })
            .select('id')
            .single();
        channelId = newChannel['id'];
      }

      // Send try-on result as message
      await Supabase.instance.client.from('chat_messages').insert({
        'channel_id': channelId,
        'sender_id': user.id,
        'content':
            'Check out this try-on preview of ${_selectedDesign?.title ?? "your design"}! 🎨',
        'message_type': 'text',
      });

      await Supabase.instance.client.from('chat_messages').insert({
        'channel_id': channelId,
        'sender_id': user.id,
        'content': _resultUrl,
        'message_type': 'image',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sent via chat!'),
            backgroundColor: Colors.greenAccent,
          ),
        );
        ref.pushShell('/chats');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _shareExternally() {
    if (_resultUrl != null) {
      Share.shareUri(Uri.parse(_resultUrl!));
    }
  }

  void _downloadResult() {
    if (_resultUrl != null) {
      launchUrl(Uri.parse(_resultUrl!));
    }
  }

  // ── Shared widgets ──

  Widget _buildStepHeader(
    String title,
    String subtitle,
    int current,
    int total,
    DesbyThemeColors colors,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ...List.generate(
                total,
                (i) => Expanded(
                  child: Container(
                    height: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: i < current
                          ? AppColors.amber
                          : colors.borderSubtle,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
