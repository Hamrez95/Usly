import 'package:supabase_flutter/supabase_flutter.dart';

class CoupleState {
  const CoupleState({
    this.coupleId,
    this.status,
    this.createdBy,
  });

  final String? coupleId;
  final String? status;
  final String? createdBy;

  bool get hasCouple => coupleId != null;
  bool get isActive => status == 'active';
  bool get isPending => status == 'pending';
}

class PairingInvite {
  const PairingInvite({
    required this.coupleId,
    required this.code,
    required this.expiresAt,
  });

  final String coupleId;
  final String code;
  final DateTime expiresAt;
}

class CoupleRepository {
  CoupleRepository(this._client);

  final SupabaseClient _client;

  Future<CoupleState> loadState() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const CoupleState();

    final membership = await _client
        .from('couple_members')
        .select('couple_id,status')
        .eq('user_id', userId)
        .eq('status', 'active')
        .maybeSingle();

    if (membership == null) return const CoupleState();
    final coupleId = membership['couple_id'] as String;
    final couple = await _client
        .from('couples')
        .select('id,status,created_by')
        .eq('id', coupleId)
        .single();

    return CoupleState(
      coupleId: couple['id'] as String,
      status: couple['status'] as String,
      createdBy: couple['created_by'] as String,
    );
  }

  Future<PairingInvite> startPairing(String displayName) async {
    final response = await _client.rpc(
      'start_pairing',
      params: {'p_display_name': displayName.trim()},
    );
    return _inviteFromRpc(response);
  }

  Future<PairingInvite> refreshPairingCode() async {
    final response = await _client.rpc('refresh_pairing_code');
    return _inviteFromRpc(response);
  }

  Future<void> acceptPairing({
    required String code,
    required String displayName,
  }) async {
    await _client.rpc(
      'accept_pairing',
      params: {
        'p_pairing_code': code.trim().toUpperCase(),
        'p_display_name': displayName.trim(),
      },
    );
  }

  PairingInvite _inviteFromRpc(dynamic response) {
    final rows = response as List<dynamic>;
    final row = rows.single as Map<String, dynamic>;
    return PairingInvite(
      coupleId: row['couple_id'] as String,
      code: row['pairing_code'] as String,
      expiresAt: DateTime.parse(row['expires_at'] as String).toLocal(),
    );
  }
}
