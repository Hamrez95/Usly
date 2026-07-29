import 'package:flutter_test/flutter_test.dart';
import 'package:usly/features/weekly/domain/weekly_models.dart';

void main() {
  test(
    'recommendations use constraints and rotate without deleting responses',
    () {
      final state = WeeklySnapshot(
        drafts: const [
          WeeklyDraft(energy: 1, need: WeeklyNeed.support),
          WeeklyDraft(energy: 4, need: WeeklyNeed.play),
        ],
        submitted: const {0, 1},
        votes: const {},
        partner: 0,
        questionIndex: 0,
        revealSeen: true,
        variation: 0,
        selectedId: null,
      );

      final first = recommend(state);
      expect(first, hasLength(3));
      expect(first.first.reason, contains('انرژی'));

      final rotated = recommend(
        WeeklySnapshot(
          drafts: state.drafts,
          submitted: state.submitted,
          votes: state.votes,
          partner: state.partner,
          questionIndex: state.questionIndex,
          revealSeen: state.revealSeen,
          variation: 1,
          selectedId: null,
        ),
      );
      expect(rotated.first.id, isNot(first.first.id));
      expect(rotated[2].title, isNot(first[2].title));
    },
  );

  test('match is true only after two identical private votes', () {
    WeeklySnapshot build(Map<int, int> votes) => WeeklySnapshot(
      drafts: const [WeeklyDraft(), WeeklyDraft()],
      submitted: const {0, 1},
      votes: votes,
      partner: 0,
      questionIndex: 0,
      revealSeen: true,
      variation: 0,
      selectedId: null,
    );

    expect(build({0: 1}).hasMatch, isFalse);
    expect(build({0: 1, 1: 2}).hasMatch, isFalse);
    expect(build({0: 1, 1: 1}).hasMatch, isTrue);
  });
}
