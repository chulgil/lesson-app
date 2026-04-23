import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Reusable circular profile image widget.
///
/// Shows the profile image if available, otherwise shows
/// an initial letter avatar with a colored background.
class ProfileImageWidget extends StatelessWidget {
  final String? imagePath;
  final String name;
  final double radius;
  final VoidCallback? onTap;
  final bool showEditIcon;

  const ProfileImageWidget({
    super.key,
    this.imagePath,
    required this.name,
    this.radius = 40,
    this.onTap,
    this.showEditIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          CircleAvatar(
            radius: radius,
            backgroundColor: AppColors.paperAccent.withValues(alpha: 0.1),
            backgroundImage: _resolveImage(),
            child:
                _resolveImage() == null
                    ? Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: AppTypography.headingLarge.copyWith(
                        color: AppColors.paperAccent,
                        fontSize: radius * 0.8,
                      ),
                    )
                    : null,
          ),
          if (showEditIcon)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.paperAccent,
                  shape: BoxShape.circle,
                  // Notebook × Score §7.50: Vermillion edit badge border/icon = paper.
                  border: Border.all(color: AppColors.paper, width: 2),
                ),
                child: Icon(
                  Icons.camera_alt,
                  size: radius * 0.35,
                  color: AppColors.paper,
                ),
              ),
            ),
        ],
      ),
    );
  }

  ImageProvider? _resolveImage() {
    if (imagePath == null || imagePath!.isEmpty) return null;

    if (imagePath!.startsWith('http')) {
      return NetworkImage(imagePath!);
    }

    final file = File(imagePath!);
    if (file.existsSync()) {
      return FileImage(file);
    }

    return null;
  }
}
