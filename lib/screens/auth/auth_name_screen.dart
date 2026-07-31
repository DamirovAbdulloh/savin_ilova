import 'package:flutter/material.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_animations.dart';
import 'auth_phone_screen.dart';

class AuthNameScreen extends StatefulWidget {
  const AuthNameScreen({super.key});

  @override
  State<AuthNameScreen> createState() => _AuthNameScreenState();
}

class _AuthNameScreenState extends State<AuthNameScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  bool get _canContinue => _firstNameController.text.trim().isNotEmpty;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton()),
      // MUHIM: tugma endi bottomNavigationBar'da — klaviatura ochilganda
      // Column siqilib overflow (sariq-qora chiziqlar) bermaydi,
      // tugma esa klaviatura ustida chiroyli turadi.
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              // progress indicator (1/3)
              Row(
                children: List.generate(3, (i) {
                  return Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOut,
                      margin: const EdgeInsets.only(right: 6),
                      height: 4,
                      decoration: BoxDecoration(
                        color: i == 0 ? AppColors.primary : AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 32),
              const FadeSlideIn(
                child: Text('👋', style: TextStyle(fontSize: 36)),
              ),
              const SizedBox(height: 16),
              FadeSlideIn(
                delay: const Duration(milliseconds: 80),
                child: Text(AppLocale.instance.t('auth_name_welcome'),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 8),
              FadeSlideIn(
                delay: const Duration(milliseconds: 160),
                child: Text(
                  AppLocale.instance.t('auth_name_sub'),
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
              ),
              const SizedBox(height: 28),
              FadeSlideIn(
                delay: const Duration(milliseconds: 240),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppLocale.instance.t('auth_first_name'),
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _firstNameController,
                      textInputAction: TextInputAction.next,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(hintText: 'Aziz'),
                    ),
                    const SizedBox(height: 16),
                    Text(AppLocale.instance.t('auth_last_name'),
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _lastNameController,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(hintText: 'Karimov'),
                    ),
                  ],
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
              onPressed: _canContinue
                  ? () {
                      Navigator.of(context).push(
                        AppPageRoute(
                          page: AuthPhoneScreen(
                            firstName: _firstNameController.text.trim(),
                            lastName: _lastNameController.text.trim(),
                          ),
                        ),
                      );
                    }
                  : null,
              child: Text(AppLocale.instance.t('common_continue')),
            ),
          ),
        ),
      ),
    );
  }
}
