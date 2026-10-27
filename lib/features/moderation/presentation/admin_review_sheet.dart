import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/features/admin/providers/admin_providers.dart';
import 'package:merokotha/features/auth/providers/auth_provider.dart';
import 'package:merokotha/shared/models/listing_model.dart';
import 'package:merokotha/shared/widgets/mk_button.dart';

/// Verify / reject / suspend / restore sheet for one listing. Every decision
/// is audit-logged to the shared moderation history.
Future<void> showListingReviewSheet(
  BuildContext context,
  WidgetRef ref,
  ListingModel listing,
) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _ReviewSheetBody(listing: listing),
  );
}

class _ReviewSheetBody extends ConsumerStatefulWidget {
  final ListingModel listing;
  const _ReviewSheetBody({required this.listing});

  @override
  ConsumerState<_ReviewSheetBody> createState() => _ReviewSheetBodyState();
}

class _ReviewSheetBodyState extends ConsumerState<_ReviewSheetBody> {
  late final TextEditingController _reasonCtrl;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _reasonCtrl = TextEditingController(
      text: widget.listing.reviewReason ?? '',
    );
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _run(
    Future<bool> Function(String? reason, String adminId) action,
  ) async {
    final reason = _reasonCtrl.text.trim();
    setState(() => _busy = true);
    final adminId =
        (await ref.read(currentUserProvider.future))?.id ?? 'admin';
    final ok = await action(reason.isEmpty ? null : reason, adminId);
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Decision saved.' : 'Failed to save. Please try again.',
        ),
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listing = widget.listing;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            listing.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.grey900,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            'Status: ${listing.status.name} · Review: ${listing.verificationStatus.name}',
            style: const TextStyle(fontSize: 12, color: AppColors.grey400),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reasonCtrl,
            maxLines: 3,
            maxLength: 300,
            decoration: const InputDecoration(
              labelText: 'Review reason (shown to the lister)',
              hintText: 'e.g. Photos are blurry — please re-upload.',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          if (_busy)
            const Center(child: CircularProgressIndicator())
          else ...[
            Row(
              children: [
                Expanded(
                  child: MkButton(
                    label: 'Verify',
                    prefixIcon: Icons.verified_rounded,
                    onPressed: () => _run(
                      (reason, adminId) => ref
                          .read(adminActionProvider.notifier)
                          .reviewListing(
                            listing.id,
                            approved: true,
                            reason: reason,
                            decidedBy: adminId,
                          ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MkButton(
                    label: 'Reject',
                    variant: MkButtonVariant.danger,
                    onPressed: () {
                      if (_reasonCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Add a reason so the lister knows what to fix.',
                            ),
                          ),
                        );
                        return;
                      }
                      _run(
                        (reason, adminId) => ref
                            .read(adminActionProvider.notifier)
                            .reviewListing(
                              listing.id,
                              approved: false,
                              reason: reason,
                              decidedBy: adminId,
                            ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            MkButton(
              label: listing.isSuspended ? 'Restore' : 'Suspend',
              variant: MkButtonVariant.outline,
              prefixIcon: listing.isSuspended
                  ? Icons.restore_rounded
                  : Icons.block_rounded,
              onPressed: () => _run(
                (reason, adminId) => ref
                    .read(adminActionProvider.notifier)
                    .setListingSuspended(
                      listing.id,
                      !listing.isSuspended,
                      reason: reason,
                      decidedBy: adminId,
                    ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
