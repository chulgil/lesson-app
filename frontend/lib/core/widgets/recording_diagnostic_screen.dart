// Recording diagnostic screen for debugging
// Only accessible in debug mode

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import '../../models/practice_repertoire.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Diagnostic screen for recording file matching
class RecordingDiagnosticScreen extends StatefulWidget {
  const RecordingDiagnosticScreen({super.key});

  @override
  State<RecordingDiagnosticScreen> createState() =>
      _RecordingDiagnosticScreenState();
}

class _RecordingDiagnosticScreenState extends State<RecordingDiagnosticScreen> {
  bool _isLoading = true;
  String _basePath = '';
  List<String> _physicalFiles = [];
  List<String> _orphanedFiles = []; // Files on disk but not in DB
  List<_RecordingEntry> _dbEntries = [];
  int _matchedCount = 0;
  int _unmatchedCount = 0;

  @override
  void initState() {
    super.initState();
    _loadDiagnosticData();
  }

  Future<void> _loadDiagnosticData() async {
    setState(() => _isLoading = true);

    try {
      // Get base path
      final appDir = await getApplicationDocumentsDirectory();
      _basePath = appDir.path;

      // Scan physical files
      _physicalFiles = [];
      final recordingsDir = Directory('$_basePath/recordings');
      if (await recordingsDir.exists()) {
        await for (final entity in recordingsDir.list(recursive: true)) {
          if (entity is File && !entity.path.endsWith('.trim')) {
            _physicalFiles.add(entity.path);
          }
        }
      }

      // Get DB entries
      _dbEntries = [];
      final box = await Hive.openBox<PracticeRecording>('practice_recordings');
      final dbFilePaths = <String>{};
      for (final recording in box.values) {
        final file = File(recording.filePath);
        final exists = await file.exists();
        dbFilePaths.add(recording.filePath);
        _dbEntries.add(_RecordingEntry(
          id: recording.id,
          sectionId: recording.sectionId,
          filePath: recording.filePath,
          fileExists: exists,
          createdAt: recording.createdAt,
        ));
      }

      // Find orphaned files (exist on disk but not in DB)
      _orphanedFiles = _physicalFiles.where((path) => !dbFilePaths.contains(path)).toList();

      // Calculate stats
      _matchedCount = _dbEntries.where((e) => e.fileExists).length;
      _unmatchedCount = _dbEntries.where((e) => !e.fileExists).length;

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Diagnostic error: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const Scaffold(
        body: Center(child: Text('Debug mode only')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('녹음 파일 진단'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDiagnosticData,
            tooltip: '새로고침',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary Card
                  _buildSummaryCard(),
                  const SizedBox(height: AppSpacing.space4),

                  // Orphaned Files Section (files on disk but not in DB)
                  _buildOrphanedFilesSection(),
                  const SizedBox(height: AppSpacing.space4),

                  // DB Entries Section
                  _buildDbEntriesSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('요약', style: AppTypography.headingMedium),
            const SizedBox(height: AppSpacing.space3),
            _buildSummaryRow('기본 경로', _basePath, wrap: true),
            const Divider(),
            _buildSummaryRow('실제 파일 수', '${_physicalFiles.length}개'),
            _buildSummaryRow('DB 기록 수', '${_dbEntries.length}개'),
            const Divider(),
            _buildSummaryRow(
              '매칭됨 (파일 존재)',
              '$_matchedCount개',
              color: AppColors.success,
            ),
            _buildSummaryRow(
              'DB 불일치 (파일 없음)',
              '$_unmatchedCount개',
              color: _unmatchedCount > 0 ? AppColors.error : AppColors.success,
            ),
            _buildSummaryRow(
              '고아 파일 (DB에 없음)',
              '${_orphanedFiles.length}개',
              color: _orphanedFiles.isNotEmpty ? AppColors.warning : AppColors.success,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value,
      {Color? color, bool wrap = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: wrap
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.bodyMedium),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTypography.bodySmall.copyWith(
                    color: color ?? AppColors.textSecondaryLight,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: AppTypography.bodyMedium),
                Text(
                  value,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _deleteOrphanedFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        debugPrint('Deleted orphaned file: $path');
        // Also delete .trim file if exists
        final trimFile = File('$path.trim');
        if (await trimFile.exists()) {
          await trimFile.delete();
          debugPrint('Deleted orphaned trim file: $path.trim');
        }
      }
      // Reload data
      await _loadDiagnosticData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('파일이 삭제되었습니다'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint('Failed to delete orphaned file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('삭제 실패: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteAllOrphanedFiles() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('고아 파일 전체 삭제'),
        content: Text('${_orphanedFiles.length}개의 고아 파일을 모두 삭제하시겠습니까?\n\n이 파일들은 DB에 기록이 없어 복구할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('전체 삭제'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    int deletedCount = 0;
    for (final path in List<String>.from(_orphanedFiles)) {
      try {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
          deletedCount++;
        }
        // Also delete .trim file if exists
        final trimFile = File('$path.trim');
        if (await trimFile.exists()) {
          await trimFile.delete();
        }
      } catch (e) {
        debugPrint('Failed to delete: $path - $e');
      }
    }

    await _loadDiagnosticData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$deletedCount개 파일이 삭제되었습니다'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildOrphanedFilesSection() {
    return Card(
      color: _orphanedFiles.isNotEmpty
          ? AppColors.warning.withValues(alpha: 0.05)
          : null,
      child: ExpansionTile(
        initiallyExpanded: _orphanedFiles.isNotEmpty,
        title: Text(
          '고아 파일 - DB에 없음 (${_orphanedFiles.length}개)',
          style: AppTypography.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
            color: _orphanedFiles.isNotEmpty ? AppColors.warning : null,
          ),
        ),
        children: [
          if (_orphanedFiles.isEmpty)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.space4),
              child: Text('고아 파일 없음 (정상)'),
            )
          else ...[
            // Delete all button
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space4,
                vertical: AppSpacing.space2,
              ),
              child: OutlinedButton.icon(
                onPressed: _deleteAllOrphanedFiles,
                icon: const Icon(Icons.delete_sweep, color: AppColors.error),
                label: Text(
                  '고아 파일 전체 삭제 (${_orphanedFiles.length}개)',
                  style: const TextStyle(color: AppColors.error),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error),
                ),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _orphanedFiles.length,
              itemBuilder: (context, index) {
                final path = _orphanedFiles[index];
                final relativePath = path.replaceFirst('$_basePath/', '');
                final fileName = path.split('/').last;

                return ListTile(
                  dense: true,
                  leading: const Icon(
                    Icons.warning_amber,
                    size: 20,
                    color: AppColors.warning,
                  ),
                  title: Text(
                    fileName,
                    style: AppTypography.bodySmall.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                  subtitle: Text(
                    relativePath,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textTertiaryLight,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.error),
                    onPressed: () => _deleteOrphanedFile(path),
                    tooltip: '삭제',
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDbEntriesSection() {
    final unmatchedEntries = _dbEntries.where((e) => !e.fileExists).toList();
    final matchedEntries = _dbEntries.where((e) => e.fileExists).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Unmatched entries (priority)
        if (unmatchedEntries.isNotEmpty) ...[
          Card(
            color: AppColors.error.withValues(alpha: 0.05),
            child: ExpansionTile(
              initiallyExpanded: true,
              title: Text(
                '파일 없음 (${unmatchedEntries.length}개)',
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.error,
                ),
              ),
              children: [
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: unmatchedEntries.length,
                  itemBuilder: (context, index) {
                    final entry = unmatchedEntries[index];
                    return _buildEntryTile(entry);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.space3),
        ],

        // Matched entries
        Card(
          child: ExpansionTile(
            title: Text(
              '파일 존재 (${matchedEntries.length}개)',
              style: AppTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.success,
              ),
            ),
            children: [
              if (matchedEntries.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.space4),
                  child: Text('없음'),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: matchedEntries.length,
                  itemBuilder: (context, index) {
                    final entry = matchedEntries[index];
                    return _buildEntryTile(entry);
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEntryTile(_RecordingEntry entry) {
    final fileName = entry.filePath.split('/').last;
    final relativePath = entry.filePath.contains('/Documents/')
        ? entry.filePath.split('/Documents/').last
        : entry.filePath;

    return ListTile(
      dense: true,
      leading: Icon(
        entry.fileExists ? Icons.check_circle : Icons.error,
        color: entry.fileExists ? AppColors.success : AppColors.error,
        size: 20,
      ),
      title: Text(
        fileName,
        style: AppTypography.bodySmall.copyWith(
          fontFamily: 'monospace',
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Section: ${entry.sectionId}',
            style: AppTypography.caption.copyWith(
              color: AppColors.textTertiaryLight,
            ),
          ),
          Text(
            relativePath,
            style: AppTypography.caption.copyWith(
              color: entry.fileExists
                  ? AppColors.textTertiaryLight
                  : AppColors.error.withValues(alpha: 0.7),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      isThreeLine: true,
    );
  }
}

class _RecordingEntry {
  final String id;
  final String sectionId;
  final String filePath;
  final bool fileExists;
  final DateTime createdAt;

  _RecordingEntry({
    required this.id,
    required this.sectionId,
    required this.filePath,
    required this.fileExists,
    required this.createdAt,
  });
}
