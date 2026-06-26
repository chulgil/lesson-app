import 'package:flutter/material.dart';

import '../../domain/entities/challenge.dart';

/// Presentation-layer visuals for [ChallengeType].
///
/// Domain stays pure (no display getters) — icons live here as [IconData]
/// per the C2 consistency contract (no emoji/icon string getters).
extension ChallengeTypeVisuals on ChallengeType {
  IconData get icon => switch (this) {
    ChallengeType.practiceDays => Icons.event,
    ChallengeType.practiceMinutes => Icons.timer,
    ChallengeType.recordings => Icons.mic,
    ChallengeType.lessons => Icons.music_note,
    ChallengeType.streak => Icons.local_fire_department,
    ChallengeType.pointsEarned => Icons.diamond,
  };
}
