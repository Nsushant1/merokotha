import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:merokotha/shared/widgets/owner_bottom_nav.dart';

import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/constants/app_sizes.dart';
import 'package:merokotha/core/router/app_routes.dart';
import 'package:merokotha/shared/models/user_model.dart';
import 'package:merokotha/shared/widgets/mk_button.dart';
import 'package:merokotha/shared/widgets/mk_text_field.dart';
import 'package:merokotha/shared/widgets/mk_widgets.dart';
import 'package:merokotha/shared/widgets/profile_section.dart';
import 'package:merokotha/features/auth/data/user_repository.dart';
import 'package:merokotha/features/auth/providers/auth_provider.dart';
import 'package:merokotha/features/auth/data/auth_repository.dart';
import 'package:merokotha/core/utils/validators.dart';

class OwnerProfileScreen extends ConsumerStatefulWidget {
  const OwnerProfileScreen({super.key});

  @override
  ConsumerState<OwnerProfileScreen> createState() => _OwnerProfileScreenState();
}

class _OwnerProfileScreenState extends ConsumerState<OwnerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();

  bool _isEditing = false;
  bool _isSaving = false;
  bool _isLoaded = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  void _loadUser(UserModel user) {
    if (!_isLoaded) {
      _nameCtrl.text = user.name;
      _locationCtrl.text = user.location ?? '';
      _isLoaded = true;
    }
  }

  Future<void> _save(UserModel user) async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    try {
      await ref.read(userRepositoryProvider).updateUser(user.id, {
        'name': _nameCtrl.text.trim(),
        'location': _locationCtrl.text.trim(),
      });
      if (mounted) {
        setState(() {
          _isEditing = false;
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _switchRole(UserModel user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
        title: const Text(
          'Switch to Customer?',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.grey900,
          ),
        ),
        content: const Text(
          'You will be switched to Customer mode. You can switch back anytime from your profile.',
          style: TextStyle(fontSize: 14, color: AppColors.grey600, height: 1.4),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.grey600),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Switch',
              style: TextStyle(
                color: AppColors.customerPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    await ref
        .read(userRepositoryProvider)
        .updateRole(user.id, UserRole.customer);
    if (mounted) context.go(AppRoutes.customerHome);
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
        title: const Text(
          'Sign out?',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.grey900,
          ),
        ),
        content: const Text(
          'Are you sure you want to sign out?',
          style: TextStyle(fontSize: 14, color: AppColors.grey600, height: 1.4),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.grey600),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Sign out',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    await ref.read(authRepositoryProvider).signOut();
    if (mounted) context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: userAsync.when(
        loading: () => const MkLoading(),
        error: (e, _) => MkErrorWidget(message: e.toString()),
        data: (user) {
          if (user == null) {
            return const MkErrorWidget(message: 'User not found');
          }
          _loadUser(user);
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: MkProfileHeader(
                  name: user.name,
                  email: user.phone.isNotEmpty
                      ? user.phone
                      : 'Mero Kotha owner',
                  photoUrl: user.photoUrl,
                  roleLabel: 'House Owner',
                  roleIcon: Icons.house_rounded,
                  onSettings: () {},
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _isEditing ? 'Edit profile' : 'My profile',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (!_isEditing)
                        TextButton(
                          onPressed: () => setState(() => _isEditing = true),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          child: const Text('Edit'),
                        ),
                      if (_isEditing)
                        TextButton(
                          onPressed: () => setState(() {
                            _isEditing = false;
                            _isLoaded = false;
                            userAsync.whenData((u) {
                              if (u != null) _loadUser(u);
                            });
                          }),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.textTertiary,
                          ),
                          child: const Text('Cancel'),
                        ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.pagePadding,
                    12,
                    AppSizes.pagePadding,
                    0,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        ProfileSectionCard(
                          title: 'Personal information',
                          children: [
                            MkTextField(
                              label: 'Full name',
                              controller: _nameCtrl,
                              validator: Validators.name,
                              enabled: _isEditing,
                              textCapitalization: TextCapitalization.words,
                              prefixIcon: const Icon(
                                Icons.person_outline_rounded,
                                size: 18,
                                color: AppColors.grey400,
                              ),
                            ),
                            const SizedBox(height: AppSizes.md),
                            MkTextField(
                              label: 'Phone number',
                              controller: TextEditingController(
                                text: user.phone,
                              ),
                              enabled: false,
                              prefixIcon: const Icon(
                                Icons.phone_outlined,
                                size: 18,
                                color: AppColors.grey400,
                              ),
                            ),
                            const SizedBox(height: AppSizes.md),
                            MkTextField(
                              label: 'Location',
                              controller: _locationCtrl,
                              enabled: _isEditing,
                              textCapitalization: TextCapitalization.words,
                              prefixIcon: const Icon(
                                Icons.location_on_outlined,
                                size: 18,
                                color: AppColors.grey400,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        if (_isEditing) ...[
                          MkButton(
                            label: 'Save changes',
                            onPressed: () => _save(user),
                            isLoading: _isSaving,
                          ),
                          const SizedBox(height: 16),
                        ],

                        ProfileSectionCard(
                          title: 'Account',
                          children: [
                            ProfileSettingsTile(
                              icon: Icons.verified_user_outlined,
                              label: 'Verified status',
                              trailing: user.isVerified
                                  ? const StatusBadge(
                                      label: 'Verified',
                                      color: AppColors.success,
                                      backgroundColor: AppColors.successLight,
                                    )
                                  : const StatusBadge(
                                      label: 'Unverified',
                                      color: AppColors.grey400,
                                      backgroundColor: AppColors.grey50,
                                    ),
                            ),
                            const ProfileDivider(),
                            ProfileSettingsTile(
                              icon: Icons.swap_horiz_rounded,
                              label: 'Switch to Customer mode',
                              onTap: () => _switchRole(user),
                              trailing: const Icon(
                                Icons.chevron_right_rounded,
                                size: 20,
                                color: AppColors.grey400,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        ProfileSectionCard(
                          title: 'App',
                          children: [
                            ProfileSettingsTile(
                              icon: Icons.language_rounded,
                              label: 'Language',
                              trailing: const Text(
                                'English',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.grey400,
                                ),
                              ),
                              onTap: () {},
                            ),
                            const ProfileDivider(),
                            const ProfileSettingsTile(
                              icon: Icons.info_outline_rounded,
                              label: 'App version',
                              trailing: Text(
                                '1.0.0',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.grey400,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        MkButton(
                          label: 'Logout',
                          onPressed: _signOut,
                          variant: MkButtonVariant.danger,
                          prefixIcon: Icons.logout_rounded,
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: const OwnerBottomNav(currentIndex: 4),
    );
  }
}
