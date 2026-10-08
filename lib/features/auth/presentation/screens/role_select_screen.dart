import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/constants/app_sizes.dart';
import 'package:merokotha/core/constants/app_strings.dart';
import 'package:merokotha/core/router/app_routes.dart';
import 'package:merokotha/features/auth/presentation/widgets/role_card.dart';
import 'package:merokotha/shared/models/user_model.dart';
import 'package:merokotha/shared/widgets/mk_button.dart';

final _selectedRoleProvider = StateProvider<UserRole?>((ref) => null);

// Secret admin code — change this in production
const _adminSecretCode = 'admin123';

class RoleSelectScreen extends ConsumerWidget {
  const RoleSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(_selectedRoleProvider);

    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.pagePaddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 32),

                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(AppStrings.chooseRole, style: textTheme.displayMedium),
                  const SizedBox(height: 8),
                  Text(
                    'This helps us personalise your experience.\nYou can switch roles later from your profile.',
                    style: textTheme.bodyLarge?.copyWith(
                      color: AppColors.grey600,
                    ),
                  ),

                  const SizedBox(height: 32),

                  RoleCard(
                    title: AppStrings.owner,
                    description: AppStrings.ownerDesc,
                    icon: Icons.house_rounded,
                    isSelected: selected == UserRole.owner,
                    color: AppColors.ownerPrimary,
                    lightColor: AppColors.ownerLight,
                    onTap: () =>
                        ref.read(_selectedRoleProvider.notifier).state =
                            UserRole.owner,
                  ),

                  const SizedBox(height: AppSizes.md),

                  RoleCard(
                    title: AppStrings.customer,
                    description: AppStrings.customerDesc,
                    icon: Icons.search_rounded,
                    isSelected: selected == UserRole.customer,
                    color: AppColors.customerPrimary,
                    lightColor: AppColors.customerLight,
                    onTap: () =>
                        ref.read(_selectedRoleProvider.notifier).state =
                            UserRole.customer,
                  ),

                  const SizedBox(height: AppSizes.md),

                  RoleCard(
                    title: AppStrings.agent,
                    description: AppStrings.agentDesc,
                    icon: Icons.badge_rounded,
                    isSelected: selected == UserRole.agent,
                    color: AppColors.agentPrimary,
                    lightColor: AppColors.agentLight,
                    onTap: () =>
                        ref.read(_selectedRoleProvider.notifier).state =
                            UserRole.agent,
                  ),

                  const SizedBox(height: 24),

                  _HiddenAdminButton(
                    onAdminSelected: () =>
                        ref.read(_selectedRoleProvider.notifier).state =
                            UserRole.superAdmin,
                    selected: selected,
                  ),

                  const SizedBox(height: AppSizes.md),

                  MkButton(
                    label: AppStrings.continueText,
                    onPressed: selected == null
                        ? null
                        : () =>
                              context.go(AppRoutes.onboarding, extra: selected),
                  ),

                  const SizedBox(height: AppSizes.md),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HiddenAdminButton extends StatefulWidget {
  final VoidCallback onAdminSelected;
  final UserRole? selected;

  const _HiddenAdminButton({
    required this.onAdminSelected,
    required this.selected,
  });

  @override
  State<_HiddenAdminButton> createState() => _HiddenAdminButtonState();
}

class _HiddenAdminButtonState extends State<_HiddenAdminButton> {
  int _tapCount = 0;

  void _onTap() {
    _tapCount++;
    if (_tapCount >= 5) {
      _tapCount = 0;
      _showAdminDialog();
    }
  }

  void _showAdminDialog() {
    final codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        title: const Text('Admin Access'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.grey50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.admin_panel_settings_rounded,
                size: 30,
                color: AppColors.grey600,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Enter admin code to proceed',
              style: TextStyle(fontSize: 14, color: AppColors.grey600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: codeController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Admin code',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (codeController.text.trim() == _adminSecretCode) {
                Navigator.pop(context);
                widget.onAdminSelected();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✓ Admin role selected'),
                    backgroundColor: Colors.blueGrey,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✗ Invalid admin code'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      child: Container(
        alignment: Alignment.center,
        child: Text(
          widget.selected == UserRole.superAdmin
              ? '🔐 Admin Mode'
              : '👤 Select role above',
          style: TextStyle(
            fontSize: 12,
            color: widget.selected == UserRole.superAdmin
                ? Colors.blueGrey
                : AppColors.grey400,
          ),
        ),
      ),
    );
  }
}
