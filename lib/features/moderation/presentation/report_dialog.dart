import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/constants/app_sizes.dart';
import 'package:merokotha/features/auth/providers/auth_provider.dart';
import 'package:merokotha/features/moderation/data/moderation_repository.dart';
import 'package:merokotha/shared/models/listing_model.dart';
import 'package:merokotha/shared/models/report_model.dart';
import 'package:merokotha/shared/widgets/mk_button.dart';

/// Report-submission dialog for a listing. Writes to `reports/{id}`;
/// status tracking lives on "My reports".
Future<void> showReportDialog(
  BuildContext context,
  WidgetRef ref,
  ListingModel listing,
) async {
  final user = ref.read(currentUserProvider).asData?.value;
  if (user == null) return;
  // Owners cannot report their own listing.
  if (listing.ownerId == user.id) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('You cannot report your own listing.')),
    );
    return;
  }
  String category = reportCategories.first;
  final detailsCtrl = TextEditingController();
  var submitting = false;

  await showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: const Text('Report this listing'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Reason',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: category,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                items: reportCategories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) =>
                    setState(() => category = v ?? reportCategories.first),
              ),
              const SizedBox(height: 12),
              const Text(
                'Details (optional)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: detailsCtrl,
                maxLines: 3,
                maxLength: 500,
                decoration: const InputDecoration(
                  hintText: 'What is wrong with this listing?',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          MkButton(
            label: 'Submit report',
            isLoading: submitting,
            onPressed: () async {
              setState(() => submitting = true);
              try {
                await ref.read(reportsRepositoryProvider).submitReport(
                  reporterId: user.id,
                  reporterName: user.name,
                  listingId: listing.id,
                  listingTitle: listing.title,
                  ownerId: listing.ownerId,
                  category: category,
                  details: detailsCtrl.text.trim(),
                );
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Report submitted. Our team will review it.',
                      ),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (_) {
                if (ctx.mounted) {
                  setState(() => submitting = false);
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to submit. Please try again.'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    ),
  );
  detailsCtrl.dispose();
}
