import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/error/failures.dart';
import '../../../../theme/colors.dart';
import '../../../../theme/spacing.dart';
import '../../../../theme/typography.dart';
import '../../data/verification_service.dart';

final verificationServiceProvider = Provider<VerificationService>(
  (ref) => VerificationService(),
);

/// Onboarding step: identity document + proof of address.
///
/// Shown to tailors because they are the ones who receive money. Verifying
/// every shopper would be disproportionate; verifying a payout recipient is a
/// fraud and compliance control.
///
/// The copy is deliberately plain about *why* we ask and what we do with it. A
/// vague "we need to verify you" on an identity upload reads as data harvesting
/// and is the fastest way to lose a user's trust — and their compliance.
class IdentityVerificationStep extends ConsumerStatefulWidget {
  const IdentityVerificationStep({super.key, this.onChanged});

  final VoidCallback? onChanged;

  @override
  ConsumerState<IdentityVerificationStep> createState() =>
      _IdentityVerificationStepState();
}

class _IdentityVerificationStepState extends ConsumerState<IdentityVerificationStep> {
  final _picker = ImagePicker();
  final _docNumberController = TextEditingController();

  IdentityDocType _docType = IdentityDocType.nin;
  VerificationPurpose _purpose = VerificationPurpose.payoutRecipient;

  /// Documents the user has chosen but not yet submitted. Staging them lets the
  /// user review each image as a card before committing anything, which is why
  /// upload and submit are separate actions rather than one merged button.
  PickedDocument? _identityImage;
  PickedDocument? _addressImage;
  bool _picking = false;

  AddressProofType _proofType = AddressProofType.utilityBill;
  final _addressController = TextEditingController();
  final _referenceController = TextEditingController();

  VerificationStatus _status = const VerificationStatus();
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _docNumberController.dispose();
    _addressController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final service = ref.read(verificationServiceProvider);
    final status = await service.fetchStatus();
    if (!mounted) return;
    setState(() {
      _status = status;
      _loading = false;
    });
  }

  /// Both documents must be **submitted**. Approval is not required to continue
  /// — `can_receive_payouts()` gates money, not onboarding — but a rejected or
  /// expired submission does not count as on file.
  ///
  /// Address proof was previously optional here and the step let a tailor
  /// finish with only an ID document, which is exactly what the policy now says
  /// is not allowed.
  bool get _canFinish => _status.isCompleteForOnboarding;

  /// Stage 1 for the identity document: choose the image and preview it.
  Future<void> _pickIdentityImage() async {
    if (_picking) return;
    setState(() {
      _picking = true;
      _error = null;
    });
    final result = await ref
        .read(verificationServiceProvider)
        .pickDocumentImage(picker: _picker);
    if (!mounted) return;
    setState(() {
      _picking = false;
      result.fold(
        (f) => _error = f.message,
        (doc) => _identityImage = doc,
      );
    });
  }

  Future<void> _submitIdentity() async {
    final staged = _identityImage;
    if (staged == null) {
      setState(() => _error = 'Choose your document image first.');
      return;
    }
    final service = ref.read(verificationServiceProvider);
    setState(() {
      _submitting = true;
      _error = null;
    });

    final result = await service.submitIdentityDocument(
      document: staged.file,
      bytes: staged.bytes,
      docType: _docType,
      documentNumber: _docNumberController.text,
      purpose: _purpose,
    );

    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _submitting = false;
        _error = _friendly(failure);
      }),
      (_) async {
        setState(() => _submitting = false);
        await _load();
        widget.onChanged?.call();
      },
    );
  }

  /// Stage 1 for the address proof: choose the image and preview it.
  Future<void> _pickAddressImage() async {
    if (_picking) return;
    setState(() {
      _picking = true;
      _error = null;
    });
    final result = await ref
        .read(verificationServiceProvider)
        .pickDocumentImage(picker: _picker);
    if (!mounted) return;
    setState(() {
      _picking = false;
      result.fold(
        (f) => _error = f.message,
        (doc) => _addressImage = doc,
      );
    });
  }

  Future<void> _submitAddress() async {
    final staged = _addressImage;
    final service = ref.read(verificationServiceProvider);
    setState(() {
      _submitting = true;
      _error = null;
    });

    final result = await service.submitAddressProof(
      proofType: _proofType,
      attestedAddress: _addressController.text,
      referenceNote: _referenceController.text,
      document: staged?.file,
      bytes: staged?.bytes,
    );

    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _submitting = false;
        _error = _friendly(failure);
      }),
      (_) async {
        setState(() => _submitting = false);
        await _load();
        widget.onChanged?.call();
      },
    );
  }

  /// "No document selected" is a normal outcome of a picker, not a failure to
  /// report as an error banner.
  String? _friendly(FailureType failure) {
    final message = failure.message;
    if (message.contains('No document selected')) return null;
    return message;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (_loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _heading(colors, 'Verify your identity'),
          _body(colors,
              'You will be receiving money from clients, so we verify every '
              'tailor once. It protects you as much as it protects them.'),
          const SizedBox(height: 16),
          _privacyNote(colors),
          const SizedBox(height: 20),

          _identitySection(colors),
          const SizedBox(height: 20),
          _addressSection(colors),

          if (_error != null) ...[
            const SizedBox(height: 16),
            _errorBanner(colors, _error!),
          ],

          const SizedBox(height: 16),
          if (_canFinish)
            _body(colors,
                'You can continue while we review. You will be able to take '
                'paid orders as soon as both documents are confirmed.')
          else
            _requirementBanner(colors),
          SizedBox(height: _canFinish ? 8 : 48),
        ],
      ),
    );
  }

  /// Names the exact document still outstanding. A greyed-out Continue with no
  /// explanation is the least helpful way to enforce a requirement.
  Widget _requirementBanner(DesbyThemeColors colors) {
    final missing = _status.outstandingRequirements;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.statusWarning.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppSpacing.md),
        border: Border.all(
          color: colors.statusWarning.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: colors.statusWarning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Still needed before you can finish: '
              '${missing.join(' and ')}.',
              style: AppTypography.caption.copyWith(color: colors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heading(DesbyThemeColors colors, String text) => Text(
        text,
        style: TextStyle(
          color: colors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      );

  Widget _body(DesbyThemeColors colors, String text) => Text(
        text,
        style: TextStyle(color: colors.textMuted, fontSize: 13, height: 1.5),
      );

  /// Stating the retention period up front is both honest and required for
  /// meaningful consent.
  Widget _privacyNote(DesbyThemeColors colors) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.containerFill,
          borderRadius: BorderRadius.circular(AppSpacing.md),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.lock_outline, size: 16, color: colors.textMuted),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Your document is stored privately. We keep a secure hash of '
                'the number — never the number itself — and delete the whole '
                'record 24 months after submission.',
                style: AppTypography.caption.copyWith(color: colors.textMuted),
              ),
            ),
          ],
        ),
      );

  Widget _identitySection(DesbyThemeColors colors) {
    switch (_status.identity) {
      case VerificationState.verified:
        return _statusCard(
          colors,
          Icons.verified_user_outlined,
          'Identity verified',
          'You are cleared to receive payouts.',
          Colors.green,
        );
      case VerificationState.pending:
        return _statusCard(
          colors,
          Icons.hourglass_empty,
          'Identity submitted',
          'We are reviewing it. This usually takes under 24 hours.',
          Colors.blue,
        );
      case VerificationState.rejected:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _statusCard(
              colors,
              Icons.error_outline,
              'Could not verify',
              _status.rejectionReason ?? 'Please submit a clearer document.',
              Colors.orange,
            ),
            const SizedBox(height: 12),
            _identityForm(colors),
          ],
        );
      case VerificationState.expired:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _statusCard(
              colors,
              Icons.history,
              'Verification expired',
              'Please verify again to keep receiving payouts.',
              Colors.orange,
            ),
            const SizedBox(height: 12),
            _identityForm(colors),
          ],
        );
      case VerificationState.none:
        return _identityForm(colors);
    }
  }

  Widget _statusCard(
    DesbyThemeColors colors,
    IconData icon,
    String title,
    String subtitle,
    Color accent,
  ) =>
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.md),
          border: Border.all(color: accent.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Icon(icon, color: accent, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      )),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: AppTypography.caption
                          .copyWith(color: colors.textMuted)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _identityForm(DesbyThemeColors colors) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _heading(colors, 'Identity document'),
          const SizedBox(height: 10),
          DropdownButtonFormField<IdentityDocType>(
            initialValue: _docType,
            isExpanded: true,
            decoration: _decoration(colors, 'Document type'),
            items: [
              for (final type in IdentityDocType.values)
                DropdownMenuItem(value: type, child: Text(type.label)),
            ],
            onChanged: (v) => setState(() => _docType = v ?? _docType),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _docNumberController,
            decoration: _decoration(colors, 'Document number'),
            keyboardType: TextInputType.text,
          ),
          const SizedBox(height: 12),
          // Upload is its own action so the user can see and change the image
          // before anything is sent. Submit is separate and only enabled once a
          // document is staged.
          _documentPicker(
            colors,
            document: _identityImage,
            picking: _picking,
            submitting: _submitting,
            canSubmit: _identityImage != null,
            uploadLabel: 'CHOOSE DOCUMENT IMAGE',
            submitLabel: 'SUBMIT IDENTITY DOCUMENT',
            onUpload: _pickIdentityImage,
            onSubmit: _submitIdentity,
          ),
        ],
      );


  /// Upload and submit as two distinct actions, with the chosen image shown as a
  /// card in between.
  ///
  /// Merging them into one "UPLOAD & SUBMIT" button meant a user could not see
  /// what they had picked before it was sent, and could not correct a wrong
  /// image without restarting the whole section.
  Widget _documentPicker(
    DesbyThemeColors colors, {
    required PickedDocument? document,
    required bool picking,
    required bool submitting,
    required bool canSubmit,
    required String uploadLabel,
    required String submitLabel,
    required VoidCallback onUpload,
    required VoidCallback onSubmit,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Chosen document, shown as a card so the user can confirm it.
        if (document != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                Image.memory(
                  document.bytes,
                  width: double.infinity,
                  height: 160,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  left: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colors.scaffoldBg.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 12, color: colors.borderFocused),
                        const SizedBox(width: 4),
                        Text(
                          'Ready to submit',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],

        // Action 1 — choose/replace the image. Nothing is submitted.
        SizedBox(
          height: 48,
          child: OutlinedButton.icon(
            onPressed: picking || submitting ? null : onUpload,
            icon: picking
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(
                    document == null ? Icons.upload_file : Icons.swap_horiz,
                    size: 18,
                  ),
            label: Text(
              document == null ? uploadLabel : 'CHANGE IMAGE',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Action 2 — submit this document. Disabled until an image is staged.
        SizedBox(
          height: 48,
          child: ElevatedButton.icon(
            onPressed: (canSubmit && !submitting) ? onSubmit : null,
            icon: submitting
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.send_rounded, size: 18),
            label: Text(
              submitLabel,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.borderFocused,
              foregroundColor: colors.textPrimary,
              disabledBackgroundColor: colors.borderDefault,
            ),
          ),
        ),
      ],
    );
  }

  Widget _addressSection(DesbyThemeColors colors) {
    if (_status.address == VerificationState.verified) {
      return _statusCard(
        colors,
        Icons.home_work_outlined,
        'Address verified',
        'Your address is on file and confirmed.',
        Colors.green,
      );
    }
    if (_status.address == VerificationState.pending) {
      return _statusCard(
        colors,
        Icons.hourglass_empty,
        'Address submitted',
        'Under review. You can continue while we check it.',
        Colors.blue,
      );
    }

    // Rejected and expired both mean "nothing usable on file", so the tailor is
    // shown the form again. Without this branch a refusal left the section
    // reading "Optional for now" with no way to fix it.
    final rejected = _status.address == VerificationState.rejected;
    final expired = _status.address == VerificationState.expired;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _heading(colors, 'Proof of address'),
            const SizedBox(width: 6),
            _requiredChip(colors),
          ],
        ),
        const SizedBox(height: 4),
        if (rejected)
          _body(colors,
              'We could not accept your previous submission. Please send a '
              'clearer document showing your full name and address.')
        else if (expired)
          _body(colors,
              'Your earlier submission has expired. Please send a current one.')
        else
          _body(colors,
              'Required. Upload a recent bill showing your name and address. '
              'It settles where deliveries go and resolves any dispute.'),
        const SizedBox(height: 10),
        DropdownButtonFormField<AddressProofType>(
          initialValue: _proofType,
          isExpanded: true,
          decoration: _decoration(colors, 'Proof type'),
          items: [
            for (final type in AddressProofType.values)
              DropdownMenuItem(value: type, child: Text(type.label)),
          ],
          onChanged: (v) => setState(() => _proofType = v ?? _proofType),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _addressController,
          decoration: _decoration(colors, 'Your home address')
              .copyWith(hintText: 'The address you live at'),
          maxLines: 2,
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _referenceController,
          decoration: _decoration(colors, 'Reference note (optional)'),
        ),
        const SizedBox(height: 12),
        _documentPicker(
          colors,
          document: _addressImage,
          picking: _picking,
          submitting: _submitting,
          canSubmit: _addressImage != null,
          uploadLabel: 'CHOOSE ADDRESS IMAGE',
          submitLabel: 'SUBMIT ADDRESS PROOF',
          onUpload: _pickAddressImage,
          onSubmit: _submitAddress,
        ),
      ],
    );
  }

  /// Small "required" marker next to a heading, so the mandatory fields are
  /// identifiable without having to fail validation to find out.
  Widget _requiredChip(DesbyThemeColors colors) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: colors.statusWarning.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          'REQUIRED',
          style: TextStyle(
            color: colors.statusWarning,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),
      );

  InputDecoration _decoration(DesbyThemeColors colors, String hint) =>
      InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: colors.inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.md),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      );

  Widget _errorBanner(DesbyThemeColors colors, String message) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppSpacing.md),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message,
                  style: AppTypography.caption.copyWith(color: colors.textPrimary)),
            ),
          ],
        ),
      );
}
