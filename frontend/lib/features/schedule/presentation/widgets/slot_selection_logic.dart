/// Selected time slot with priority ranking.
class SelectedSlot {
  final int priority;
  final DateTime? date;
  final int dayOfWeek;
  final String startTime;
  final String endTime;

  const SelectedSlot({
    required this.priority,
    this.date,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
  });

  SelectedSlot copyWith({int? priority}) {
    return SelectedSlot(
      priority: priority ?? this.priority,
      date: date,
      dayOfWeek: dayOfWeek,
      startTime: startTime,
      endTime: endTime,
    );
  }

  /// Match by dayOfWeek + startTime (ignoring date for duplicate check).
  bool matchesSlot(int day, String time) =>
      dayOfWeek == day && startTime == time;
}

/// Pure logic for 3-slot cycling selection.
///
/// Click cycle: 1 → 2 → 3 → reset(1) → 2 → 3...
/// Same slot re-tap → remove + renumber.
/// Same dayOfWeek+startTime → treated as re-tap.
class SlotSelectionLogic {
  final int maxSlots;
  final List<SelectedSlot> _slots = [];

  SlotSelectionLogic({this.maxSlots = 3});

  List<SelectedSlot> get slots => List.unmodifiable(_slots);

  /// Handle a slot tap. Returns updated slot list.
  List<SelectedSlot> handleTap({
    required DateTime date,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
  }) {
    // Check if already selected (by dayOfWeek + startTime)
    final existingIndex =
        _slots.indexWhere((s) => s.matchesSlot(dayOfWeek, startTime));

    if (existingIndex >= 0) {
      // Re-tap: remove and renumber
      _slots.removeAt(existingIndex);
      _renumber();
      return slots;
    }

    // Already at max → reset all, start fresh with this slot as priority 1
    if (_slots.length >= maxSlots) {
      _slots.clear();
    }

    // Add new slot with next priority
    _slots.add(SelectedSlot(
      priority: _slots.length + 1,
      date: date,
      dayOfWeek: dayOfWeek,
      startTime: startTime,
      endTime: endTime,
    ));

    return slots;
  }

  /// Remove slot at index and renumber.
  void removeAt(int index) {
    if (index >= 0 && index < _slots.length) {
      _slots.removeAt(index);
      _renumber();
    }
  }

  /// Clear all selections.
  void clear() {
    _slots.clear();
  }

  /// Find priority for a given slot (0 = not selected).
  int priorityFor(int dayOfWeek, String startTime) {
    final slot = _slots.cast<SelectedSlot?>().firstWhere(
          (s) => s!.matchesSlot(dayOfWeek, startTime),
          orElse: () => null,
        );
    return slot?.priority ?? 0;
  }

  void _renumber() {
    for (var i = 0; i < _slots.length; i++) {
      _slots[i] = _slots[i].copyWith(priority: i + 1);
    }
  }
}
