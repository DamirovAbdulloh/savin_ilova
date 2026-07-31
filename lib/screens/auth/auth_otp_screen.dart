import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../home/main_shell.dart';

class AuthOtpScreen extends StatefulWidget {
  final String phoneNumber;

  /// Test rejimida backend qaytargan kod — maydonga avtomatik yoziladi.
  /// Haqiqiy rejimda `null` bo'ladi (kod faqat SMS orqali keladi).
  final String? devCode;

  const AuthOtpScreen({
    super.key,
    required this.phoneNumber,
    this.devCode,
  });

  @override
  State<AuthOtpScreen> createState() => _AuthOtpScreenState();
}

class _AuthOtpScreenState extends State<AuthOtpScreen> {
  static const _blockDurationSeconds = 5 * 60; // 5 daqiqa blok

  String _code = '';
  final TextEditingController _codeController = TextEditingController();
  bool _loading = false;
  bool _blocked = false;
  int _attemptsLeft = 3;
  String? _error;
  Timer? _timer;
  int _secondsLeft = 42;
  Timer? _blockTimer;
  int _blockSecondsLeft = _blockDurationSeconds;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    // Test rejimida kodni avtomatik to'ldiramiz — SMS kelmaydi, shuning
    // uchun uni qo'lda topib yozishga hojat qolmaydi. Controller orqali
    // yozilmasa kod faqat o'zgaruvchida qolib, ekranda bo'sh ko'rinadi.
    final dev = widget.devCode;
    if (dev != null && dev.isNotEmpty) {
      _code = dev;
      _codeController.text = dev;
    }
  }

  void _startResendTimer() {
    _secondsLeft = 42;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft == 0) {
        t.cancel();
      } else {
        setState(() => _secondsLeft--);
      }
    });
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
      setState(() {
        _attemptsLeft -= 1;
        if (_attemptsLeft <= 0) {
          _blocked = true;
        } else {
          _error = '${e.message} Qolgan urinish: $_attemptsLeft ta.';
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
    if (_blocked) {
      return Scaffold(
        appBar: AppBar(leading: const BackButton()),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_clock, size: 56, color: AppColors.warning),
                const SizedBox(height: 20),
                const Text('Vaqtincha bloklangan',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                const Text(
                  "Siz 3 marta noto'g'ri kod kiritdingiz. Xavfsizlik uchun urinishlar vaqtincha to'xtatildi.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),
                Text(_blockTimeFormatted,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.warning)),
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
              Row(
                children: List.generate(3, (i) {
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(right: 6),
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 32),
              const Icon(Icons.sms, size: 36, color: AppColors.primary),
              const SizedBox(height: 16),
              const Text('Tasdiqlash kodi',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(
                '${widget.phoneNumber} raqamiga 6 raqamli kod yubordik',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
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
              if (widget.devCode != null && widget.devCode!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Test rejimi: SMS xizmati hali ulanmagan, kod avtomatik '
                    "to'ldirildi. Davom etish uchun tugmani bosing.",
                    style: const TextStyle(color: AppColors.primary, fontSize: 12),
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
                  onPressed: _secondsLeft == 0 ? _startResendTimer : null,
                  child: Text(
                    _secondsLeft == 0
                        ? 'Kodni qayta yuborish'
                        : "Kod kelmadimi? Qayta yuborish (0:${_secondsLeft.toString().padLeft(2, '0')})",
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
