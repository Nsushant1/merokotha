import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/constants/app_sizes.dart';
import 'package:merokotha/core/router/app_routes.dart';
import 'package:merokotha/core/utils/validators.dart';
import 'package:merokotha/features/auth/data/user_repository.dart';
import 'package:merokotha/features/auth/providers/auth_provider.dart';
import 'package:merokotha/shared/models/user_model.dart';
import 'package:merokotha/shared/widgets/mk_button.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  bool _isSaving = false;
  UserRole? _role;

  late final AnimationController _animCtrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _headerSlide;
  late final Animation<Offset> _cardSlide;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _headerSlide =
        Tween<Offset>(begin: const Offset(0, -0.05), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animCtrl,
            curve: const Interval(0.0, 0.65, curve: Curves.easeOutCubic),
          ),
        );
    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.07), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _animCtrl,
            curve: const Interval(0.25, 1.0, curve: Curves.easeOutCubic),
          ),
        );
    _animCtrl.forward();

    final fbUser = ref.read(authStateProvider).value;
    if (fbUser != null) {
      _nameCtrl.text = fbUser.displayName ?? '';
      _emailCtrl.text = fbUser.email ?? '';
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final extra = GoRouterState.of(context).extra;
    if (extra is UserRole) _role = extra;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _locationCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);
    try {
      final fbUser = ref.read(authStateProvider).value;
      if (fbUser == null) throw Exception('Not authenticated');
      final role = _role ?? UserRole.customer;
      final now = DateTime.now();
      final user = UserModel(
        id: fbUser.uid,
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        role: role,
        photoUrl: fbUser.photoURL,
        location: _locationCtrl.text.trim(),
        createdAt: now,
        updatedAt: now,
      );
      await ref.read(userRepositoryProvider).createUser(user);
      if (!mounted) return;
      if (role == UserRole.owner) {
        context.go(AppRoutes.ownerHome);
      } else if (role == UserRole.agent) {
        context.go(AppRoutes.agentHome);
      } else if (role == UserRole.superAdmin) {
        context.go(AppRoutes.adminHome);
      } else {
        context.go(AppRoutes.customerHome);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save profile: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  bool get _isOwner => _role == UserRole.owner;
  bool get _isAgent => _role == UserRole.agent;
  Color get _accent => _isOwner
      ? AppColors.ownerPrimary
      : _isAgent
          ? AppColors.agentPrimary
          : AppColors.customerPrimary;
  Color get _accentLight => _isOwner
      ? AppColors.ownerLight
      : _isAgent
          ? AppColors.agentLight
          : AppColors.customerLight;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: FadeTransition(
        opacity: _fade,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SlideTransition(
                    position: _headerSlide,
                    child: _HeaderPanel(
                      isOwner: _isOwner,
                      isAgent: _isAgent,
                      accent: _accent,
                      accentLight: _accentLight,
                    ),
                  ),
                  SlideTransition(
                    position: _cardSlide,
                    child: FadeTransition(
                      opacity: _fade,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _FormCard(
                              nameCtrl: _nameCtrl,
                              emailCtrl: _emailCtrl,
                              phoneCtrl: _phoneCtrl,
                              locationCtrl: _locationCtrl,
                              accent: _accent,
                            ),
                            const SizedBox(height: 24),
                            MkButton(
                              label: 'Continue',
                              onPressed: _save,
                              isLoading: _isSaving,
                              height: 54,
                            ),
                            const SizedBox(height: 18),
                            Center(
                              child: GestureDetector(
                                onTap: () => context.go(AppRoutes.roleSelect),
                                child: Text(
                                  'Change role selection',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 13,
                                    color: AppColors.grey400,
                                    decoration: TextDecoration.underline,
                                    decorationColor: AppColors.grey400,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Header panel ─────────────────────────────────────────────────────────────

class _HeaderPanel extends StatelessWidget {
  final bool isOwner;
  final bool isAgent;
  final Color accent;
  final Color accentLight;

  const _HeaderPanel({
    required this.isOwner,
    this.isAgent = false,
    required this.accent,
    required this.accentLight,
  });

  @override
  Widget build(BuildContext context) {
    final chips = isOwner
        ? ['List for free', 'Reach tenants', 'Manage inquiries']
        : isAgent
            ? ['Post for owners', 'Manage listings', 'Handle inquiries']
            : ['Browse listings', 'Save favourites', 'Contact owners'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: AppSizes.shadowCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Role badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: accentLight,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isOwner
                      ? Icons.house_rounded
                      : isAgent
                          ? Icons.badge_rounded
                          : Icons.search_rounded,
                  size: 13,
                  color: accent,
                ),
                const SizedBox(width: 6),
                Text(
                  isOwner
                      ? 'Room Owner'
                      : isAgent
                          ? 'Agent'
                          : 'Room Seeker',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: accent,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          Text(
            isOwner
                ? 'List your\nplace in minutes'
                : isAgent
                    ? 'Post rooms\nfor owners'
                    : 'Find your\nperfect room',
            style: GoogleFonts.dmSans(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: AppColors.grey900,
              height: 1.15,
              letterSpacing: -0.8,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            'Tell us a bit about yourself to personalise your experience.',
            style: GoogleFonts.dmSans(
              fontSize: 15,
              color: AppColors.grey600,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 24),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: chips
                .map(
                  (label) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundSecondary,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      label,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: AppColors.grey600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ── Form card ─────────────────────────────────────────────────────────────────

class _FormCard extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController locationCtrl;
  final Color accent;

  const _FormCard({
    required this.nameCtrl,
    required this.emailCtrl,
    required this.phoneCtrl,
    required this.locationCtrl,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppSizes.shadowCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your details',
            style: GoogleFonts.dmSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.grey900,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 22),
          _Field(
            ctrl: nameCtrl,
            label: 'Full name',
            hint: 'e.g. Hari Thapa',
            icon: Icons.person_outline_rounded,
            validator: Validators.name,
            accent: accent,
          ),
          const SizedBox(height: 18),
          _Field(
            ctrl: emailCtrl,
            label: 'Email',
            hint: '',
            icon: Icons.email_outlined,
            validator: null,
            accent: accent,
            enabled: false,
          ),
          const SizedBox(height: 18),
          _Field(
            ctrl: phoneCtrl,
            label: 'Phone number',
            hint: '98XXXXXXXX',
            icon: Icons.phone_outlined,
            validator: Validators.phone,
            accent: accent,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 18),
          _Field(
            ctrl: locationCtrl,
            label: 'Location',
            hint: 'e.g. Kathmandu, Baneshwor',
            icon: Icons.location_on_outlined,
            validator: (v) => Validators.required(v, fieldName: 'Location'),
            accent: accent,
          ),
        ],
      ),
    );
  }
}

// ── Input field ───────────────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String hint;
  final IconData icon;
  final String? Function(String?)? validator;
  final Color accent;
  final bool enabled;
  final TextInputType? keyboardType;

  const _Field({
    required this.ctrl,
    required this.label,
    required this.hint,
    required this.icon,
    required this.validator,
    required this.accent,
    this.enabled = true,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.grey400,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: ctrl,
          validator: validator,
          enabled: enabled,
          keyboardType: keyboardType,
          textCapitalization: keyboardType == TextInputType.phone
              ? TextCapitalization.none
              : TextCapitalization.words,
          style: GoogleFonts.dmSans(
            fontSize: 15,
            color: enabled ? AppColors.grey900 : AppColors.grey400,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.dmSans(
              fontSize: 14,
              color: AppColors.grey200,
            ),
            prefixIcon: Icon(icon, size: 18, color: AppColors.grey400),
            filled: true,
            fillColor: AppColors.backgroundSecondary,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 15,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: accent, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
