import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/constants/app_sizes.dart';
import 'package:merokotha/core/router/app_routes.dart';
import 'package:merokotha/features/auth/data/user_repository.dart';
import 'package:merokotha/features/auth/providers/auth_provider.dart';
import 'package:merokotha/features/auth/providers/pending_inquiry_provider.dart';
import 'package:merokotha/features/customer/providers/customers_providers.dart';
import 'package:merokotha/features/customer/presentation/widgets/profile_stat_mini.dart';
import 'package:merokotha/features/owner/providers/owner_providers.dart';
import 'package:merokotha/shared/models/user_model.dart';
import 'package:merokotha/shared/widgets/mk_button.dart';
import 'package:merokotha/shared/widgets/mk_text_field.dart';
import 'package:merokotha/shared/widgets/profile_section.dart';
import 'package:merokotha/features/home/presentation/widgets/home_bottom_nav.dart';

/// Single profile for every regular user.
///
/// Browsing and posting are capabilities of one account, so there are no
/// role-switch tiles. Agent access is handled exclusively through the
/// "Become an Agent" application flow (see [AgentStatus]).
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  bool _isEditing = false;
  bool _isSaving = false;
  bool _isLoaded = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locationCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _loadUser(UserModel user) {
    if (!_isLoaded) {
      _nameCtrl.text = user.name;
      _locationCtrl.text = user.location ?? '';
      _phoneCtrl.text = user.phone;
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

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('Are you sure you want to sign out?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Sign out',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    signOutAndClearSession(ref);
    if (mounted) context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final favIds = ref.watch(favouriteIdsProvider).asData?.value ?? [];
    final myListings = ref.watch(ownerListingsProvider).asData?.value ?? [];

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: SafeArea(
        child: userAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Failed to load: $e')),
          data: (user) {
            if (user == null) {
              return const Center(child: Text('Not signed in'));
            }
            _loadUser(user);
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.pagePadding),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MkProfileHeader(
                      name: user.name,
                      email: user.email,
                      photoUrl: user.photoUrl,
                      roleLabel: 'Member',
                      roleIcon: Icons.person_rounded,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ProfileStatMini(
                            label: 'Saved rooms',
                            value: '${favIds.length}',
                            icon: Icons.favorite_rounded,
                            color: AppColors.accent,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ProfileStatMini(
                            label: 'My listings',
                            value: '${myListings.length}',
                            icon: Icons.house_rounded,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _PersonalInfoCard(
                      nameCtrl: _nameCtrl,
                      locationCtrl: _locationCtrl,
                      phoneCtrl: _phoneCtrl,
                      isEditing: _isEditing,
                      isSaving: _isSaving,
                      onEditToggle: () =>
                          setState(() => _isEditing = !_isEditing),
                      onSave: () => _save(user),
                    ),
                    const SizedBox(height: 16),
                    ProfileSectionCard(
                      title: 'Quick links',
                      children: [
                        ProfileSettingsTile(
                          icon: Icons.favorite_outline_rounded,
                          label: 'Saved rooms',
                          count: favIds.length,
                          trailing: const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.grey400,
                          ),
                          onTap: () => context.push(AppRoutes.favourites),
                        ),
                        const ProfileDivider(),
                        ProfileSettingsTile(
                          icon: Icons.house_outlined,
                          label: 'My listings',
                          count: myListings.length,
                          trailing: const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.grey400,
                          ),
                          onTap: () => context.push(AppRoutes.myListings),
                        ),
                        const ProfileDivider(),
                        ProfileSettingsTile(
                          icon: Icons.inbox_outlined,
                          label: 'My inquiries',
                          trailing: const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.grey400,
                          ),
                          onTap: () => context.push(AppRoutes.myInquiries),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ProfileSectionCard(
                      title: 'Account',
                      children: [
                        _AgentTile(user: user),
                        const ProfileDivider(),
                        const ProfileSettingsTile(
                          icon: Icons.language_rounded,
                          label: 'Language',
                          trailing: Text(
                            'English',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.grey400,
                            ),
                          ),
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
                      variant: MkButtonVariant.danger,
                      prefixIcon: Icons.logout_rounded,
                      onPressed: _signOut,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: const HomeBottomNav(currentIndex: 4),
    );
  }
}

class _PersonalInfoCard extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController locationCtrl;
  final TextEditingController phoneCtrl;
  final bool isEditing;
  final bool isSaving;
  final VoidCallback onEditToggle;
  final VoidCallback onSave;

  const _PersonalInfoCard({
    required this.nameCtrl,
    required this.locationCtrl,
    required this.phoneCtrl,
    required this.isEditing,
    required this.isSaving,
    required this.onEditToggle,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return ProfileSectionCard(
      title: 'Personal information',
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox.shrink(),
            TextButton(
              onPressed: onEditToggle,
              child: Text(isEditing ? 'Cancel' : 'Edit'),
            ),
          ],
        ),
        MkTextField(
          controller: nameCtrl,
          label: 'Full name',
          enabled: isEditing,
        ),
        const SizedBox(height: 12),
        MkTextField(
          controller: phoneCtrl,
          label: 'Phone number',
          enabled: false,
        ),
        const SizedBox(height: 12),
        MkTextField(
          controller: locationCtrl,
          label: 'Location',
          enabled: isEditing,
        ),
        if (isEditing) ...[
          const SizedBox(height: 16),
          MkButton(
            label: 'Save changes',
            onPressed: onSave,
            isLoading: isSaving,
          ),
        ],
      ],
    );
  }
}

/// Entry to the agent world, driven by [AgentStatus]:
/// none → "Become an Agent" (application form);
/// pending → review status (application screen);
/// verified → open the Agent interface.
class _AgentTile extends StatelessWidget {
  final UserModel user;
  const _AgentTile({required this.user});

  @override
  Widget build(BuildContext context) {
    switch (user.agentStatus) {
      case AgentStatus.verified:
        return ProfileSettingsTile(
          icon: Icons.badge_rounded,
          label: 'Open Agent Hub',
          trailing: const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.grey400,
          ),
          onTap: () => context.push(AppRoutes.agentHome),
        );
      case AgentStatus.pending:
        return ProfileSettingsTile(
          icon: Icons.hourglass_top_rounded,
          label: 'Agent application under review',
          trailing: const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.grey400,
          ),
          onTap: () => context.push(AppRoutes.applyAgent),
        );
      case AgentStatus.none:
        return ProfileSettingsTile(
          icon: Icons.badge_outlined,
          label: 'Become an Agent',
          trailing: const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.grey400,
          ),
          onTap: () => context.push(AppRoutes.applyAgent),
        );
    }
  }
}
