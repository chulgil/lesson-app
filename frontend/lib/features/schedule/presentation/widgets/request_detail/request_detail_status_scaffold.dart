import 'package:flutter/material.dart';

import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../../../../../core/widgets/notebook/notebook_surfaces.dart';

/// Shared loading/error/not-found scaffold for [RequestDetailScreen] — same
/// AppBar title + paper background across all three non-data
/// `AsyncValue.when` branches.
class RequestDetailStatusScaffold extends StatelessWidget {
  final Widget body;

  const RequestDetailStatusScaffold({super.key, required this.body});

  @override
  Widget build(BuildContext context) {
    return NotebookScreenScaffold(
      backgroundColor: AppColors.paper,
      appBar: const NotebookDetailAppBar(title: AppStrings.requestDetailTitle),
      body: body,
    );
  }
}
