import 'dart:math' show sin, pi;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/constants/app_sizes.dart';
import 'package:sms_autofill/sms_autofill.dart';

class OtpInputField extends StatefulWidget {
  final void Function(String otp) onCompleted;
  final void Function(String otp)? onChanged;
  final bool hasError;
  final ValueNotifier<int>? clearTrigger;

  const OtpInputField({
    super.key,
    required this.onCompleted,
    this.onChanged,
    this.hasError = false,
    this.clearTrigger,
  });

  @override
  State<OtpInputField> createState() => OtpInputFieldState();
}

class OtpInputFieldState extends State<OtpInputField>
    with CodeAutoFill, WidgetsBindingObserver, SingleTickerProviderStateMixin {
  static const _length = 6;
  final _controllers = List.generate(_length, (_) => TextEditingController());
  final _focusNodes = List.generate(_length, (_) => FocusNode());

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  bool _localError = false;
  bool _successFlash = false;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
    );
    listenForCode();
    widget.clearTrigger?.addListener(_onClearTriggered);
    WidgetsBinding.instance.addObserver(this);
    _checkClipboard();
  }

  @override
  void didUpdateWidget(OtpInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hasError && !oldWidget.hasError) {
      _triggerError();
    }
    if (widget.clearTrigger != oldWidget.clearTrigger) {
      oldWidget.clearTrigger?.removeListener(_onClearTriggered);
      widget.clearTrigger?.addListener(_onClearTriggered);
    }
  }

  void _onClearTriggered() {
    clear();
  }

  void _triggerError() {
    setState(() => _localError = true);
    _shakeController.forward(from: 0);
    HapticFeedback.heavyImpact();
    SemanticsService.announce(
      'Incorrect OTP. Please try again.',
      Directionality.of(context),
    );
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) setState(() => _localError = false);
    });
  }

  void _triggerSuccess() {
    setState(() => _successFlash = true);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _successFlash = false);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkClipboard();
    }
  }

  Future<void> _checkClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.length < 6) return;

    final digits = text.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 6) {
      _distributeCode(digits);
    }
  }

  void _distributeCode(String digits) {
    for (int i = 0; i < _length && i < digits.length; i++) {
      _controllers[i].text = digits[i];
    }

    final nextFocus = digits.length < _length ? digits.length : _length - 1;
    _focusNodes[nextFocus].requestFocus();

    widget.onChanged?.call(_currentOtp);
    if (_currentOtp.length == _length) {
      widget.onCompleted(_currentOtp);
      _triggerSuccess();
      _unfocusAll();
      SemanticsService.announce(
        'Code auto-filled',
        Directionality.of(context),
      );
    }
  }

  void _unfocusAll() {
    for (final node in _focusNodes) {
      node.unfocus();
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    widget.clearTrigger?.removeListener(_onClearTriggered);
    WidgetsBinding.instance.removeObserver(this);
    cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  void codeUpdated() {
    final otp = code;
    if (otp == null || otp.isEmpty) return;

    final digits = otp.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return;

    _distributeCode(digits);
  }

  String get _currentOtp => _controllers.map((c) => c.text).join();

  void _onChanged(int index, String value) {
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'\D'), '');
      for (int i = 0; i < _length && i < digits.length; i++) {
        _controllers[i].text = digits[i];
      }
      final nextFocus = digits.length < _length ? digits.length : _length - 1;
      _focusNodes[nextFocus].requestFocus();
      widget.onChanged?.call(_currentOtp);
      if (_currentOtp.length == _length) {
        widget.onCompleted(_currentOtp);
        _triggerSuccess();
        _unfocusAll();
      }
      return;
    }

    if (value.isNotEmpty && index < _length - 1) {
      _focusNodes[index + 1].requestFocus();
      HapticFeedback.lightImpact();
    }

    widget.onChanged?.call(_currentOtp);
    if (_currentOtp.length == _length) {
      widget.onCompleted(_currentOtp);
      _triggerSuccess();
      _unfocusAll();
      HapticFeedback.mediumImpact();
    }
  }

  void _onKeyEvent(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
      _controllers[index - 1].clear();
    }
  }

  void clear() {
    for (final c in _controllers) {
      c.clear();
    }
    _focusNodes[0].requestFocus();
  }

  Color _boxColor(bool focused, bool filled) {
    if (_localError) return AppColors.errorLight;
    if (_successFlash) return AppColors.successLight;
    if (focused || filled) return AppColors.primaryLight;
    return AppColors.backgroundSecondary;
  }

  Color _borderColor(bool focused) {
    if (_localError) return AppColors.error;
    if (_successFlash) return AppColors.success;
    if (focused) return AppColors.primary;
    return AppColors.border;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        final shakeOffset = sin(_shakeAnimation.value * pi * 4) * 8;
        return Transform.translate(
          offset: Offset(shakeOffset, 0),
          child: child,
        );
      },
      child: AutofillGroup(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(_length, (index) {
            return KeyboardListener(
              focusNode: FocusNode(),
              onKeyEvent: (e) => _onKeyEvent(index, e),
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  _focusNodes[index],
                  _controllers[index],
                ]),
                builder: (context, _) {
                  final focused = _focusNodes[index].hasFocus;
                  final filled = _controllers[index].text.isNotEmpty;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    curve: Curves.easeOut,
                    width: 48,
                    height: 56,
                    decoration: BoxDecoration(
                      color: _boxColor(focused, filled),
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      border: Border.all(
                        color: _borderColor(focused),
                        width: focused ? 1.6 : 1,
                      ),
                      boxShadow: focused && !_localError && !_successFlash
                          ? const [
                              BoxShadow(
                                color: Color(0x1D1D9E75),
                                blurRadius: 12,
                                offset: Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Semantics(
                      label: 'OTP digit ${index + 1} of $_length',
                      child: TextFormField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        autofillHints: index == 0 ? const [AutofillHints.oneTimeCode] : null,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.grey900,
                        ),
                        decoration: const InputDecoration(
                          counterText: '',
                          contentPadding: EdgeInsets.zero,
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                        onChanged: (v) => _onChanged(index, v),
                      ),
                    ),
                  );
                },
              ),
            );
          }),
        ),
      ),
    );
  }
}
