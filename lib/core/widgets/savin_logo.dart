import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Savin brend logotipi (SVG). `iconOnly` — faqat yashil belgi;
/// aks holda to'liq "savin" yozuvi bilan. `color` berilsa logotip shu
/// rangga bo'yaladi (masalan qorong'i fonda oq qilish uchun).
class SavinLogo extends StatelessWidget {
  final double height;
  final bool iconOnly;
  final Color? color;

  const SavinLogo({
    super.key,
    this.height = 40,
    this.iconOnly = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final asset = iconOnly
        ? 'assets/logo/logo-savin-icon.svg'
        : 'assets/logo/logo-savin.svg';
    return SvgPicture.asset(
      asset,
      height: height,
      colorFilter:
          color != null ? ColorFilter.mode(color!, BlendMode.srcIn) : null,
    );
  }
}
