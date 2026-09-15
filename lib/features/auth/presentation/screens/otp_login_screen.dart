import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/constants/app_sizes.dart';
import 'package:merokotha/core/constants/app_strings.dart';
import 'package:merokotha/core/router/app_routes.dart';
import 'package:merokotha/core/utils/validators.dart';
import 'package:merokotha/features/auth/data/user_repository.dart';
import 'package:merokotha/features/auth/presentation/widgets/otp_input_field.dart';
import 'package:merokotha/features/auth/providers/auth_provider.dart';
import 'package:merokotha/shared/widgets/mk_button.dart';

class OtpLoginScreen extends ConsumerStatefulWidget {
  const OtpLoginScreen({super.key});

  @override
  ConsumerState<OtpLoginScreen> createState() => _OtpLoginScreenState();
}

class _OtpLoginScreenState extends ConsumerState<OtpLoginScreen> {
  final _phoneFormKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _clearTrigger = ValueNotifier<int>(0);

  String _otpValue = '';
  bool _showOtpField = false;
  int _resendCountdown = 60;
  int _lockoutCountdown = 0;
  Timer? _timer;
  Timer? _lockoutTimer;

  @override
  void dispose() {
    _phoneController.dispose();
    _clearTrigger.dispose();
    _timer?.cancel();
    _lockoutTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _resendCountdown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendCountdown == 0) {
        t.cancel();
      } else {
        setState(() => _resendCountdown--);
      }
    });
  }

  void _startLockoutTimer(int seconds) {
    _lockoutCountdown = seconds;
    _lockoutTimer?.cancel();
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_lockoutCountdown == 0) {
        t.cancel();
      } else {
        setState(() => _lockoutCountdown--);
      }
    });
  }

  Future<void> _sendOtp() async {
    if (!_phoneFormKey.currentState!.validate()) return;
    final otpState = ref.read(otpProvider);
    if (otpState.isSending || otpState.isLockedOut) return;
    FocusScope.of(context).unfocus();

    await ref.read(otpProvider.notifier).sendOtp(_phoneController.text.trim());
  }

  Future<void> _verifyOtp() async {
    if (_otpValue.length != 6) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(AppStrings.invalidOtp)));
      return;
    }
    FocusScope.of(context).unfocus();
    await ref.read(otpProvider.notifier).verifyOtp(_otpValue);
  }

  Future<void> _navigatePostLogin() async {
    final firebaseUser = ref.read(authStateProvider).value;
    if (firebaseUser == null) return;

    final userExists = await ref
        .read(userRepositoryProvider)
        .userExists(firebaseUser.uid);

    if (!mounted) return;
    if (!userExists) {
      context.go(AppRoutes.roleSelect);
    } else {
      final user = await ref
          .read(userRepositoryProvider)
          .getUser(firebaseUser.uid);
      if (!mounted) return;
      context.go(
        user?.isOwner == true ? AppRoutes.ownerHome : AppRoutes.customerHome,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final otpState = ref.watch(otpProvider);

    ref.listen(authStateProvider, (prev, next) {
      final wasAuth = prev?.value != null;
      final isAuth = next.value != null;
      if (!wasAuth && isAuth && mounted) {
        _navigatePostLogin();
      }
    });

    ref.listen(otpProvider, (prev, next) {
      if (next.codeSent && !(prev?.codeSent ?? false) && mounted) {
        setState(() => _showOtpField = true);
        _startResendTimer();
      }
      if (next.isLockedOut && !(prev?.isLockedOut ?? false) && mounted) {
        _startLockoutTimer(next.lockoutSecondsRemaining);
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.grey900),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      child: Image.asset(
                        'assets/merokotha.png',
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    AppStrings.appName,
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: AppColors.grey900,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 60),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _showOtpField
                    ? _OtpHeading(phone: _phoneController.text.trim())
                    : const _PhoneHeading(),
              ),

              const SizedBox(height: 32),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, anim) =>
                    FadeTransition(opacity: anim, child: child),
                child: _showOtpField
                    ? _buildOtpSection(otpState)
                    : _buildPhoneSection(otpState),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneSection(OtpState otpState) {
    return Form(
      key: _phoneFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            validator: Validators.phone,
            style: const TextStyle(fontSize: 16, color: AppColors.grey900),
            decoration: InputDecoration(
              hintText: AppStrings.phoneHint,
              prefixIcon: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.grey50,
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: const Text(
                  '🇳🇵 +977',
                  style: TextStyle(fontSize: 14, color: AppColors.grey800),
                ),
              ),
              prefixIconConstraints: const BoxConstraints(),
            ),
          ),

          const SizedBox(height: AppSizes.lg),

          MkButton(
            label: AppStrings.sendOtp,
            onPressed: _sendOtp,
            isLoading: otpState.isSending,
          ),
        ],
      ),
    );
  }

  Widget _buildOtpSection(OtpState otpState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OtpInputField(
          hasError: otpState.errorMessage != null,
          clearTrigger: _clearTrigger,
          onCompleted: (otp) {
            setState(() => _otpValue = otp);
            _verifyOtp();
          },
          onChanged: (otp) {
            setState(() => _otpValue = otp);
            if (otpState.errorMessage != null) {
              ref.read(otpProvider.notifier).resetError();
            }
          },
        ),

        if (_otpValue.isNotEmpty)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                _clearTrigger.value++;
                setState(() => _otpValue = '');
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.grey400,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Clear',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
          ),

        const SizedBox(height: AppSizes.lg),

        MkButton(
          label: otpState.isLockedOut
              ? 'Try again in ${_lockoutCountdown}s'
              : AppStrings.verifyOtp,
          onPressed: (otpState.isLockedOut || otpState.isVerifying)
              ? null
              : () => _verifyOtp(),
          isLoading: otpState.isVerifying,
        ),

        const SizedBox(height: AppSizes.md),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _resendCountdown > 0
                ? Text(
                    '${AppStrings.resendIn} $_resendCountdown${AppStrings.seconds}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.grey400,
                    ),
                  )
                : TextButton(
                    onPressed: otpState.isSending ? null : _sendOtp,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      AppStrings.resendOtp,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

            TextButton(
              onPressed: () {
                ref.read(otpProvider.notifier).resetAll();
                setState(() {
                  _showOtpField = false;
                  _otpValue = '';
                });
                _timer?.cancel();
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.grey600,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Change number',
                style: TextStyle(
                  fontSize: 13,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),

        if (otpState.errorMessage != null) ...[
          const SizedBox(height: AppSizes.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.errorLight,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            child: Text(
              otpState.errorMessage!,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.error,
                height: 1.4,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _PhoneHeading extends StatelessWidget {
  const _PhoneHeading();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Welcome!',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            color: AppColors.grey900,
          ),
        ),
        SizedBox(height: 8),
        Text(
          AppStrings.enterPhone,
          style: TextStyle(fontSize: 15, color: AppColors.grey600, height: 1.5),
        ),
      ],
    );
  }
}

class _OtpHeading extends StatelessWidget {
  final String phone;
  const _OtpHeading({required this.phone});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Enter OTP',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            color: AppColors.grey900,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text(
              '${AppStrings.otpSentTo} ',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.grey600,
                height: 1.5,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                '+977 $phone',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.grey900,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}


