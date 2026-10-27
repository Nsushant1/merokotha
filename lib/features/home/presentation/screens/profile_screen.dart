import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/constants/app_sizes.dart';
import 'package:merokotha/core/i18n/localization.dart';
import 'package:merokotha/core/router/app_routes.dart';
import 'package:merokotha/core/utils/validators.dart';
import 'package:merokotha/features/auth/data/auth_repository.dart';
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
  final _emailCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _callCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();
  bool _hideName = false;

  bool _isEditing = false;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;
  bool _isLoaded = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _locationCtrl.dispose();
    _phoneCtrl.dispose();
    _bioCtrl.dispose();
    _callCtrl.dispose();
    _whatsappCtrl.dispose();
    super.dispose();
  }

  void _loadUser(UserModel user) {
    if (!_isLoaded) {
      _nameCtrl.text = user.name;
      _emailCtrl.text = user.email;
      _locationCtrl.text = user.location ?? '';
      _phoneCtrl.text = user.phone;
      _bioCtrl.text = user.bio ?? '';
      _callCtrl.text = user.publicPhone ?? '';
      _whatsappCtrl.text = user.whatsappNumber ?? '';
      _hideName = user.hideDisplayName;
      _isLoaded = true;
    }
  }

  Future<void> _save(UserModel user) async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);
    try {
      final call = _callCtrl.text.trim();
      final wa = _whatsappCtrl.text.trim();
      await ref.read(userRepositoryProvider).updateUser(user.id, {
        'name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'location': _locationCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'bio': _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
        'publicPhone': call.isEmpty ? null : call,
        'whatsappNumber': wa.isEmpty ? null : wa,
        'hideDisplayName': _hideName,
      });
      if (mounted) {
        setState(() {
          _isEditing = false;
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr(ref, 'profile_updated')),
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

  /// Uploads a new avatar to `users/{uid}/` and saves its URL.
  Future<void> _changePhoto(UserModel user) async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      imageQuality: 80,
    );
    if (picked == null || !mounted) return;
    setState(() => _isUploadingPhoto = true);
    try {
      final file = File(picked.path);
      final target = FirebaseStorage.instance
          .ref()
          .child('users/${user.id}/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await target.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final url = await target.getDownloadURL();
      await ref.read(userRepositoryProvider).updateUser(user.id, {
        'photoUrl': url,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr(ref, 'profile_updated')),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo upload failed. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
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
                      roleLabel: tr(ref, 'profile_member'),
                      roleIcon: Icons.person_rounded,
                      onPhotoTap: _isEditing && !_isUploadingPhoto
                          ? () => _changePhoto(user)
                          : null,
                      photoLoading: _isUploadingPhoto,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ProfileStatMini(
                            label: tr(ref, 'profile_saved_rooms'),
                            value: '${favIds.length}',
                            icon: Icons.favorite_rounded,
                            color: AppColors.accent,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ProfileStatMini(
                            label: tr(ref, 'profile_my_listings'),
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
                      emailCtrl: _emailCtrl,
                      locationCtrl: _locationCtrl,
                      phoneCtrl: _phoneCtrl,
                      bioCtrl: _bioCtrl,
                      callCtrl: _callCtrl,
                      whatsappCtrl: _whatsappCtrl,
                      hideName: _hideName,
                      onHideNameChanged: (v) =>
                          setState(() => _hideName = v),
                      isEditing: _isEditing,
                      isSaving: _isSaving,
                      onEditToggle: () =>
                          setState(() => _isEditing = !_isEditing),
                      onSave: () => _save(user),
                    ),
                    const SizedBox(height: 16),
                    ProfileSectionCard(
                      title: tr(ref, 'profile_quick_links'),
                      children: [
                        ProfileSettingsTile(
                          icon: Icons.favorite_outline_rounded,
                          label: tr(ref, 'profile_saved_rooms'),
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
                          label: tr(ref, 'profile_my_listings'),
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
                          label: tr(ref, 'profile_my_inquiries'),
                          trailing: const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.grey400,
                          ),
                          onTap: () => context.push(AppRoutes.myInquiries),
                        ),
                        const ProfileDivider(),
                        ProfileSettingsTile(
                          icon: Icons.flag_outlined,
                          label: tr(ref, 'profile_my_reports'),
                          trailing: const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.grey400,
                          ),
                          onTap: () => context.push(AppRoutes.myReports),
                        ),
                        const ProfileDivider(),
                        ProfileSettingsTile(
                          icon: Icons.bookmark_outline_rounded,
                          label: tr(ref, 'profile_saved_searches'),
                          trailing: const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.grey400,
                          ),
                          onTap: () => context.push(AppRoutes.savedSearches),
                        ),
                        const ProfileDivider(),
                        ProfileSettingsTile(
                          icon: Icons.badge_outlined,
                          label: tr(ref, 'profile_find_agent'),
                          trailing: const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.grey400,
                          ),
                          onTap: () => context.push(AppRoutes.agents),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ProfileSectionCard(
                      title: tr(ref, 'profile_account'),
                      children: [
                        _AgentTile(user: user),
                        const ProfileDivider(),
                        _LanguageTile(
                          current: ref.watch(localeProvider),
                          onChanged: (code) => ref
                              .read(localeProvider.notifier)
                              .setLocale(code),
                        ),
                        const ProfileDivider(),
                        _LinkAccountsTile(user: user),
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
                      label: tr(ref, 'profile_logout'),
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
  final TextEditingController emailCtrl;
  final TextEditingController locationCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController bioCtrl;
  final TextEditingController callCtrl;
  final TextEditingController whatsappCtrl;
  final bool hideName;
  final ValueChanged<bool> onHideNameChanged;
  final bool isEditing;
  final bool isSaving;
  final VoidCallback onEditToggle;
  final VoidCallback onSave;

  const _PersonalInfoCard({
    required this.nameCtrl,
    required this.emailCtrl,
    required this.locationCtrl,
    required this.phoneCtrl,
    required this.bioCtrl,
    required this.callCtrl,
    required this.whatsappCtrl,
    required this.hideName,
    required this.onHideNameChanged,
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
          validator: Validators.name,
        ),
        const SizedBox(height: 12),
        MkTextField(
          controller: emailCtrl,
          label: 'Contact email',
          enabled: isEditing,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        MkTextField(
          controller: phoneCtrl,
          label: 'Phone number',
          enabled: isEditing,
          keyboardType: TextInputType.phone,
          validator: Validators.optionalPhone,
        ),
        const SizedBox(height: 12),
        MkTextField(
          controller: bioCtrl,
          label: 'Bio',
          hint: 'Tell renters about yourself...',
          enabled: isEditing,
          maxLines: 3,
        ),
        const SizedBox(height: 12),
        MkTextField(
          controller: locationCtrl,
          label: 'Location',
          enabled: isEditing,
        ),
        const SizedBox(height: 12),
        MkTextField(
          controller: callCtrl,
          label: 'Public call number',
          hint: 'Optional — shown on listings',
          enabled: isEditing,
          keyboardType: TextInputType.phone,
          validator: Validators.optionalPhone,
        ),
        const SizedBox(height: 12),
        MkTextField(
          controller: whatsappCtrl,
          label: 'WhatsApp number',
          hint: 'Optional — shown on listings',
          enabled: isEditing,
          keyboardType: TextInputType.phone,
          validator: Validators.optionalPhone,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'Hide my public name',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          subtitle: const Text(
            'Seekers see "Property Owner" instead.',
            style: TextStyle(fontSize: 12),
          ),
          value: hideName,
          onChanged: isEditing ? onHideNameChanged : null,
        ),
        if (isEditing) ...[
          const SizedBox(height: 8),
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

/// Working English/Nepali language switcher (replaces the old placeholder).
class _LanguageTile extends StatelessWidget {
  final String current;
  final ValueChanged<String> onChanged;
  const _LanguageTile({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return ProfileSettingsTile(
      icon: Icons.language_rounded,
      label: 'Language',
      trailing: SegmentedButton<String>(
        style: SegmentedButton.styleFrom(
          visualDensity: VisualDensity.compact,
        ),
        segments: const [
          ButtonSegment(value: 'en', label: Text('EN')),
          ButtonSegment(value: 'ne', label: Text('ने')),
        ],
        selected: {current},
        onSelectionChanged: (s) => onChanged(s.first),
      ),
    );
  }
}

/// Google/email provider linking. Both methods share one Firebase UID.
class _LinkAccountsTile extends ConsumerStatefulWidget {
  final UserModel user;
  const _LinkAccountsTile({required this.user});

  @override
  ConsumerState<_LinkAccountsTile> createState() => _LinkAccountsTileState();
}

class _LinkAccountsTileState extends ConsumerState<_LinkAccountsTile> {
  bool _busy = false;

  List<String> get _linked =>
      ref.read(authRepositoryProvider).linkedProviders;
  bool get _hasGoogle => _linked.contains('google.com');
  bool get _hasEmail => _linked.contains('password');

  Future<void> _linkGoogle() async {
    setState(() => _busy = true);
    try {
      final cred = await ref.read(authRepositoryProvider).linkWithGoogle();
      if (cred == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google linking cancelled.')),
        );
      } else if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Google account linked.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.code == 'credential-already-in-use'
                ? 'This Google account is already linked to another user.'
                : 'Linking failed. Please try again.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _linkEmail() async {
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add email sign-in'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    Validators.required(v, fieldName: 'Email'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: passCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password (min 6 chars)',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.length < 6) ? 'At least 6 characters' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
            },
            child: const Text('Link'),
          ),
        ],
      ),
    );
    emailCtrl.dispose();
    passCtrl.dispose();
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .linkWithEmail(email: emailCtrl.text, password: passCtrl.text);
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email sign-in linked.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.code == 'email-already-in-use'
                ? 'This email is already in use.'
                : 'Linking failed. Please try again.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final linked = _linked;
    final label = [
      if (linked.contains('google.com')) 'Google',
      if (linked.contains('password')) 'Email',
    ].join(' + ');
    return ProfileSettingsTile(
      icon: Icons.link_rounded,
      label: 'Sign-in methods',
      trailing: _busy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(
              label.isEmpty ? 'None' : label,
              style: const TextStyle(fontSize: 13, color: AppColors.grey400),
            ),
      onTap: () {
        if (_busy) return;
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                const Text(
                  'Linked sign-in methods share one account.',
                  style: TextStyle(fontSize: 13, color: AppColors.grey600),
                ),
                if (!_hasGoogle)
                  ListTile(
                    leading: const Icon(Icons.g_mobiledata_rounded),
                    title: const Text('Link Google account'),
                    onTap: () {
                      Navigator.pop(ctx);
                      _linkGoogle();
                    },
                  ),
                if (!_hasEmail)
                  ListTile(
                    leading: const Icon(Icons.email_outlined),
                    title: const Text('Add email sign-in'),
                    onTap: () {
                      Navigator.pop(ctx);
                      _linkEmail();
                    },
                  ),
                if (_hasGoogle && _hasEmail)
                  const ListTile(
                    leading: Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.success,
                    ),
                    title: Text('Google and email both linked'),
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
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
