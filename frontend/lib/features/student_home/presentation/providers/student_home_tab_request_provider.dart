import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One-shot request to switch the student-home bottom-nav tab from a descendant
/// widget (e.g. trial bookings "더보기" → Lessons tab). [StudentHomeScreen]
/// listens, applies the index, then resets to null. null = no pending request.
///
/// #749 — replaces a no-op SnackBar that only told the user where to look.
final studentHomeTabRequestProvider = StateProvider<int?>((ref) => null);
