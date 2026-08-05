import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../core/widgets/app_animations.dart';
import '../../services/deep_link_service.dart';
import '../auth/auth_name_screen.dart';
import '../splash_onboarding/language_select_screen.dart';

/// "Do'stingiz sizni taklif qildi" — taklif havolasi bosilganda ochiladigan
/// birinchi ekran (dizayn: "Referal — Taklifni qabul qilish").
///
/// Havola ilovada ochilganda kod saqlanadi va shu ekran ko'rsatiladi.
/// "Ro'yxatdan o'tish" bosilsa oddiy ro'yxatdan o'tish oqimi boshlanadi —
/// kod avtomatik qo'shiladi, ya'ni do'st ro'yxatdan o'tishi bilan taklif
/// hisoblanadi (to'liq bo'lishi uchun u bir hafta ilovaga kirishi kerak).
class InviteAcceptScreen extends StatelessWidget {
  final String code;
  const InviteAcceptScreen({super.key, required this.code});

  void _continueToRegister(BuildContext context) {
    Navigator.of(context).pushReplacement(
      AppPageRoute(page: const AuthNameScreen()),
    );
  }

  void _later(BuildContext context) {
    Navigator.of(context).pushReplacement(
      AppPageRoute(page: const LanguageSelectScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(),
              FadeSlideIn(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Text('🎁', style: TextStyle(fontSize: 44)),
                ),
              ),
              const SizedBox(height: 24),
              FadeSlideIn(
                delay: const Duration(milliseconds: 80),
                child: const Text(
                  "Sizni Savin'ga taklif qilishdi!",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 10),
              FadeSlideIn(
                delay: const Duration(milliseconds: 120),
                child: const Text(
                  "Ro'yxatdan o'ting — 400+ joyda chegirmalardan foydalanishni "
                  "bugunoq boshlaysiz.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
                ),
              ),
              const SizedBox(height: 24),
              FadeSlideIn(
                delay: const Duration(milliseconds: 160),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      const Text('TAKLIF KODI',
                          style: TextStyle(
                              fontSize: 10.5,
                              letterSpacing: 1,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      Text(code,
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              FadeSlideIn(
                delay: const Duration(milliseconds: 200),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Perk('400+ joyda 10–40% chegirma'),
                      SizedBox(height: 8),
                      _Perk('Cheksiz QR foydalanish'),
                      SizedBox(height: 8),
                      _Perk('Istalgan vaqtda bekor qilish'),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              FadeSlideIn(
                delay: const Duration(milliseconds: 260),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _continueToRegister(context),
                    child: const Text("Ro'yxatdan o'tish"),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => _later(context),
                child: const Text('Keyinroq',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _Perk extends StatelessWidget {
  final String text;
  const _Perk(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle, size: 17, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 13)),
        ),
      ],
    );
  }
}

/// Deep link kodi kelganini tekshirib, kerak bo'lsa taklif ekranini ochadi.
Route<dynamic>? inviteRouteIfPending() {
  final code = DeepLinkService.instance.justArrivedCode;
  if (code == null || code.isEmpty) return null;
  return AppPageRoute(page: InviteAcceptScreen(code: code));
}
