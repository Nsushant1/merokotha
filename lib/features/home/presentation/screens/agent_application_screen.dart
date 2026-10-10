import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/constants/app_sizes.dart';
import 'package:merokotha/core/utils/validators.dart';
import 'package:merokotha/features/auth/providers/auth_provider.dart';
import 'package:merokotha/features/home/providers/agent_application_providers.dart';
import 'package:merokotha/shared/models/agent_application_model.dart';
import 'package:merokotha/shared/models/user_model.dart';
import 'package:merokotha/shared/widgets/mk_button.dart';
import 'package:merokotha/shared/widgets/mk_text_field.dart';

/// "Become an Agent" application.
///
/// Filing an application grants nothing — the Agent interface unlocks only
/// after an admin approves it. Shows the live application status when one
/// already exists (pending review / rejected with reason).
class AgentApplicationScreen extends ConsumerStatefulWidget {
  const AgentApplicationScreen({super.key});

  @override
  ConsumerState<AgentApplicationScreen> createState() =>
      _AgentApplicationScreenState();
}

class _AgentApplicationScreenState
    extends ConsumerState<AgentApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _prefilled = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _locationCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _prefill(UserModel user, AgentApplicationModel? existing) {
    if (_prefilled) return;
    _prefilled = true;
    _nameCtrl.text = existing?.fullName ?? user.name;
    _phoneCtrl.text = existing?.phone ?? user.phone;
    _locationCtrl.text = existing?.location ?? user.location ?? '';
    _notesCtrl.text = existing?.notes ?? '';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final ok = await ref
        .read(agentApplicationFormProvider.notifier)
        .submit(
          fullName: _nameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          location: _locationCtrl.text.trim(),
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        );
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Application submitted for review.'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final appAsync = ref.watch(myAgentApplicationProvider);
    final formState = ref.watch(agentApplicationFormProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(
        title: const Text('Become an Agent'),
        backgroundColor: Colors.white,
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load: $e')),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Not signed in'));
          }
          if (user.agentStatus == AgentStatus.verified) {
            return _StatusView(
              icon: Icons.verified_rounded,
              iconColor: AppColors.success,
              title: 'You are a verified agent',
              subtitle: 'Use the Agent Hub to post rooms on behalf of owners.',
              actionLabel: 'Open Agent Hub',
              onAction: () => context.go('/agent/home'),
            );
          }
          return appAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Failed to load: $e')),
            data: (existing) {
              _prefill(user, existing);
              if (existing?.status == AgentApplicationStatus.pending) {
                return const _StatusView(
                  icon: Icons.hourglass_top_rounded,
                  iconColor: AppColors.warning,
                  title: 'Application under review',
                  subtitle:
                      'An admin will review your application soon. Posting unlocks after approval.',
                );
              }
              return SingleChildScrollView(
                padding: const EdgeInsets.all(AppSizes.pagePadding),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (existing?.status ==
                          AgentApplicationStatus.rejected) ...[
                        _RejectedBanner(reason: existing?.reason),
                        const SizedBox(height: 16),
                      ],
                      Text(
                        'Apply to post rooms for owners. Approval is manual and usually takes a day or two.',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: AppColors.grey600,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: AppSizes.shadowCard,
                        ),
                        child: Column(
                          children: [
                            MkTextField(
                              controller: _nameCtrl,
                              label: 'Full name',
                              hint: 'e.g. Hari Thapa',
                              validator: Validators.name,
                            ),
                            const SizedBox(height: 16),
                            MkTextField(
                              controller: _phoneCtrl,
                              label: 'Phone number',
                              hint: '98XXXXXXXX',
                              validator: Validators.phone,
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 16),
                            MkTextField(
                              controller: _locationCtrl,
                              label: 'Location',
                              hint: 'e.g. Kathmandu, Baneshwor',
                              validator: (v) =>
                                  Validators.required(v, fieldName: 'Location'),
                            ),
                            const SizedBox(height: 16),
                            MkTextField(
                              controller: _notesCtrl,
                              label: 'Notes (optional)',
                              hint: 'Experience, areas you cover...',
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (formState.error != null) ...[
                        Text(
                          formState.error!,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      MkButton(
                        label: existing == null
                            ? 'Submit application'
                            : 'Re-submit application',
                        onPressed: _submit,
                        isLoading: formState.isLoading,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _StatusView extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _StatusView({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.pagePaddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.grey50,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 34, color: iconColor),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.dmSans(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.grey900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: AppColors.grey600,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              MkButton(label: actionLabel!, onPressed: onAction),
            ],
          ],
        ),
      ),
    );
  }
}

class _RejectedBanner extends StatelessWidget {
  final String? reason;
  const _RejectedBanner({this.reason});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Previous application was not approved.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.error,
            ),
          ),
          if (reason != null && reason!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Reason: $reason',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.error,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 4),
          const Text(
            'You may update the details below and re-apply.',
            style: TextStyle(fontSize: 13, color: AppColors.grey600),
          ),
        ],
      ),
    );
  }
}
