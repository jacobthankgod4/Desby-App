import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/failures.dart';

/// Why an identity document is being held.
enum VerificationPurpose { payoutRecipient, sellerTrust, disputeEvidence }

extension VerificationPurposeValue on VerificationPurpose {
  String get storage => switch (this) {
        VerificationPurpose.payoutRecipient => 'payout_recipient',
        VerificationPurpose.sellerTrust => 'seller_trust',
        VerificationPurpose.disputeEvidence => 'dispute_evidence',
      };
}

enum IdentityDocType { nin, voterCard, driversLicence, passport, businessRc, other }

extension IdentityDocTypeValue on IdentityDocType {
  String get storage => switch (this) {
        IdentityDocType.nin => 'nin',
        IdentityDocType.voterCard => 'voter_card',
        IdentityDocType.driversLicence => 'drivers_licence',
        IdentityDocType.passport => 'national_passport',
        IdentityDocType.businessRc => 'business_rc',
        IdentityDocType.other => 'other',
      };

  String get label => switch (this) {
        IdentityDocType.nin => 'National Identity Number (NIN)',
        IdentityDocType.voterCard => 'Voter card',
        IdentityDocType.driversLicence => "Driver's licence",
        IdentityDocType.passport => 'International passport',
        IdentityDocType.businessRc => 'Business registration (CAC)',
        IdentityDocType.other => 'Other government document',
      };
}

enum AddressProofType { utilityBill, bankStatement, nationalId, tenancyAgreement, other }

extension AddressProofTypeValue on AddressProofType {
  String get storage => switch (this) {
        AddressProofType.utilityBill => 'utility_bill',
        AddressProofType.bankStatement => 'bank_statement',
        AddressProofType.nationalId => 'national_id',
        AddressProofType.tenancyAgreement => 'tenancy_agreement',
        AddressProofType.other => 'other',
      };

  String get label => switch (this) {
        AddressProofType.utilityBill => 'Utility bill (electricity or water)',
        AddressProofType.bankStatement => 'Bank statement',
        AddressProofType.nationalId => 'National ID document',
        AddressProofType.tenancyAgreement => 'Tenancy or rent agreement',
        AddressProofType.other => 'Other proof of address',
      };
}

enum VerificationState { none, pending, verified, rejected, expired }

/// Current verification standing for one user.
class VerificationStatus {
  final VerificationState identity;
  final VerificationState address;
  final DateTime? identityVerifiedAt;
  final DateTime? addressVerifiedAt;
  final String? rejectionReason;

  const VerificationStatus({
    this.identity = VerificationState.none,
    this.address = VerificationState.none,
    this.identityVerifiedAt,
    this.addressVerifiedAt,
    this.rejectionReason,
  });

  bool get isIdentityVerified => identity == VerificationState.verified;
  bool get isAddressVerified => address == VerificationState.verified;
  bool get isPending =>
      identity == VerificationState.pending || address == VerificationState.pending;

  /// Submitted counts as pending or verified. Approval is deliberately *not*
  /// required to finish onboarding — only to get paid — so the gate everywhere
  /// in the UI keys off "submitted", never "verified".
  ///
  /// `rejected` and `expired` are neither: a tailor whose document was refused
  /// has nothing on file, and letting them continue on that basis would defeat
  /// the control entirely.
  bool get isIdentitySubmitted => _isSubmitted(identity);
  bool get isAddressSubmitted => _isSubmitted(address);

  /// Address proof is mandatory for a tailor to finish onboarding, alongside the
  /// identity document.
  bool get isCompleteForOnboarding =>
      isIdentitySubmitted && isAddressSubmitted;

  /// What is still missing, in the tailor's words. Drives the prompt on the
  /// blocked Continue button so it says which document to upload rather than
  /// failing generically.
  List<String> get outstandingRequirements => [
        if (!isIdentitySubmitted) 'an identity document',
        if (!isAddressSubmitted) 'proof of address',
      ];

  static bool _isSubmitted(VerificationState s) =>
      s == VerificationState.pending || s == VerificationState.verified;

  static VerificationState _state(String? raw) => switch (raw) {
        'pending' => VerificationState.pending,
        'verified' => VerificationState.verified,
        'rejected' => VerificationState.rejected,
        'expired' => VerificationState.expired,
        _ => VerificationState.none,
      };

  static VerificationStatus fromRpc(dynamic row) {
    if (row is! List || row.isEmpty || row.first is! Map) {
      return const VerificationStatus();
    }
    final r = Map<String, dynamic>.from(row.first as Map);
    return VerificationStatus(
      identity: _state(r['identity_status'] as String?),
      address: _state(r['address_status'] as String?),
      identityVerifiedAt:
          DateTime.tryParse(r['identity_verified_at']?.toString() ?? ''),
      addressVerifiedAt:
          DateTime.tryParse(r['address_verified_at']?.toString() ?? ''),
      rejectionReason: r['rejection_reason'] as String?,
    );
  }
}

/// A document image the user has chosen but not yet submitted.
class PickedDocument {
  const PickedDocument(this.file, this.bytes);

  final XFile file;
  final Uint8List bytes;

  String get name => file.name;
}

/// Submits and reads identity / address verification.
///
/// Two rules shape this service:
///
///  * The document number is never sent to the server in the clear. It is
///    hashed in the browser and only the fingerprint is submitted, so the
///    database never becomes a list of identity numbers. This also means a
///    lost database cannot leak anyone's NIN.
///  * Documents live in a PRIVATE bucket. There is deliberately no
///    `getPublicUrl` anywhere in this file — every view is a short-lived signed
///    URL, and the document is never addressable by a guessable permanent link.
class VerificationService {
  VerificationService({SupabaseClient? client})
      : _supabase = client ?? Supabase.instance.client;

  final SupabaseClient _supabase;
  static const String _bucket = 'identity_documents';

  /// SHA-256 of a normalised document number.
  ///
  /// Normalisation matters: "ABC 1234-5678" and "abc12345678" are the same
  /// document, and must fingerprint identically.
  static String fingerprint(String documentNumber) {
    final normalised = documentNumber.replaceAll(RegExp(r'[\s\-]'), '').toLowerCase();
    return sha256.convert(utf8.encode(normalised)).toString();
  }

  /// Last four characters, for showing a reviewer which document this is
  /// without the row being a full identity record.
  static String last4(String documentNumber) {
    final digits = documentNumber.replaceAll(RegExp(r'[^0-9A-Za-z]'), '');
    return digits.length <= 4 ? digits : digits.substring(digits.length - 4);
  }

  Future<VerificationStatus> fetchStatus() async {
    try {
      final result = await _supabase.rpc('verification_status_for',
          params: {'p_user_id': _supabase.auth.currentUser?.id});
      return VerificationStatus.fromRpc(result);
    } catch (e) {
      debugPrint('[VERIFY] status fetch failed: $e');
      return const VerificationStatus();
    }
  }

  /// Whether the signed-in user is cleared to receive payouts.
  ///
  /// Mirrors the server-side `can_receive_payouts()`; the server still enforces
  /// it at release time, so this is for UI only.
  Future<bool> canReceivePayouts() async {
    try {
      final result = await _supabase.rpc('can_receive_payouts',
          params: {'p_user_id': _supabase.auth.currentUser?.id});
      return result == true;
    } catch (_) {
      return false;
    }
  }

  /// Stage 1: let the user choose a document image and preview it.
  ///
  /// Returns the picked file and its bytes so the caller can render a preview
  /// card. Nothing is uploaded or written to the database yet — the user
  /// confirms the image first, then submits it separately.
  Future<Result<PickedDocument>> pickDocumentImage({
    required ImagePicker picker,
  }) async {
    try {
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        // Long edge cap. The reviewer only needs a legible page, and a 12MP
        // camera shot is both slow to upload and a larger breach surface.
        maxWidth: 2000,
        maxHeight: 2000,
        imageQuality: 85,
      );
      if (picked == null) {
        return const Failure(UnknownFailure(message: 'No document selected.'));
      }
      return Success(PickedDocument(picked, await picked.readAsBytes()));
    } catch (e) {
      debugPrint('[VERIFY] pick failed: $e');
      return Failure(UnknownFailure(message: 'Could not read that image.'));
    }
  }

  /// Stage 2: upload the staged document and submit it for review.
  ///
  /// [documentNumber] is hashed locally and never transmitted in the clear.
  Future<Result<void>> submitIdentityDocument({
    required XFile document,
    required Uint8List bytes,
    required IdentityDocType docType,
    required String documentNumber,
    required VerificationPurpose purpose,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      return const Failure(AuthFailure(message: 'Please sign in again.'));
    }
    final trimmed = documentNumber.trim();
    if (trimmed.length < 4) {
      return const Failure(
        UnknownFailure(message: 'Enter the document number exactly as printed.'),
      );
    }

    try {
      final extension = document.name.toLowerCase().endsWith('.png') ? 'png' : 'jpg';
      final path = '$userId/${docType.storage}_${DateTime.now().millisecondsSinceEpoch}.$extension';

      // Own-folder only; the storage policy enforces this too.
      await _supabase.storage.from(_bucket).uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(upsert: false),
      );

      await _supabase.from('identity_verifications').insert({
        'user_id': userId,
        'doc_type': docType.storage,
        'doc_fingerprint': fingerprint(trimmed),
        'doc_last4': last4(trimmed),
        'doc_storage_path': path,
        'status': 'pending',
        'purpose': purpose.storage,
      });

      return const Success(null);
    } catch (e) {
      debugPrint('[VERIFY] identity submit failed: $e');
      return Failure(UnknownFailure(message: 'Could not submit that document.'));
    }
  }

  /// Submits proof of address. Accepts an uploaded file or a written note.
  Future<Result<void>> submitAddressProof({
    required AddressProofType proofType,
    required String attestedAddress,
    String? attestedState,
    String? attestedLga,
    String? referenceNote,
    // The document image is staged by `pickDocumentImage` first, so the user
    // reviews the picture before anything is submitted.
    XFile? document,
    Uint8List? bytes,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      return const Failure(AuthFailure(message: 'Please sign in again.'));
    }
    if (attestedAddress.trim().isEmpty) {
      return const Failure(
        UnknownFailure(message: 'Enter the address you live at.'),
      );
    }

    try {
      // The image was chosen and reviewed in a previous step; upload it now
      // rather than opening the picker inside the submit action.
      String? path;
      if (document != null && bytes != null && bytes.isNotEmpty) {
        final extension =
            document.name.toLowerCase().endsWith('.png') ? 'png' : 'jpg';
        path = '$userId/address_${DateTime.now().millisecondsSinceEpoch}.$extension';
        await _supabase.storage.from(_bucket).uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: false),
        );
      }

      if (path == null && (referenceNote == null || referenceNote.trim().isEmpty)) {
        return const Failure(
          UnknownFailure(message: 'Attach a document or add a reference note.'),
        );
      }

      await _supabase.from('address_verifications').insert({
        'user_id': userId,
        'proof_type': proofType.storage,
        'proof_storage_path': path,
        'reference_note': referenceNote?.trim(),
        'attested_address': attestedAddress.trim(),
        'attested_state': attestedState,
        'attested_lga': attestedLga,
        'status': 'pending',
      });

      return const Success(null);
    } catch (e) {
      debugPrint('[VERIFY] address submit failed: $e');
      return Failure(UnknownFailure(message: 'Could not submit that proof.'));
    }
  }

  /// A short-lived signed URL for a reviewer (or the owner) to view a
  /// document. Deliberately short: minutes, not days.
  Future<String?> signedPreviewUrl(String storagePath) async {
    try {
      return await _supabase.storage
          .from(_bucket)
          .createSignedUrl(storagePath, 300);
    } catch (e) {
      debugPrint('[VERIFY] signed url failed: $e');
      return null;
    }
  }

  /// Withdraws a pending submission — the user's right to erase before review.
  ///
  /// Only `pending` rows can be withdrawn; once a reviewer has looked at a
  /// document, removal is a retention decision made server-side.
  Future<Result<void>> withdrawPending() async {
    try {
      await _supabase
          .from('identity_verifications')
          .delete()
          .eq('user_id', _supabase.auth.currentUser?.id ?? '')
          .eq('status', 'pending');
      return const Success(null);
    } catch (e) {
      return Failure(UnknownFailure(message: e.toString()));
    }
  }
}