import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/constants/app_sizes.dart';
import 'package:merokotha/features/auth/data/user_repository.dart';
import 'package:merokotha/shared/models/listing_model.dart';
import 'package:merokotha/shared/models/user_model.dart';
import 'package:merokotha/shared/widgets/mk_widgets.dart';

/// "Listed by" card on the room detail screen.
///
/// Owner-posted listings render exactly as before (owner name + House Owner
/// label). For agent-posted listings ([ListingModel.isAgentListed]) the
/// real-owner contact stored on the listing is masked: the card shows the
/// agent's public profile instead (fetched via [UserRepository]) with an
/// Agent badge. The owner name/phone are never rendered here.
class RoomOwnerCard extends ConsumerStatefulWidget {
  final ListingModel listing;
  const RoomOwnerCard({super.key, required this.listing});

  @override
  ConsumerState<RoomOwnerCard> createState() => _RoomOwnerCardState();
}

class _RoomOwnerCardState extends ConsumerState<RoomOwnerCard> {
  Future<UserModel?>? _agentFuture;

  @override
  void initState() {
    super.initState();
    if (widget.listing.isAgentListed) {
      _agentFuture = ref
          .read(userRepositoryProvider)
          .getUser(widget.listing.ownerId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final listing = widget.listing;
    if (!listing.isAgentListed) {
      return _OwnerCard(
        name: listing.ownerName,
        photoUrl: listing.ownerPhotoUrl,
      );
    }

    return FutureBuilder<UserModel?>(
      future: _agentFuture,
      builder: (context, snap) {
        final agent = snap.data;
        return _AgentCard(
          name: agent?.name ?? 'Agent',
          photoUrl: listing.ownerPhotoUrl ?? agent?.photoUrl,
        );
      },
    );
  }
}

/// Original owner rendering — unchanged.
class _OwnerCard extends StatelessWidget {
  final String name;
  final String? photoUrl;
  const _OwnerCard({required this.name, required this.photoUrl});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSizes.md),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
    ),
    child: Row(
      children: [
        UserAvatar(name: name, photoUrl: photoUrl, size: 44),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.grey900,
              ),
            ),
            const Text(
              'House Owner',
              style: TextStyle(fontSize: 12, color: AppColors.grey400),
            ),
          ],
        ),
      ],
    ),
  );
}

/// Agent rendering — same layout, Agent badge instead of House Owner label.
class _AgentCard extends StatelessWidget {
  final String name;
  final String? photoUrl;
  const _AgentCard({required this.name, required this.photoUrl});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSizes.md),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
    ),
    child: Row(
      children: [
        UserAvatar(name: name, photoUrl: photoUrl, size: 44),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.grey900,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.agentLight,
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
                child: const Text(
                  'Agent',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.agentPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
