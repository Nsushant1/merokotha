import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/constants/app_sizes.dart';
import 'package:merokotha/core/router/app_routes.dart';
import 'package:merokotha/core/utils/formatters.dart';
import 'package:merokotha/features/auth/providers/pending_inquiry_provider.dart';
import 'package:merokotha/shared/models/listing_model.dart';
import 'package:merokotha/shared/widgets/login_sheet.dart';
import 'package:merokotha/shared/widgets/mk_button.dart';

class RoomBottomCTA extends ConsumerWidget {
  final ListingModel listing;
  final AsyncValue userAsync;

  const RoomBottomCTA({
    super.key,
    required this.listing,
    required this.userAsync,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) => Container(
    padding: EdgeInsets.fromLTRB(
      AppSizes.pagePadding,
      AppSizes.md,
      AppSizes.pagePadding,
      MediaQuery.of(context).padding.bottom + AppSizes.md,
    ),
    decoration: BoxDecoration(
      color: Colors.white,
      border: const Border(top: BorderSide(color: AppColors.border)),
      boxShadow: AppSizes.shadowRaised,
    ),
    child: Row(
      children: [
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            onTap: () {
              final price = Formatters.amount(listing.rentPerMonth);
              final address = listing.address ?? '';
              Share.share(
                'Check out this ${listing.roomTypeLabel} on MeroKotha: '
                '${listing.title} - Rs. $price/mo'
                '${address.isNotEmpty ? ' at $address' : ''}',
              );
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: const Icon(
                Icons.share_outlined,
                size: 20,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: MkButton(
            label: listing.isAgentListed ? 'Message agent' : 'Message owner',
            height: 48,
            prefixIcon: Icons.message_outlined,
            variant: MkButtonVariant.accent,
            onPressed: () {
              if (userAsync.asData?.value == null) {
                // Remember the room so post-sign-in can resume straight
                // into its inquiry flow instead of losing the selection.
                ref.read(pendingInquiryProvider.notifier).set(listing);
                showLoginSheet(context);
                return;
              }
              context.push(
                AppRoutes.inquire.replaceAll(':id', listing.id),
                extra: listing,
              );
            },
          ),
        ),
      ],
    ),
  );
}
