import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/features/analytics/data/analytics_repository.dart';
import 'package:merokotha/shared/models/analytics_model.dart';

/// Public call + WhatsApp contact buttons. Rendered only for the numbers
/// that are present. Taps are logged as analytics events.
class ContactButtons extends ConsumerWidget {
  final String? publicPhone;
  final String? whatsappNumber;
  final String listingId;
  final String? ownerId;

  const ContactButtons({
    super.key,
    required this.publicPhone,
    required this.whatsappNumber,
    required this.listingId,
    this.ownerId,
  });

  bool get hasAny =>
      (publicPhone?.isNotEmpty ?? false) ||
      (whatsappNumber?.isNotEmpty ?? false);

  Future<void> _log(WidgetRef ref, AnalyticsEventType type) async {
    final visitor = ref.read(visitorIdProvider);
    await ref
        .read(analyticsRepositoryProvider)
        .logEvent(
          listingId: listingId,
          ownerId: ownerId,
          type: type,
          visitorId: visitor,
        );
  }

  Future<void> _call(BuildContext context, WidgetRef ref) async {
    final phone = publicPhone!.trim();
    await _log(ref, AnalyticsEventType.call);
    final uri = Uri.parse('tel:$phone');
    if (!await launchUrl(uri)) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not place call.')));
      }
    }
  }

  Future<void> _whatsapp(BuildContext context, WidgetRef ref) async {
    var number = whatsappNumber!.trim().replaceAll(RegExp(r'[^0-9+]'), '');
    if (number.startsWith('+')) number = number.substring(1);
    await _log(ref, AnalyticsEventType.whatsapp);
    final uri = Uri.parse('https://wa.me/$number');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not open WhatsApp.')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!hasAny) return const SizedBox.shrink();
    return Row(
      children: [
        if (publicPhone?.isNotEmpty ?? false)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _call(context, ref),
              icon: const Icon(
                Icons.call_outlined,
                size: 18,
                color: AppColors.success,
              ),
              label: const Text(
                'Call',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.success,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.success, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size(0, 48),
              ),
            ),
          ),
        if ((publicPhone?.isNotEmpty ?? false) &&
            (whatsappNumber?.isNotEmpty ?? false))
          const SizedBox(width: 12),
        if (whatsappNumber?.isNotEmpty ?? false)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _whatsapp(context, ref),
              icon: const Icon(
                Icons.chat_outlined,
                size: 18,
                color: AppColors.primary,
              ),
              label: const Text(
                'WhatsApp',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size(0, 48),
              ),
            ),
          ),
      ],
    );
  }
}
