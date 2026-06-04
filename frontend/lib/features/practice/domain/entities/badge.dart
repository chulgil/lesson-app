// Badge entity for practice gamification (§2.7 뱃지 시스템).
//
// Pure domain — no Flutter/UI dependencies. Display names/labels live in
// presentation/extensions (see badge_visuals.dart).

import 'package:json_annotation/json_annotation.dart';

part 'badge.g.dart';

/// Badge category — broadly mirrors §2.7 grouping.
enum BadgeCategory {
  /// 꾸준함 — streak-based badges.
  consistency,

  /// 성실함 — completion-rate badges.
  diligence,

  /// 도전 — repertoire/challenge badges.
  challenge,

  /// 특별 — teacher praise / manual badges.
  special,
}

/// Badge type — stable IDs from §2.7.1. The string `id` mirrors enum name.
enum BadgeType {
  // Consistency
  firstPractice,
  streak3,
  streak7,
  streak30,
  streak100,

  // Diligence
  perfectWeek,
  mustMaster,
  practiceKing,

  // Challenge
  firstPiece,
  fivePieces,
  challengeKing,

  // Special
  firstLike,
  lovedStudent,
  performance,
}

extension BadgeTypeMeta on BadgeType {
  /// Stable string ID used across BE/JSON. Snake-case form per §2.7.1.
  String get id {
    switch (this) {
      case BadgeType.firstPractice:
        return 'first_practice';
      case BadgeType.streak3:
        return 'streak_3';
      case BadgeType.streak7:
        return 'streak_7';
      case BadgeType.streak30:
        return 'streak_30';
      case BadgeType.streak100:
        return 'streak_100';
      case BadgeType.perfectWeek:
        return 'perfect_week';
      case BadgeType.mustMaster:
        return 'must_master';
      case BadgeType.practiceKing:
        return 'practice_king';
      case BadgeType.firstPiece:
        return 'first_piece';
      case BadgeType.fivePieces:
        return 'five_pieces';
      case BadgeType.challengeKing:
        return 'challenge_king';
      case BadgeType.firstLike:
        return 'first_like';
      case BadgeType.lovedStudent:
        return 'loved_student';
      case BadgeType.performance:
        return 'performance';
    }
  }

  BadgeCategory get category {
    switch (this) {
      case BadgeType.firstPractice:
      case BadgeType.streak3:
      case BadgeType.streak7:
      case BadgeType.streak30:
      case BadgeType.streak100:
        return BadgeCategory.consistency;
      case BadgeType.perfectWeek:
      case BadgeType.mustMaster:
      case BadgeType.practiceKing:
        return BadgeCategory.diligence;
      case BadgeType.firstPiece:
      case BadgeType.fivePieces:
      case BadgeType.challengeKing:
        return BadgeCategory.challenge;
      case BadgeType.firstLike:
      case BadgeType.lovedStudent:
      case BadgeType.performance:
        return BadgeCategory.special;
    }
  }

  /// Whether the badge can only be granted manually (not auto-evaluated).
  bool get isManual => this == BadgeType.performance;

  static BadgeType? fromId(String id) {
    for (final t in BadgeType.values) {
      if (t.id == id) return t;
    }
    return null;
  }
}

/// Badge — immutable record of an earnable achievement.
@JsonSerializable()
class Badge {
  final String id;
  final BadgeType type;

  /// Whether the student has earned this badge.
  final bool isEarned;

  /// Earned timestamp; null when locked.
  final DateTime? earnedAt;

  const Badge({
    required this.id,
    required this.type,
    this.isEarned = false,
    this.earnedAt,
  });

  /// Convenience constructor — uses [BadgeType.id] as the badge id.
  factory Badge.locked(BadgeType type) =>
      Badge(id: type.id, type: type, isEarned: false);

  factory Badge.earned(BadgeType type, {DateTime? at}) =>
      Badge(id: type.id, type: type, isEarned: true, earnedAt: at);

  Badge copyWith({
    String? id,
    BadgeType? type,
    bool? isEarned,
    DateTime? earnedAt,
  }) {
    return Badge(
      id: id ?? this.id,
      type: type ?? this.type,
      isEarned: isEarned ?? this.isEarned,
      earnedAt: earnedAt ?? this.earnedAt,
    );
  }

  factory Badge.fromJson(Map<String, dynamic> json) => _$BadgeFromJson(json);
  Map<String, dynamic> toJson() => _$BadgeToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Badge &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          type == other.type &&
          isEarned == other.isEarned &&
          earnedAt == other.earnedAt;

  @override
  int get hashCode => Object.hash(id, type, isEarned, earnedAt);
}
