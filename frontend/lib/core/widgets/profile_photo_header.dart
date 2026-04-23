import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Header widget showing background image + profile avatar overlay.
///
/// Used in BasicInfoEditScreen, EditStudentScreen, ProfileTab, StudentDetailScreen.
class ProfilePhotoHeader extends StatelessWidget {
  final String? profileImagePath;
  final String? backgroundImagePath;
  final String initial;
  final Color avatarColor;
  final VoidCallback? onTapProfile;
  final VoidCallback? onTapBackground;
  final bool editable;
  final double backgroundHeight;
  final double avatarRadius;

  const ProfilePhotoHeader({
    super.key,
    this.profileImagePath,
    this.backgroundImagePath,
    required this.initial,
    this.avatarColor = AppColors.paperAccentSoft,
    this.onTapProfile,
    this.onTapBackground,
    this.editable = true,
    this.backgroundHeight = 180,
    this.avatarRadius = 50,
  });

  @override
  Widget build(BuildContext context) {
    // Avatar overlaps background by half its height
    final overlapHeight = avatarRadius;

    return Column(
      children: [
        SizedBox(
          height: backgroundHeight + overlapHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Background image area
              GestureDetector(
                onTap: editable ? onTapBackground : null,
                child: Container(
                  height: backgroundHeight,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildBackgroundContent(),
                      if (editable)
                        Positioned(
                          right: 12,
                          bottom: 12,
                          child: _buildEditBadge(Icons.photo_camera),
                        ),
                    ],
                  ),
                ),
              ),

              // Profile avatar (overlapping bottom of background)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: editable ? onTapProfile : null,
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            // Notebook × Score §7.50: avatar ring border = paper.
                            border: Border.all(
                              color: AppColors.paper,
                              width: 3,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: avatarRadius,
                            backgroundColor: avatarColor,
                            backgroundImage: _resolveProfileImage(),
                            child:
                                _resolveProfileImage() == null
                                    ? Text(
                                      initial,
                                      // Notebook × Score §7.50: avatar initial color = paper (profile color 배경).
                                      style: AppTypography.displayMedium
                                          .copyWith(
                                            color: AppColors.paper,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    )
                                    : null,
                          ),
                        ),
                        if (editable)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: _buildEditBadge(Icons.camera_alt),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBackgroundContent() {
    if (backgroundImagePath != null && backgroundImagePath!.isNotEmpty) {
      if (backgroundImagePath!.startsWith('http')) {
        return Image.network(
          backgroundImagePath!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildDefaultBackground(),
        );
      }
      final file = File(backgroundImagePath!);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover);
      }
    }
    return _buildDefaultBackground();
  }

  Widget _buildDefaultBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.paperAccent.withValues(alpha: 0.3),
            AppColors.paperAccentSoft.withValues(alpha: 0.2),
          ],
        ),
      ),
    );
  }

  ImageProvider? _resolveProfileImage() {
    if (profileImagePath == null || profileImagePath!.isEmpty) return null;

    if (profileImagePath!.startsWith('http')) {
      return NetworkImage(profileImagePath!);
    }

    final file = File(profileImagePath!);
    if (file.existsSync()) {
      return FileImage(file);
    }

    return null;
  }

  Widget _buildEditBadge(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.paperAccent,
        shape: BoxShape.circle,
        // Notebook × Score §7.50: Vermillion edit badge border/icon = paper.
        border: Border.all(color: AppColors.paper, width: 2),
      ),
      child: Icon(icon, size: 16, color: AppColors.paper),
    );
  }
}
