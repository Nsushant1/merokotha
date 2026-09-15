import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/constants/app_sizes.dart';
import 'package:merokotha/core/router/app_routes.dart';
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
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          child: const Icon(
            Icons.share_outlined,
            size: 20,
            color: AppColors.grey600,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: MkButton(
            label: listing.isAgentListed ? 'Message agent' : 'Message owner',
            height: 48,
            prefixIcon: Icons.message_outlined,
            onPressed: () {
              if (userAsync.asData?.value == null) {
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
