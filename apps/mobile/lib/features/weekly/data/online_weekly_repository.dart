import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:usly/features/weekly/domain/weekly_models.dart';

class OnlineExperience {
  const OnlineExperience({
    required this.id,
    required this.rank,
    required this.kind,
    required this.title,
    required this.duration,
    required this.budget,
    required this.setting,
    required this.reason,
    required this.instructions,
  });

  final String id;
  final int rank;
  final String kind;
  final String title;
  final String duration;
  final String budget;
  final String setting;
  final String reason;
  final String instructions;

  factory OnlineExperience.fromJson(Map<String, dynamic> json) {
    return OnlineExperience(
      id: json['id'] as String,
      rank: json['rank'] as int,
      kind: json['kind'] as String,
      title: json['title_fa'] as String,
      duration: json['duration_fa'] as String,
      budget: json['budget_fa'] as String,
      setting: json['setting_fa'] as String,
      reason: json['reason_fa'] as String,
      instructions: json['instructions_fa'] as String,
    );
  }
}

class OnlineWeeklyState {
  const OnlineWeeklyState({
    this.syncId,
    this.status,
    this.responseCount = 0,
    this.voteCount = 0,
    this.selectedOptionId,
    this.ownVoteId,
    this.hasSubmitted = false,
    this.options = const [],
  });

  final String? syncId;
  final String? status;
  final int responseCount;
  final int voteCount;
  final String? selectedOptionId;
  final String? ownVoteId;
  final bool hasSubmitted;
  final List<OnlineExperience> options;

  bool get waitingForPartner => hasSubmitted && responseCount < 2;
  bool get readyToVote =>
      responseCount == 2 && selectedOptionId == null && ownVoteId == null;
  bool get waitingForPartnerVote =>
      ownVoteId != null && voteCount < 2 && selectedOptionId == null;
  bool get noMatch =>
      ownVoteId != null && voteCount == 2 && selectedOptionId == null;
  bool get hasMatch => selectedOptionId != null;
}

class OnlineWeeklyRepository {
  OnlineWeeklyRepository(this._client);

  final SupabaseClient _client;

  Future<OnlineWeeklyState> load(String coupleId) async {
    final weekStart = _currentWeekStartUtc();
    final sync = await _client
        .from('weekly_syncs')
        .select(
          'id,status,response_count,vote_count,selected_option_id,week_start',
        )
        .eq('couple_id', coupleId)
        .eq('week_start', weekStart)
        .maybeSingle();

    if (sync == null) return const OnlineWeeklyState();
    final syncId = sync['id'] as String;
    final response = await _client
        .from('weekly_sync_responses')
        .select('weekly_sync_id')
        .eq('weekly_sync_id', syncId)
        .maybeSingle();

    final optionRows = await _client
        .from('weekly_options')
        .select()
        .eq('weekly_sync_id', syncId)
        .order('rank');

    final vote = await _client
        .from('weekly_votes')
        .select('option_id')
        .eq('weekly_sync_id', syncId)
        .maybeSingle();

    return OnlineWeeklyState(
      syncId: syncId,
      status: sync['status'] as String,
      responseCount: sync['response_count'] as int,
      voteCount: sync['vote_count'] as int,
      selectedOptionId: sync['selected_option_id'] as String?,
      ownVoteId: vote?['option_id'] as String?,
      hasSubmitted: response != null,
      options: (optionRows as List<dynamic>)
          .map((row) => OnlineExperience.fromJson(row as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<void> submit(WeeklyDraft draft) async {
    await _client.rpc(
      'submit_weekly_response',
      params: {
        'p_energy_level': draft.energy,
        'p_need_category': draft.need.name,
        'p_duration_band': draft.duration.name,
        'p_budget_band': draft.budget.name,
        'p_setting_band': draft.setting.name,
      },
    );
  }

  Future<void> vote({required String syncId, required String optionId}) async {
    await _client.rpc(
      'vote_weekly_option',
      params: {'p_weekly_sync_id': syncId, 'p_option_id': optionId},
    );
  }

  String _currentWeekStartUtc() {
    final now = DateTime.now().toUtc();
    final monday = DateTime.utc(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - DateTime.monday));
    return '${monday.year.toString().padLeft(4, '0')}-'
        '${monday.month.toString().padLeft(2, '0')}-'
        '${monday.day.toString().padLeft(2, '0')}';
  }
}
