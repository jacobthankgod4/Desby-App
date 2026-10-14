import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/failures.dart';

/// One row in the admin review queue.
class ReviewQueueItem {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String docType;
  final String? docLast4;
  final String storagePath;
  final String purpose;
  final String status;
  final DateTime submittedAt;
  final DateTime? verifiedAt;
  final String? rejectionReason;

  const ReviewQueueItem({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.docType,
    required this.storagePath,
    required this.purpose,
    required this.status,
    required this.submittedAt,
    this.docLast4,
    this.verifiedAt,
    this.rejectionReason,
  });

  factory ReviewQueueItem.fromRow(Map<String, dynamic> row) => ReviewQueueItem(
        id: row['id']?.toString() ?? '',
        userId: row['user_id']?.toString() ?? '',
        userName: (row['user_name'] as String?) ?? '(no name)',
        userEmail: (row['user_email'] as String?) ?? '(no email)',
        docType: (row['doc_type'] as String?) ?? 'unknown',
        docLast4: row['doc_last4'] as String?,
        storagePath: row['doc_storage_path']?.toString() ?? '',
        purpose: (row['purpose'] as String?) ?? 'payout_recipient',
        status: (row['status'] as String?) ?? 'pending',
        submittedAt:
            DateTime.tryParse(row['submitted_at']?.toString() ?? '') ??
                DateTime.now(),
        verifiedAt: DateTime.tryParse(row['verified_at']?.toString() ?? ''),
        rejectionReason: row['rejection_reason'] as String?,
      );
}

/// A user row for the admin directory.
class AdminUserRow {
  final String id;
  final String? name;
  final String? email;
  final String? userType;
  final String? phone;
  final String? address;
  final String? businessName;
  final DateTime? createdAt;
  final String identityStatus;
  final bool canReceivePayouts;

  const AdminUserRow({
    required this.id,
    required this.identityStatus,
    required this.canReceivePayouts,
    this.name,
    this.email,
    this.userType,
    this.phone,
    this.address,
    this.businessName,
    this.createdAt,
  });

  factory AdminUserRow.fromRow(Map<String, dynamic> row) => AdminUserRow(
        id: row['id']?.toString() ?? '',
        name: row['name'] as String?,
        email: row['email'] as String?,
        userType: row['user_type'] as String?,
        phone: row['phone'] as String?,
        address: row['address'] as String?,
        businessName: row['business_name'] as String?,
        createdAt: DateTime.tryParse(row['created_at']?.toString() ?? ''),
        identityStatus: (row['identity_status'] as String?) ?? 'none',
        canReceivePayouts: row['can_receive_payouts'] == true,
      );
}

/// Admin-side data access.
///
/// Every read goes through an RLS-scoped query or a SECURITY DEFINER function
/// that re-checks `is_admin()` server-side. Nothing here trusts the caller: a
/// user who is not an admin gets empty results and an error, not data.
class AdminService {
  AdminService({SupabaseClient? client})
      : _supabase = client ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  /// Whether the signed-in user is an admin. The UI uses this only to decide
  /// what to render; every query below is independently protected.
  Future<bool> isAdmin() async {
    try {
      final result = await _supabase.rpc('is_admin');
      return result == true;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> overview() async {
    final result = await _supabase.rpc('admin_overview');
    if (result is Map) return Map<String, dynamic>.from(result);
    return const {};
  }

  /// Pending identity submissions, newest first.
  Future<Result<List<ReviewQueueItem>>> identityQueue({int limit = 50}) async {
    try {
      final rows = await _supabase
          .from('identity_verifications')
          .select(
            'id, user_id, doc_type, doc_last4, doc_storage_path, status, '
            'purpose, submitted_at, verified_at, rejection_reason',
          )
          .eq('status', 'pending')
          .order('submitted_at', ascending: false)
          .limit(limit);

      final users = await _userLookup(
        (rows as List).map((r) => r['user_id']?.toString()).toList(),
      );
      return Success(
        (rows as List)
            .map((r) {
              final row = Map<String, dynamic>.from(r);
              final u = users[row['user_id']?.toString()];
              row['user_name'] = u?['name'];
              row['user_email'] = u?['email'];
              return ReviewQueueItem.fromRow(row);
            })
            .toList(),
      );
    } catch (e) {
      debugPrint('[ADMIN] identity queue failed: $e');
      return Failure(UnknownFailure(message: e.toString()));
    }
  }

  /// Pending address proofs.
  Future<Result<List<ReviewQueueItem>>> addressQueue({int limit = 50}) async {
    try {
      final rows = await _supabase
          .from('address_verifications')
          .select(
            'id, user_id, proof_type, proof_storage_path, reference_note, '
            'attested_address, status, submitted_at, verified_at, rejection_reason',
          )
          .eq('status', 'pending')
          .order('submitted_at', ascending: false)
          .limit(limit);

      final users = await _userLookup(
        (rows as List).map((r) => r['user_id']?.toString()).toList(),
      );
      return Success(
        (rows as List)
            .map((r) {
              final row = Map<String, dynamic>.from(r);
              final u = users[row['user_id']?.toString()];
              row['user_name'] = u?['name'];
              row['user_email'] = u?['email'];
              // Reuse the same shape; proof_type stands in for doc_type.
              row['doc_type'] = row['proof_type'];
              row['doc_last4'] = null;
              row['purpose'] = 'dispute_evidence';
              row['doc_storage_path'] =
                  row['proof_storage_path'] ?? '__none__';
              return ReviewQueueItem.fromRow(row);
            })
            .toList(),
      );
    } catch (e) {
      debugPrint('[ADMIN] address queue failed: $e');
      return Failure(UnknownFailure(message: e.toString()));
    }
  }

  /// A short-lived signed URL for viewing one document. Mints server-side and
  /// is recorded in the audit log.
  Future<String?> documentUrl(String storagePath) async {
    if (storagePath == '__none__' || storagePath.isEmpty) return null;
    try {
      final result = await _supabase.rpc(
        'mint_review_document_url',
        params: {'p_storage_path': storagePath},
      );
      return result as String?;
    } catch (e) {
      debugPrint('[ADMIN] mint url failed: $e');
      return null;
    }
  }

  Future<Result<Map<String, dynamic>>> decideIdentity(
    String verificationId,
    String decision, {
    String? reason,
  }) async {
    try {
      final result = await _supabase.rpc(
        'decide_identity_verification',
        params: {
          'p_verification_id': verificationId,
          'p_decision': decision,
          'p_reason': reason,
        },
      );
      if (result is Map) return Success(Map<String, dynamic>.from(result));
      return const Failure(UnknownFailure(message: 'Decision failed'));
    } catch (e) {
      return Failure(UnknownFailure(message: _cleanError(e)));
    }
  }

  Future<Result<Map<String, dynamic>>> decideAddress(
    String verificationId,
    String decision, {
    String? reason,
  }) async {
    try {
      final result = await _supabase.rpc(
        'decide_address_verification',
        params: {
          'p_verification_id': verificationId,
          'p_decision': decision,
          'p_reason': reason,
        },
      );
      if (result is Map) return Success(Map<String, dynamic>.from(result));
      return const Failure(UnknownFailure(message: 'Decision failed'));
    } catch (e) {
      return Failure(UnknownFailure(message: _cleanError(e)));
    }
  }

  /// User directory with verification standing and payout eligibility.
  Future<Result<List<AdminUserRow>>> users({int limit = 100}) async {
    try {
      final rows = await _supabase
          .from('users')
          .select(
            'id, name, email, user_type, phone, address, business_name, created_at',
          )
          .order('created_at', ascending: false)
          .limit(limit);

      final userIds = (rows as List).map((r) => r['id']?.toString()).toList();

      // Verification state per user, fetched in one round trip rather than N.
      final statusRows = await _supabase.rpc(
        'admin_verification_bulk',
        params: {'p_user_ids': userIds},
      );

      final statusByUser = <String, String>{};
      final payoutByUser = <String, bool>{};
      if (statusRows is List) {
        for (final r in statusRows) {
          if (r is Map) {
            final id = r['user_id']?.toString();
            if (id == null) continue;
            statusByUser[id] = (r['identity_status'] as String?) ?? 'none';
            payoutByUser[id] = r['can_receive_payouts'] == true;
          }
        }
      }

      return Success(
        (rows as List)
            .map((r) {
              final row = Map<String, dynamic>.from(r);
              final id = row['id']?.toString();
              row['identity_status'] = statusByUser[id] ?? 'none';
              row['can_receive_payouts'] = payoutByUser[id] ?? false;
              return AdminUserRow.fromRow(row);
            })
            .toList(),
      );
    } catch (e) {
      debugPrint('[ADMIN] users failed: $e');
      return Failure(UnknownFailure(message: e.toString()));
    }
  }

  /// Invites someone to create a Desby OS account by email.
  ///
  /// Sends the **Invite user** template (`supabase/templates/invite.html`).
  /// This is the only path in the app that invokes it — the client-facing
  /// "invite" flow shares a token for a *client* to submit measurements and
  /// never creates an auth account.
  ///
  /// Requires `service_role`: `admin.inviteUserByEmail` is a GoTrue admin call
  /// that the anon client key cannot make.
  Future<Result<void>> inviteUser({
    required String email,
    String? redirectTo,
  }) async {
    try {
      final normalised = email.trim().toLowerCase();
      if (normalised.isEmpty || !normalised.contains('@')) {
        return Failure(
          UnknownFailure(message: 'Enter a valid email address'),
        );
      }

      // Reuse the admin edge function rather than handing the browser a
      // service_role key. It also re-checks the admin role server-side.
      final res = await _supabase.functions.invoke(
        'admin-invite-user',
        body: {'email': normalised, if (redirectTo != null) 'redirect_to': redirectTo},
      );

      final Object? raw = res;
      final Map<String, dynamic> data = raw is Map
          ? Map<String, dynamic>.from(raw)
          : const <String, dynamic>{};
      if (data['success'] == true) {
        debugPrint('[ADMIN] invited $normalised');
        return Success(null);
      }
      return Failure(
        UnknownFailure(
          message: (data['error'] ?? 'Could not send the invitation')
              .toString(),
        ),
      );
    } catch (e) {
      debugPrint('[ADMIN] inviteUser failed: $e');
      return Failure(UnknownFailure(message: e.toString()));
    }
  }

  /// Recent orders for the activity view.
  Future<Result<List<Map<String, dynamic>>>> orders({int limit = 100}) async {
    try {
      final rows = await _supabase
          .from('orders')
          .select(
            'id, reference, status, payment_status, total_amount, platform_fee, '
            'tailor_payout, delivery_address, created_at, client_name',
          )
          .order('created_at', ascending: false)
          .limit(limit);
      return Success(
        (rows as List).map((r) => Map<String, dynamic>.from(r)).toList(),
      );
    } catch (e) {
      debugPrint('[ADMIN] orders failed: $e');
      return Failure(UnknownFailure(message: e.toString()));
    }
  }

  /// Recent privileged actions, for the "who did what" view.
  Future<Result<List<Map<String, dynamic>>>> auditTrail({int limit = 50}) async {
    try {
      final rows = await _supabase
          .from('admin_audit_log')
          .select('id, admin_id, action, target_table, target_id, detail, created_at')
          .order('created_at', ascending: false)
          .limit(limit);
      return Success(
        (rows as List).map((r) => Map<String, dynamic>.from(r)).toList(),
      );
    } catch (e) {
      return Failure(UnknownFailure(message: e.toString()));
    }
  }

  /// Name/email for the users referenced by a queue, in one query.
  ///
  /// A queue without the submitter's name is useless to a reviewer, and doing
  /// this per-row would be an N+1 against the largest table in the admin view.
  Future<Map<String, Map<String, String?>>> _userLookup(List<String?> ids) async {
    final wanted = ids.whereType<String>().where((e) => e.isNotEmpty).toSet();
    if (wanted.isEmpty) return {};
    try {
      final rows = await _supabase
          .from('users')
          .select('id, name, email')
          .inFilter('id', wanted.toList());
      return {
        for (final r in (rows as List))
          r['id']?.toString() ?? '': {
            'name': r['name'] as String?,
            'email': r['email'] as String?,
          },
      };
    } catch (_) {
      return {};
    }
  }

  String _cleanError(Object e) {
    final s = e.toString();
    // Strip the PostgREST envelope; the message inside is what is useful.
    final match = RegExp(r'message:\s*([^,}]+)').firstMatch(s);
    return (match?.group(1) ?? s).trim();
  }
}
