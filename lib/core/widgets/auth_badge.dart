import 'package:flutter/material.dart';

import '../theme.dart';

/// Ro'yxatdan o'tish qadamlari yuqorisidagi belgi.
///
/// Dizaynda har bir qadamda (ism, telefon, SMS kod) sarlavha ustida och
/// yashil, yumaloq burchakli kvadrat ichida emoji/ikonka turadi. Ilgari
/// ekranlarda faqat yalang'och emoji yoki ikonka chizilardi.
class AuthBadge extends StatelessWidget {
  final String? emoji;
  final IconData? icon;

  const AuthBadge({super.key, this.emoji, this.icon})
      : assert(emoji != null || icon != null,
            'AuthBadge uchun emoji yoki icon berilishi kerak');

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: emoji != null
          ? Text(emoji!, style: const TextStyle(fontSize: 26))
          : Icon(icon, size: 26, color: AppColors.primary),
    );
  }
}

/// Qadamlar ko'rsatkichi (dizayndagi uchta qisqa chiziq).
class AuthStepDots extends StatelessWidget {
  /// 1..3
  final int step;
  const AuthStepDots({super.key, required this.step});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (i) {
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
            margin: const EdgeInsets.only(right: 6),
            height: 4,
            decoration: BoxDecoration(
              color: i < step ? AppColors.primary : AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}
