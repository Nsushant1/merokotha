import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/constants/app_sizes.dart';

class ListingPhotoPicker extends StatelessWidget {
  final List<File> images;
  final ValueChanged<List<File>> onChanged;
  final String? existingPhotoUrl;
  final int existingPhotoCount;

  const ListingPhotoPicker({
    super.key,
    required this.images,
    required this.onChanged,
    this.existingPhotoUrl,
    this.existingPhotoCount = 0,
  });

  Future<void> _pick(BuildContext context) async {
    try {
      final picked = await ImagePicker().pickMultiImage(imageQuality: 75);
      if (picked.isEmpty) return;
      onChanged(picked.map((f) => File(f.path)).toList());
    } catch (_) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to pick images')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.backgroundSecondary,
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      child: InkWell(
        onTap: () => _pick(context),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Container(
          width: double.infinity,
          height: 140,
          padding: const EdgeInsets.all(AppSizes.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            border: Border.all(color: AppColors.border),
          ),
          child: images.isNotEmpty
              ? _NewImagesView(images: images)
              : existingPhotoUrl != null && existingPhotoCount > 0
              ? _ExistingPreview(
                  url: existingPhotoUrl!,
                  count: existingPhotoCount,
                )
              : const _EmptyPlaceholder(),
        ),
      ),
    );
  }
}

class _EmptyPlaceholder extends StatelessWidget {
  const _EmptyPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(
            color: AppColors.primaryLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.add_photo_alternate_rounded,
            size: 24,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Add photos',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.grey800,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Tap to select images',
          style: TextStyle(fontSize: 12, color: AppColors.grey400),
        ),
      ],
    );
  }
}

class _NewImagesView extends StatelessWidget {
  final List<File> images;
  const _NewImagesView({required this.images});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: images.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (_, i) => ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              child: Image.file(
                images[i],
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${images.length} photo${images.length == 1 ? '' : 's'} selected. Tap to change.',
          style: const TextStyle(fontSize: 12, color: AppColors.grey400),
        ),
      ],
    );
  }
}

class _ExistingPreview extends StatelessWidget {
  final String url;
  final int count;
  const _ExistingPreview({required this.url, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          child: Image.network(
            url,
            width: 100,
            height: 100,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              width: 100,
              height: 100,
              color: AppColors.grey100,
              child: const Icon(Icons.house_outlined, color: AppColors.grey400),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$count photo${count == 1 ? '' : 's'} uploaded',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.grey800,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Tap to replace with new photos',
                style: TextStyle(fontSize: 12, color: AppColors.grey400),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
