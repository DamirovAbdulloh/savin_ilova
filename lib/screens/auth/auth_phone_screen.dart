import 'package:flutter/material.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_animations.dart';
import '../../services/auth_service.dart';
import 'auth_otp_screen.dart';

class AuthPhoneScreen extends StatefulWidget {
  final String firstName;
  final String lastName;

  const AuthPhoneScreen({super.key, required this.firstName, required this.lastName});

  @override
  State<AuthPhoneScreen> createState() => _AuthPhoneScreenState();
}

class _AuthPhoneScreenState extends State<AuthPhoneScreen> {
  final _phoneController = TextEditingController();
  bool _loading = false;
  String? _error;

  bool get _canContinue => _phoneController.text.replaceAll(' ', '').length == 9;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final fullPhone = '+998${_phoneController.text.replaceAll(' ', '')}';
    try {
      // Backend: POST /auth/register/ — ro'yxatdan o'tkazadi (SMS kod yuboradi)
      final result = await AuthService.instance.register(
        firstName: widget.firstName,
        lastName: widget.lastName,
        phoneNumber: fullPhone,
      );

      // Telefon raqami SMS kod bilan tasdiqlanadi. Backend har safar
      // tasodifiy kod yaratadi; test rejimida (provayder kredensiallari
      // qo'yilmaganda) kod javobda `dev_otp` sifatida qaytadi va OTP
      // ekranida avtomatik to'ldiriladi.
      if (!mounted) return;
      Navigator.of(context).push(
        AppPageRoute(
          page: AuthOtpScreen(
            phoneNumber: fullPhone,
            devCode: result['dev_otp'] as String?,
          ),
        ),
      );
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton()),
      // Tugma bottomNavigationBar'da — klaviatura ochilganda overflow bo'lmaydi
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: List.generate(3, (i) {
                  return Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOut,
                      margin: const EdgeInsets.only(right: 6),
                      height: 4,
                      decoration: BoxDecoration(
                        color: i <= 1 ? AppColors.primary : AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 32),
              const FadeSlideIn(
                child: Icon(Icons.phone_iphone, size: 36, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              FadeSlideIn(
                delay: const Duration(milliseconds: 80),
                child: Text(AppLocale.instance.t('auth_phone_title'),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 8),
              FadeSlideIn(
                delay: const Duration(milliseconds: 160),
                child: Text(
                  AppLocale.instance.t('auth_phone_sub'),
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
              ),
              const SizedBox(height: 28),
              FadeSlideIn(
                delay: const Duration(milliseconds: 240),
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 9,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    // Dizayn: bayroq + kod (🇺🇿 +998)
                    prefixText: '🇺🇿 +998  ',
                    hintText: '00 000 00 00',
                    counterText: '',
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Dizayn: xavfsizlik eslatmasi
              FadeSlideIn(
                delay: const Duration(milliseconds: 280),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(AppLocale.instance.t('auth_phone_secure'),
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 11.5)),
                    ),
                  ],
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                child: _error == null
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(_error!,
                            style: const TextStyle(color: AppColors.danger, fontSize: 13)),
                      ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: FadeSlideIn(
            delay: const Duration(milliseconds: 320),
            child: ElevatedButton(
              onPressed: (_canContinue && !_loading) ? _submit : null,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _loading
                    ? const SizedBox(
                        key: ValueKey('loading'),
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(AppLocale.instance.t('common_continue'), key: const ValueKey('text')),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
