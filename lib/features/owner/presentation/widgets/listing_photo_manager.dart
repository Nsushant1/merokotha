import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/constants/app_sizes.dart';

/// Full photo manager for the listing upload/edit forms.
///
/// - Existing photos (network URLs) can be removed, reordered, and the
///   first photo is always the cover.
/// - New photos (local files) can be added alongside existing ones and
///   removed before upload.
/// - The parent owns both lists and merges them on submit
///   (`keptUrls + uploadedNewFiles`, cover first).
class ListingPhotoManager extends StatelessWidget {
  final List<String> existingUrls;
  final ValueChanged<List<String>> onExistingChanged;
  final List<File> newImages;
  final ValueChanged<List<File>> onNewChanged;

  const ListingPhotoManager({
    super.key,
    required this.existingUrls,
    required this.onExistingChanged,
    required this.newImages,
    required this.onNewChanged,
  });

  Future<void> _pick(BuildContext context) async {
    try {
      final picked = await ImagePicker().pickMultiImage(imageQuality: 75);
      if (picked.isEmpty) return;
      onNewChanged([
        ...newImages,
        ...picked.map((f) => File(f.path)),
      ]);
    } catch (_) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to pick images')));
    }
  }

  void _moveExisting(int from, int to) {
    if (to < 0 || to >= existingUrls.length) return;
    final list = List<String>.from(existingUrls);
    final item = list.removeAt(from);
    list.insert(to, item);
    onExistingChanged(list);
  }

  @override
  Widget build(BuildContext context) {
    final total = existingUrls.length + newImages.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Photos',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.grey900,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              total == 0 ? 'No photos yet' : '$total photo${total == 1 ? '' : 's'} · first is cover',
              style: const TextStyle(fontSize: 12, color: AppColors.grey400),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _pick(context),
              icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (total == 0)
          GestureDetector(
            onTap: () => _pick(context),
            child: Container(
              width: double.infinity,
              height: 140,
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                border: Border.all(color: AppColors.border),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_rounded,
                    size: 32,
                    color: AppColors.primary,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap to add photos',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.grey800,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: total + 1,
            itemBuilder: (_, i) {
              if (i == total) {
                // Add tile.
                return GestureDetector(
                  onTap: () => _pick(context),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.backgroundSecondary,
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      size: 28,
                      color: AppColors.grey400,
                    ),
                  ),
                );
              }
              if (i < existingUrls.length) {
                return _PhotoTile(
                  image: CachedNetworkImage(
                    imageUrl: existingUrls[i],
                    fit: BoxFit.cover,
                    placeholder: (_, _) => Container(
                      color: AppColors.grey100,
                    ),
                    errorWidget: (_, _, _) => Container(
                      color: AppColors.grey100,
                      child: const Icon(
                        Icons.house_outlined,
                        color: AppColors.grey400,
                      ),
                    ),
                  ),
                  isCover: i == 0,
                  onMoveLeft: i > 0 ? () => _moveExisting(i, i - 1) : null,
                  onMoveRight: i < existingUrls.length - 1
                      ? () => _moveExisting(i, i + 1)
                      : null,
                  onRemove: () => onExistingChanged(
                    List<String>.from(existingUrls)..removeAt(i),
                  ),
                );
              }
              final ni = i - existingUrls.length;
              return _PhotoTile(
                image: Image.file(newImages[ni], fit: BoxFit.cover),
                isCover: i == 0,
                isNew: true,
                onRemove: () => onNewChanged(
                  List<File>.from(newImages)..removeAt(ni),
                ),
              );
            },
          ),
      ],
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final Widget image;
  final bool isCover;
  final bool isNew;
  final VoidCallback? onMoveLeft;
  final VoidCallback? onMoveRight;
  final VoidCallback onRemove;

  const _PhotoTile({
    required this.image,
    required this.onRemove,
    this.isCover = false,
    this.isNew = false,
    this.onMoveLeft,
    this.onMoveRight,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          child: image,
        ),
        if (isCover)
          Positioned(
            top: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              ),
              child: const Text(
                'Cover',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        if (isNew)
          Positioned(
            top: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.info,
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              ),
              child: const Text(
                'New',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        Positioned(
          top: 2,
          right: 2,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
            ),
          ),
        ),
        if (onMoveLeft != null || onMoveRight != null)
          Positioned(
            bottom: 2,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (onMoveLeft != null)
                  _nudge(Icons.chevron_left_rounded, onMoveLeft!),
                if (onMoveRight != null)
                  _nudge(Icons.chevron_right_rounded, onMoveRight!),
              ],
            ),
          ),
      ],
    );
  }

  Widget _nudge(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 24,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: const BoxDecoration(
        color: Colors.black54,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 16, color: Colors.white),
    ),
  );
}
