import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/constants/app_sizes.dart';
import 'package:merokotha/core/router/app_routes.dart';
import 'package:merokotha/core/utils/formatters.dart';
import 'package:merokotha/core/utils/validators.dart';
import 'package:merokotha/features/auth/providers/auth_provider.dart';
import 'package:merokotha/features/customer/presentation/widgets/customer_widgets.dart';
import 'package:merokotha/features/customer/providers/customers_providers.dart';
import 'package:merokotha/shared/models/listing_model.dart';
import 'package:merokotha/shared/widgets/mk_app_bar.dart';
import 'package:merokotha/shared/widgets/mk_button.dart';
import 'package:merokotha/shared/widgets/mk_text_field.dart';
import 'package:merokotha/shared/widgets/mk_widgets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:merokotha/shared/widgets/shimmer_loading.dart';

class InquireScreen extends ConsumerStatefulWidget {
  final ListingModel listing;
  const InquireScreen({super.key, required this.listing});

  @override
  ConsumerState<InquireScreen> createState() => _InquireScreenState();
}

class _InquireScreenState extends ConsumerState<InquireScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageCtrl = TextEditingController();
  DateTime _moveInDate = DateTime.now().add(const Duration(days: 7));
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill a polite default message
    _messageCtrl.text =
        'Hi, I am interested in renting this room. Could you please share more details about availability?';
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    final success = await ref
        .read(sendInquiryProvider.notifier)
        .send(
          listing: widget.listing,
          customerName: user.name,
          customerId: user.id,
          message: _messageCtrl.text.trim(),
          moveInDate: _moveInDate,
        );

    if (success && mounted) {
      setState(() {
        _submitted = true;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _moveInDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.customerPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _moveInDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final sendState = ref.watch(sendInquiryProvider);

    ref.listen(sendInquiryProvider, (_, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const MkAppBar(title: 'Send inquiry'),
      body: _submitted
          ? _SuccessView(listing: widget.listing)
          : _FormView(
              listing: widget.listing,
              formKey: _formKey,
              messageCtrl: _messageCtrl,
              moveInDate: _moveInDate,
              onPickDate: _pickDate,
              onSubmit: _submit,
              isLoading: sendState.isLoading,
            ),
    );
  }
}

class _FormView extends StatelessWidget {
  final ListingModel listing;
  final GlobalKey<FormState> formKey;
  final TextEditingController messageCtrl;
  final DateTime moveInDate;
  final VoidCallback onPickDate;
  final VoidCallback onSubmit;
  final bool isLoading;

  const _FormView({
    required this.listing,
    required this.formKey,
    required this.messageCtrl,
    required this.moveInDate,
    required this.onPickDate,
    required this.onSubmit,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.pagePadding),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: AppColors.customerLight,
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    child: listing.photoUrls.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: listing.photoUrls.first,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            placeholder: (_, _) => ShimmerLoading(
                              child: ShimmerBox(width: 60, height: 60, borderRadius: BorderRadius.zero),
                            ),
                          )
                        : Container(
                            width: 60,
                            height: 60,
                            color: AppColors.grey100,
                            child: const Icon(
                              Icons.home_outlined,
                              color: AppColors.grey400,
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          listing.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.grey900,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        PriceBadge(amount: listing.rentPerMonth),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Preferred move-in date',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.grey800,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: onPickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  border: Border.all(color: AppColors.grey100),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: AppColors.customerPrimary,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      Formatters.date(moveInDate),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.grey900,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: AppColors.grey400,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            MkTextField(
              label: listing.isAgentListed
                  ? 'Message to agent'
                  : 'Message to owner',
              hint: 'Write your inquiry...',
              controller: messageCtrl,
              validator: (v) => Validators.required(v, fieldName: 'Message'),
              maxLines: 5,
            ),

            const SizedBox(height: 8),
            const Text(
              'Be polite and mention your preferences. Owners respond faster to detailed inquiries.',
              style: TextStyle(fontSize: 12, color: AppColors.grey400),
            ),

            const SizedBox(height: 32),

            MkButton(
              label: 'Send inquiry',
              onPressed: onSubmit,
              isLoading: isLoading,
              prefixIcon: Icons.send_rounded,
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  final ListingModel listing;
  const _SuccessView({required this.listing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.pagePadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.successLight,
              borderRadius: BorderRadius.circular(AppSizes.radiusXl),
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 44,
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Inquiry sent!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.grey900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            listing.isAgentListed
                ? 'The agent will review your message and respond soon. You\'ll be notified when they reply.'
                : 'The owner will review your message and respond soon. You\'ll be notified when they reply.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.grey600,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 32),

          // Status tracker
          const InquiryStatusTracker(status: 'pending'),

          const SizedBox(height: 40),

          // Buttons
          MkButton(
            label: 'Back to listing',
            onPressed: () => context.pop(),
            variant: MkButtonVariant.outline,
          ),
          const SizedBox(height: 12),
          MkButton(
            label: 'Browse more rooms',
            onPressed: () => context.go(AppRoutes.customerHome),
            variant: MkButtonVariant.ghost,
          ),
        ],
      ),
    );
  }
}
