import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:usly/features/weekly/domain/weekly_models.dart';

class LocalWeeklyStore {
  LocalWeeklyStore(this._preferences);

  static const _key = 'usly.weekly.v2';
  final SharedPreferences _preferences;

  WeeklySnapshot load() {
    final raw = _preferences.getString(_key);
    if (raw == null) return WeeklySnapshot.initial();
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return WeeklySnapshot(
        drafts: (json['drafts'] as List<dynamic>)
            .map((item) => WeeklyDraft.fromJson(item as Map<String, dynamic>))
            .toList(),
        submitted: (json['submitted'] as List<dynamic>).cast<int>().toSet(),
        votes: (json['votes'] as Map<String, dynamic>).map(
          (key, value) => MapEntry(int.parse(key), value as int),
        ),
        partner: json['partner'] as int? ?? 0,
        questionIndex: json['questionIndex'] as int? ?? 0,
        revealSeen: json['revealSeen'] as bool? ?? false,
        variation: json['variation'] as int? ?? 0,
        selectedId: json['selectedId'] as int?,
      );
    } on Object {
      return WeeklySnapshot.initial();
    }
  }

  Future<void> save(WeeklySnapshot state) async {
    await _preferences.setString(
      _key,
      jsonEncode({
        'drafts': state.drafts.map((draft) => draft.toJson()).toList(),
        'submitted': state.submitted.toList(),
        'votes': state.votes.map((key, value) => MapEntry('$key', value)),
        'partner': state.partner,
        'questionIndex': state.questionIndex,
        'revealSeen': state.revealSeen,
        'variation': state.variation,
        'selectedId': state.selectedId,
      }),
    );
  }

  Future<void> reset() async {
    await _preferences.remove(_key);
  }
}
