import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/theme.dart';
import '../../core/widgets/auth_badge.dart';
import '../../services/auth_service.dart';
import '../home/main_shell.dart';

class AuthOtpScreen extends StatefulWidget {
  final String phoneNumber;

  /// Test rejimida backend qaytargan kod — maydonga avtomatik yoziladi.
  /// Haqiqiy rejimda `null` bo'ladi (kod faqat SMS orqali keladi).
  final String? devCode;

  /// Kodni QAYTA yuborish uchun kerak — backend `/auth/register/` endpointi
  /// ism-familiyani ham kutadi (u yerda foydalanuvchi yaratiladi/yangilanadi).
  final String firstName;
  final String lastName;

  const AuthOtpScreen({
    super.key,
    required this.phoneNumber,
    required this.firstName,
    this.lastName = '',
    this.devCode,
  });

  @override
  State<AuthOtpScreen> createState() => _AuthOtpScreenState();
}

class _AuthOtpScreenState extends State<AuthOtpScreen> {
  static const _blockDurationSeconds = 5 * 60; // 5 daqiqa blok

  /// Backenddagi `PhoneOtp.RESEND_COOLDOWN_SECONDS` bilan bir xil.
  /// Ilgari bu yerda 42 turardi — hisoblagich tugagach bosilgan "qayta
  /// yuborish" server tomonidan 429 bilan rad etilardi.
  static const _resendCooldownSeconds = 60;

  String _code = '';
  final TextEditingController _codeController = TextEditingController();
  bool _loading = false;
  bool _resending = false;
  bool _blocked = false;
  int _attemptsLeft = 3;
  String? _error;
  String? _devCode;
  Timer? _timer;
  int _secondsLeft = _resendCooldownSeconds;
  Timer? _blockTimer;
  int _blockSecondsLeft = _blockDurationSeconds;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    // Test rejimida kodni avtomatik to'ldiramiz — SMS kelmaydi, shuning
    // uchun uni qo'lda topib yozishga hojat qolmaydi. Controller orqali
    // yozilmasa kod faqat o'zgaruvchida qolib, ekranda bo'sh ko'rinadi.
    _devCode = widget.devCode;
    final dev = _devCode;
    if (dev != null && dev.isNotEmpty) {
      _code = dev;
      _codeController.text = dev;
    }
  }

  void _startResendTimer([int seconds = _resendCooldownSeconds]) {
    _secondsLeft = seconds;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_secondsLeft <= 0) {
        t.cancel();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  /// Kodni qayta yuborish — backendga HAQIQIY so'rov.
  ///
  /// Ilgari bu tugma faqat mahalliy hisoblagichni qayta ishga tushirardi:
  /// SMS kelmagan foydalanuvchi yangi kod ololmay, ro'yxatdan o'tish shu
  /// yerda tugab qolardi.
  Future<void> _resend() async {
    if (_resending || _secondsLeft > 0) return;
    setState(() {
      _resending = true;
      _error = null;
    });
    try {
      final result = await AuthService.instance.register(
        firstName: widget.firstName,
        lastName: widget.lastName,
        phoneNumber: widget.phoneNumber,
      );
      if (!mounted) return;

      final dev = result['dev_otp'] as String?;
      setState(() {
        _devCode = dev;
        _attemptsLeft = 3;
        if (dev != null && dev.isNotEmpty) {
          _code = dev;
          _codeController.text = dev;
        } else {
          _code = '';
          _codeController.clear();
        }
      });
      _startResendTimer((result['resend_after'] as num?)?.toInt() ?? _resendCooldownSeconds);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocale.instance.t('auth_otp_new_sent'))),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      // 429 — juda tez so'raldi: server qancha kutish kerakligini aytadi
      final wait = e.retryAfter;
      if (wait != null && wait > 0) _startResendTimer(wait);
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  void _startBlockTimer() {
    _blockSecondsLeft = _blockDurationSeconds;
    _blockTimer?.cancel();
    _blockTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_blockSecondsLeft <= 1) {
        t.cancel();
        setState(() {
          _blocked = false;
          _attemptsLeft = 3;
          _code = '';
          _error = null;
        });
        _startResendTimer();
      } else {
        setState(() => _blockSecondsLeft--);
      }
    });
  }

  /// "1:05" ko'rinishi. Ilgari matnda "0:" qotirilgan edi va 60 soniyalik
  /// oraliq "0:60" bo'lib chiqardi.
  String _formatWait(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  String get _blockTimeFormatted {
    final m = _blockSecondsLeft ~/ 60;
    final s = _blockSecondsLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _verify() async {
    if (_code.length != 6) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthService.instance.login(phoneNumber: widget.phoneNumber, otpCode: _code);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShell()),
        (route) => false,
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      // Urinish faqat server kodni RAD ETGANDA sarflanadi (HTTP 400).
      // Ilgari internet uzilishi yoki 404 ham urinish deb hisoblanib,
      // uch marta uzilishdan keyin foydalanuvchi 5 daqiqaga bloklanardi.
      final rejectedCode = e.statusCode == 400;
      setState(() {
        if (rejectedCode) {
          _attemptsLeft -= 1;
          if (_attemptsLeft <= 0) {
            _blocked = true;
          } else {
            _error = '${e.message} Qolgan urinish: $_attemptsLeft ta.';
          }
        } else {
          _error = e.message;
        }
      });
      if (_blocked) {
        _timer?.cancel();
        _startBlockTimer();
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _blockTimer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocale.instance;

    // Dizayn: "Auth — 5 daqiqa blok" ekrani — soat tasviri, sariq kartada
    // qolgan vaqt va qo'llab-quvvatlash havolasi.
    if (_blocked) {
      return Scaffold(
        appBar: AppBar(leading: const BackButton()),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.lock_clock,
                      size: 46, color: AppColors.warning),
                ),
                const SizedBox(height: 22),
                Text(loc.t('auth_otp_blocked'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(
                  loc.t('auth_otp_blocked_sub'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.textSecondary, height: 1.4),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 34, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(loc.t('auth_otp_left'),
                          style: const TextStyle(
                              color: AppColors.warning,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(_blockTimeFormatted,
                          style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFD9480F))),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                Text(loc.t('auth_otp_problem'),
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12.5)),
                TextButton(
                  onPressed: () => launchUrl(
                    Uri.parse('https://t.me/savinapp_support'),
                    mode: LaunchMode.externalApplication,
                  ),
                  child: Text(loc.t('auth_otp_support'),
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(leading: const BackButton()),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AuthStepDots(step: 3),
              const SizedBox(height: 32),
              const AuthBadge(emoji: '💬'),
              const SizedBox(height: 16),
              Text(loc.t('auth_otp_title'),
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(
                '${widget.phoneNumber} ${loc.t('auth_otp_sub')}',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 28),
              PinCodeTextField(
                appContext: context,
                length: 6,
                // Controller bo'lmasa test rejimidagi kod ekranda ko'rinmaydi
                controller: _codeController,
                onChanged: (value) => setState(() => _code = value),
                onCompleted: (_) => _verify(),
                keyboardType: TextInputType.number,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(10),
                  fieldHeight: 48,
                  fieldWidth: 44,
                  activeColor: AppColors.primary,
                  selectedColor: AppColors.primary,
                  inactiveColor: AppColors.border,
                ),
              ),
              // Test rejimi: SMS xizmati ulanmagan, kod avtomatik to'ldirilgan
              if (_devCode != null && _devCode!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    loc.t('auth_otp_test_mode'),
                    style: const TextStyle(
                        color: AppColors.primary, fontSize: 12),
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
              ],
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: (_secondsLeft == 0 && !_resending) ? _resend : null,
                  child: _resending
                      ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(
                          _secondsLeft == 0
                              ? loc.t('auth_otp_resend')
                              : '${loc.t('auth_otp_wait')} (${_formatWait(_secondsLeft)})',
                        ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_code.length == 6 && !_loading) ? _verify : null,
                  child: _loading
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Tasdiqlash'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
