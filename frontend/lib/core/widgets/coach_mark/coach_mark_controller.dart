import 'package:flutter/material.dart';

import 'coach_mark_overlay.dart';

/// A single step in a CoachMark tutorial sequence.
class CoachMarkStep {
  final String id;
  final GlobalKey targetKey;
  final String title;
  final String description;
  final String actionLabel;
  final CoachMarkPosition position;

  /// Called when the action button is tapped.
  /// If null, the controller automatically advances to the next step.
  final VoidCallback? onAction;

  const CoachMarkStep({
    required this.id,
    required this.targetKey,
    required this.title,
    required this.description,
    required this.actionLabel,
    this.position = CoachMarkPosition.below,
    this.onAction,
  });
}

/// Manages a sequence of [CoachMarkStep]s.
///
/// Usage:
/// ```dart
/// final controller = CoachMarkController(steps: [...]);
/// controller.start();
/// ```
class CoachMarkController extends ChangeNotifier {
  final List<CoachMarkStep> steps;

  int _currentIndex = 0;
  bool _isActive = false;

  CoachMarkController({required this.steps});

  /// The currently visible step, or null if inactive.
  CoachMarkStep? get currentStep =>
      _isActive && _currentIndex < steps.length ? steps[_currentIndex] : null;

  bool get isActive => _isActive;
  int get currentIndex => _currentIndex;
  int get totalSteps => steps.length;

  /// Starts the sequence from the first step.
  void start() {
    _isActive = true;
    _currentIndex = 0;
    notifyListeners();
  }

  /// Advances to the next step, or dismisses if at the end.
  void next() {
    _currentIndex++;
    if (_currentIndex >= steps.length) {
      dismiss();
    } else {
      notifyListeners();
    }
  }

  /// Hides the coach mark overlay and resets the index.
  void dismiss() {
    _isActive = false;
    _currentIndex = 0;
    notifyListeners();
  }
}
