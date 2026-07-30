// Journey sticker catalog entities (P3b Daily Satisfaction — doc 46 §5).
//
// Pure computed catalog — no accrual table. The backend re-aggregates
// existing log tables (practice_logs, practice_journal_volumes,
// practice_recordings) and the streak SSOT on every read, so a sticker's
// `current`/`achieved` values are retroactive: a student who practiced
// before this catalog shipped sees correct progress immediately.

import 'package:json_annotation/json_annotation.dart';

part 'journey_sticker.g.dart';

/// Catalog section a sticker belongs to.
enum StickerFamily { practice, journey, streak, growth }

/// How `target`/`current` should be read for a sticker.
enum StickerUnit { minutes, days, count }

/// A single achievement in the journey sticker catalog.
@JsonSerializable()
class JourneySticker {
  /// Globally unique, stable identifier (e.g. "practice_minutes_10h").
  final String key;
  final StickerFamily family;

  /// Sub-group within [family] for tier-ladder rendering (e.g. "practice"
  /// has two independent ladders: practice_minutes and practice_days).
  final String metric;

  /// 1-based position within this sticker's metric ladder.
  final int tier;
  final int target;
  final int current;
  final bool achieved;
  final StickerUnit unit;

  const JourneySticker({
    required this.key,
    required this.family,
    required this.metric,
    required this.tier,
    required this.target,
    required this.current,
    required this.achieved,
    required this.unit,
  });

  factory JourneySticker.fromJson(Map<String, dynamic> json) =>
      _$JourneyStickerFromJson(json);

  Map<String, dynamic> toJson() => _$JourneyStickerToJson(this);

  /// Progress toward [target] in the 0.0–1.0 range.
  double get progress {
    if (achieved) return 1.0;
    if (target <= 0) return 0.0;
    return (current / target).clamp(0.0, 1.0);
  }
}

/// Full computed journey sticker catalog for a student.
@JsonSerializable(explicitToJson: true)
class JourneyStickerCatalog {
  final String studentId;
  final List<JourneySticker> stickers;

  const JourneyStickerCatalog({
    required this.studentId,
    this.stickers = const [],
  });

  factory JourneyStickerCatalog.fromJson(Map<String, dynamic> json) =>
      _$JourneyStickerCatalogFromJson(json);

  Map<String, dynamic> toJson() => _$JourneyStickerCatalogToJson(this);

  /// Stickers grouped by [StickerFamily], preserving catalog order within
  /// each group (metric ladders are emitted low-tier-first by the backend).
  Map<StickerFamily, List<JourneySticker>> get byFamily {
    final grouped = <StickerFamily, List<JourneySticker>>{};
    for (final sticker in stickers) {
      grouped.putIfAbsent(sticker.family, () => []).add(sticker);
    }
    return grouped;
  }

  /// Count of achieved stickers (for a compact "N/M" summary).
  int get achievedCount => stickers.where((s) => s.achieved).length;
}
