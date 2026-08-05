import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/bottom_sheet_handle.dart';
import '../../domain/entities/teaching_resource.dart';
import '../providers/teaching_resource_providers.dart';

/// Bottom sheet for teacher to add a reference recording resource.
///
/// Supports:
///   - Recording a new audio clip via microphone
///   - Selecting an existing file via file picker
///   - Playback preview with just_audio
///   - Title + memo fields
///   - Mock save (local path as audioUrl — real upload is Phase D)
// ignore: widget-smoke-test
class AddRecordingResourceSheet extends ConsumerStatefulWidget {
  /// Called when a resource is successfully created.
  final void Function(TeachingResource resource)? onResourceCreated;

  const AddRecordingResourceSheet({super.key, this.onResourceCreated});

  @override
  ConsumerState<AddRecordingResourceSheet> createState() =>
      _AddRecordingResourceSheetState();
}

class _AddRecordingResourceSheetState
    extends ConsumerState<AddRecordingResourceSheet> {
  final _titleController = TextEditingController();
  final _memoController = TextEditingController();
  final _uuid = const Uuid();

  // --- Recording state ---
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;

  // Timer for live duration display while recording
  Timer? _recordingTimer;
  int _recordingSeconds = 0;

  // --- File state ---
  String? _selectedFilePath;
  String? _selectedFileName;
  int? _durationSeconds; // Duration of picked / recorded file

  // --- Playback state ---
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  StreamSubscription<PlayerState>? _playerStateSub;

  // --- Submit state ---
  bool _isSubmitting = false;

  bool get _hasAudio => _selectedFilePath != null;

  bool get _canSubmit =>
      _hasAudio && _titleController.text.trim().isNotEmpty && !_isSubmitting;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_onFormChanged);
    _playerStateSub = _player.playerStateStream.listen(_onPlayerStateChanged);
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _titleController.removeListener(_onFormChanged);
    _titleController.dispose();
    _memoController.dispose();
    _recorder.dispose();
    _playerStateSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  void _onFormChanged() => setState(() {});

  void _onPlayerStateChanged(PlayerState state) {
    if (mounted) {
      setState(() {
        _isPlaying = state.playing;
      });
    }
  }

  // --- Recording ---

  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.micPermissionNeeded)),
        );
      }
      return;
    }

    // Stop playback if active
    await _stopPlayback();

    try {
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/ref_recording_${_uuid.v4()}.m4a';
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
          numChannels: 1,
        ),
        path: path,
      );
      _recordingSeconds = 0;
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _recordingSeconds++);
      });
      setState(() => _isRecording = true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.cannotStartRecording)),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    _recordingTimer?.cancel();
    _recordingTimer = null;

    final path = await _recorder.stop();
    final seconds = _recordingSeconds;
    setState(() {
      _isRecording = false;
      _recordingSeconds = 0;
    });

    if (path != null) {
      final fileName = path.split('/').last;
      setState(() {
        _selectedFilePath = path;
        _selectedFileName = fileName;
        _durationSeconds = seconds;
        if (_titleController.text.isEmpty) {
          _titleController.text = AppStrings.addRecordingTitle;
        }
      });
    }
  }

  // --- File picker ---

  Future<void> _pickFile() async {
    // Stop playback / recording first
    await _stopPlayback();
    if (_isRecording) await _stopRecording();

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['m4a', 'mp3', 'wav', 'aac'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      if (file.path == null) return;

      // Probe duration with just_audio
      int? dur;
      try {
        final probePlayer = AudioPlayer();
        await probePlayer.setFilePath(file.path!);
        final d = probePlayer.duration;
        dur = d?.inSeconds;
        await probePlayer.dispose();
      } catch (_) {
        dur = null;
      }

      setState(() {
        _selectedFilePath = file.path;
        _selectedFileName = file.name;
        _durationSeconds = dur;
        if (_titleController.text.isEmpty) {
          _titleController.text = file.name.replaceAll(RegExp(r'\.[^.]+$'), '');
        }
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.cannotSelectFile)),
        );
      }
    }
  }

  // --- Playback ---

  Future<void> _togglePlayback() async {
    if (_selectedFilePath == null) return;

    if (_isPlaying) {
      await _stopPlayback();
    } else {
      await _startPlayback();
    }
  }

  Future<void> _startPlayback() async {
    try {
      await _player.setFilePath(_selectedFilePath!);
      await _player.play();
    } catch (_) {
      // #1243 — silently swallowing this made the play button look broken
      // (손상 파일·미지원 코덱·세션 점유). 형제 실패 경로와 동일하게 안내한다.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.cannotPlayRecording)),
        );
      }
    }
  }

  Future<void> _stopPlayback() async {
    try {
      await _player.stop();
    } catch (_) {
      // Ignore
    }
  }

  // --- Clear selection ---

  Future<void> _clearSelection() async {
    await _stopPlayback();
    setState(() {
      _selectedFilePath = null;
      _selectedFileName = null;
      _durationSeconds = null;
    });
  }

  // --- Submit ---

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() => _isSubmitting = true);

    try {
      final resource = await ref
          .read(teachingResourceNotifierProvider.notifier)
          .createResource(
            type: TeachingResourceType.teacherRecording,
            title: _titleController.text.trim(),
            description: _memoController.text.trim().isNotEmpty
                ? _memoController.text.trim()
                : null,
            // Mock: use local path. Real upload (Phase D) replaces this.
            audioUrl: _selectedFilePath,
            audioDurationSeconds: _durationSeconds,
          );

      if (mounted) {
        widget.onResourceCreated?.call(resource);
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.recordingAddFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // --- UI ---

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.zero,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              const Center(
                child: BottomSheetHandle(
                  margin: EdgeInsets.only(bottom: AppSpacing.space4),
                ),
              ),

              // Title
              Text(
                AppStrings.addRecordingTitle,
                style: NotebookTypography.appBarTitle,
              ),
              const SizedBox(height: AppSpacing.space6),

              // Source buttons (hidden while recording or file selected)
              if (!_hasAudio && !_isRecording) ...[
                _RecordNewButton(onTap: _startRecording),
                const SizedBox(height: AppSpacing.space3),
                _SelectFileButton(onTap: _pickFile),
                const SizedBox(height: AppSpacing.space2),
                Text(
                  AppStrings.maxFileSize,
                  style: AppTypography.captionSmall.copyWith(
                    color: AppColors.inkTertiary,
                  ),
                ),
                const SizedBox(height: AppSpacing.space4),
              ],

              // Recording in progress indicator
              if (_isRecording) ...[
                _RecordingIndicator(
                  seconds: _recordingSeconds,
                  onStop: _stopRecording,
                ),
                const SizedBox(height: AppSpacing.space4),
              ],

              // File preview row (after pick/record)
              if (_hasAudio) ...[
                _AudioPreviewRow(
                  fileName: _selectedFileName ?? '',
                  durationSeconds: _durationSeconds,
                  isPlaying: _isPlaying,
                  onTogglePlay: _togglePlayback,
                  onDelete: _clearSelection,
                ),
                const SizedBox(height: AppSpacing.space6),

                // Title field
                _buildLabel(AppStrings.titleLabel),
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: AppStrings.recordingTitleHintText,
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  style: AppTypography.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.space4),

                // Memo field
                _buildLabel(AppStrings.memoStudentVisibleLabel),
                TextField(
                  controller: _memoController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: AppStrings.recordingMemoHint,
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  style: AppTypography.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.space6),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _canSubmit ? _submit : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.paperAccent,
                      foregroundColor: AppColors.paper,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                      minimumSize: const Size(
                        double.infinity,
                        AppSpacing.buttonHeight,
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.paper,
                            ),
                          )
                        : const Text(AppStrings.add),
                  ),
                ),
                const SizedBox(height: AppSpacing.space4),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space2),
      child: Text(
        text,
        style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

// --- Sub-widgets ---

/// Full-width outlined button for "새로 녹음하기"
class _RecordNewButton extends StatelessWidget {
  final VoidCallback onTap;

  const _RecordNewButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.mic, size: 20),
        label: const Text(AppStrings.recordNew),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          side: BorderSide(color: AppColors.inkQuaternary),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
        ),
      ),
    );
  }
}

/// Full-width outlined button for "파일에서 선택"
class _SelectFileButton extends StatelessWidget {
  final VoidCallback onTap;

  const _SelectFileButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.folder_open, size: 20),
        label: const Text(AppStrings.selectFile),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          side: BorderSide(color: AppColors.inkQuaternary),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
        ),
      ),
    );
  }
}

/// Pulsing recording indicator with elapsed time and stop button
class _RecordingIndicator extends StatelessWidget {
  final int seconds;
  final VoidCallback onStop;

  const _RecordingIndicator({required this.seconds, required this.onStop});

  String get _timeLabel {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space3,
      ),
      decoration: BoxDecoration(
        color: AppColors.paperAccentSoft,
        border: Border.all(color: AppColors.paperAccent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          // Pulsing dot
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: AppColors.paperAccent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.space2),
          Text(
            AppStrings.recordingInProgressLabel,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.paperAccent,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: AppSpacing.space2),
          Text(
            _timeLabel,
            style: AppTypography.captionSmall.copyWith(
              color: AppColors.paperAccent,
            ),
          ),
          const Spacer(),
          // Stop button
          InkWell(
            onTap: onStop,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.space1),
              child: Icon(
                Icons.stop_circle_outlined,
                size: 28,
                color: AppColors.paperAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Row showing selected audio file with play/delete actions
class _AudioPreviewRow extends StatelessWidget {
  final String fileName;
  final int? durationSeconds;
  final bool isPlaying;
  final VoidCallback onTogglePlay;
  final VoidCallback onDelete;

  const _AudioPreviewRow({
    required this.fileName,
    required this.durationSeconds,
    required this.isPlaying,
    required this.onTogglePlay,
    required this.onDelete,
  });

  String? get _durationLabel {
    if (durationSeconds == null) return null;
    final m = durationSeconds! ~/ 60;
    final s = durationSeconds! % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space3,
        vertical: AppSpacing.space2,
      ),
      decoration: BoxDecoration(
        color: AppColors.paperDark,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: Row(
        children: [
          Icon(Icons.audiotrack, size: 20, color: AppColors.paperAccent),
          const SizedBox(width: AppSpacing.space2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: AppTypography.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (_durationLabel != null)
                  Text(
                    _durationLabel!,
                    style: AppTypography.captionSmall.copyWith(
                      color: AppColors.inkTertiary,
                    ),
                  ),
              ],
            ),
          ),
          // Play/pause button
          IconButton(
            onPressed: onTogglePlay,
            icon: Icon(
              isPlaying ? Icons.pause : Icons.play_arrow,
              color: AppColors.ink,
            ),
            iconSize: 24,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: EdgeInsets.zero,
          ),
          // Delete button
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.close, color: AppColors.inkTertiary),
            iconSize: 20,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}
