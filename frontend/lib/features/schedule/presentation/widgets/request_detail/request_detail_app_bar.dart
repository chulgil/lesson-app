import 'package:flutter/material.dart';

import '../../../../../core/theme/notebook_typography.dart';
import '../../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../../../domain/entities/unified_lesson_request.dart';
import '../../extensions/unified_lesson_request_visuals.dart';

/// Builds the chat-style AppBar for [RequestDetailScreen]:
/// "< 상대이름 (레슨타입)" with a tap-to-open profile title and a "more" action.
///
/// Tap handling stays with the caller: [onTitleTap] opens the opponent
/// profile bottom sheet, [onMoreTap] opens the more-actions menu.
PreferredSizeWidget buildRequestDetailAppBar({
  required UnifiedLessonRequest request,
  required String opponentName,
  required String? academyName,
  required VoidCallback onTitleTap,
  required VoidCallback onMoreTap,
}) {
  final titleText =
      request.isAcademy && academyName != null
          ? '$academyName $opponentName (${request.typeDisplayLabel})'
          : '$opponentName (${request.typeDisplayLabel})';

  return NotebookDetailAppBar(
    titleWidget: GestureDetector(
      onTap: onTitleTap,
      child: Text(titleText, style: NotebookTypography.appBarTitle),
    ),
    actions: const [DetailAppBarAction.more],
    onAction: (action) {
      if (action == DetailAppBarAction.more) {
        onMoreTap();
      }
    },
  );
}
