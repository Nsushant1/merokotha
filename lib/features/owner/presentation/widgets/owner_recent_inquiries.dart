import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/constants/app_sizes.dart';
import 'package:merokotha/features/auth/providers/auth_provider.dart';
import 'package:merokotha/features/owner/data/inquiry_repository.dart';
import 'package:merokotha/features/owner/presentation/widgets/inquiry_card.dart';
import 'package:merokotha/shared/models/inquiry_model.dart';
import 'package:merokotha/shared/widgets/mk_widgets.dart';

class OwnerRecentInquiries extends ConsumerWidget {
  const OwnerRecentInquiries({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(currentUserProvider)
        .when(
          data: (user) {
            if (user == null) return const SizedBox.shrink();
            return StreamBuilder<List<InquiryModel>>(
              stream: ref
                  .watch(inquiryRepositoryProvider)
                  .watchByStatus(user.id, InquiryStatus.pending),
              builder: (_, snap) {
                final inquiries = snap.data ?? [];
                if (inquiries.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(AppSizes.md),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                      boxShadow: AppSizes.shadowCard,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryLight,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.primary,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'No pending inquiries',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.grey600,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return Column(
                  children: inquiries
                      .take(2)
                      .map(
                        (inq) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: InquiryCard(
                            inquiry: inq,
                            onAccept: () => ref
                                .read(inquiryRepositoryProvider)
                                .acceptInquiry(
                                  inquiryId: inq.id,
                                  inquiry: inq,
                                  ownerName: user.name,
                                  ownerPhotoUrl: user.photoUrl,
                                ),
                            onDecline: () => ref
                                .read(inquiryRepositoryProvider)
                                .declineInquiry(inq.id),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            );
          },
          loading: () => const MkLoading(fullScreen: false),
          error: (_, _) => const SizedBox.shrink(),
        );
  }
}
