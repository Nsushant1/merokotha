import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/constants/app_sizes.dart';
import 'package:merokotha/core/router/app_routes.dart';
import 'package:merokotha/core/utils/validators.dart';
import 'package:merokotha/features/auth/data/auth_repository.dart';
import 'package:merokotha/features/auth/data/user_repository.dart';
import 'package:merokotha/features/auth/providers/auth_provider.dart';
import 'package:merokotha/features/customer/presentation/widgets/customer_widgets.dart';
import 'package:merokotha/features/customer/providers/customers_providers.dart';
import 'package:merokotha/shared/models/user_model.dart';
import 'package:merokotha/shared/widgets/mk_button.dart';
import 'package:merokotha/shared/widgets/mk_text_field.dart';
import 'package:merokotha/shared/widgets/mk_widgets.dart';
import 'package:merokotha/shared/widgets/profile_section.dart';
import 'package:merokotha/shared/widgets/shimmer_loading.dart';

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.pagePadding),
        child: Column(
          children: [
            const ShimmerBox(
              width: 88,
              height: 88,
              borderRadius: BorderRadius.all(Radius.circular(44)),
            ),
            const SizedBox(height: 14),
            ShimmerBox(
              height: 16,
              width: 140,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ShimmerBox(
                    height: 68,
                    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ShimmerBox(
                    height: 68,
                    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ShimmerBox(
              height: 180,
              width: double.infinity,
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            ),
            const SizedBox(height: 16),
            ShimmerBox(
              height: 120,
              width: double.infinity,
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomerProfileScreen extends ConsumerStatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  ConsumerState<CustomerProfileScreen> createState() =>
      _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends ConsumerState<CustomerProfileScreen> {
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
        title: const Text('Switch to House Owner?'),
        content: const Text(
          'You will be switched to Owner mode to list rooms. You can switch back anytime.',
        ),
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
              'Switch',
              style: TextStyle(color: AppColors.ownerPrimary),
            ),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    await ref.read(userRepositoryProvider).updateRole(user.id, UserRole.owner);
    if (mounted) context.go(AppRoutes.ownerHome);
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
    await ref.read(authRepositoryProvider).signOut();
    if (mounted) context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final favIds = ref.watch(favouriteIdsProvider).asData?.value ?? [];

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: userAsync.when(
        loading: () => const _ProfileSkeleton(),
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
                      : 'Mero Kotha member',
                  photoUrl: user.photoUrl,
                  roleLabel: 'Room Seeker',
                  roleIcon: Icons.search_rounded,
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
                        const SizedBox(height: 24),

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
                            const SizedBox(width: 10),
                            const Expanded(
                              child: ProfileStatMini(
                                label: 'Inquiries sent',
                                value: '—',
                                icon: Icons.send_rounded,
                                color: AppColors.customerPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

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
                              label: 'Your area / city',
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
                            variant: MkButtonVariant.primary,
                          ),
                          const SizedBox(height: 16),
                        ],

                        ProfileSectionCard(
                          title: 'Quick links',
                          children: [
                            ProfileSettingsTile(
                              icon: Icons.favorite_outline_rounded,
                              label: 'Saved rooms',
                              count: favIds.length,
                              countColor: AppColors.customerPrimary,
                              countBackgroundColor: AppColors.customerLight,
                              onTap: () => context.push(AppRoutes.favourites),
                              trailing: const Icon(
                                Icons.chevron_right_rounded,
                                size: 20,
                                color: AppColors.grey400,
                              ),
                            ),
                            const ProfileDivider(),
                            ProfileSettingsTile(
                              icon: Icons.inbox_outlined,
                              label: 'My inquiries',
                              onTap: () {},
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
                          title: 'Account',
                          children: [
                            ProfileSettingsTile(
                              icon: Icons.swap_horiz_rounded,
                              label: 'Switch to Owner mode',
                              onTap: () => _switchRole(user),
                              trailing: const Icon(
                                Icons.chevron_right_rounded,
                                size: 20,
                                color: AppColors.grey400,
                              ),
                            ),
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
      bottomNavigationBar: const CustomerBottomNav(currentIndex: 4),
    );
  }
}
