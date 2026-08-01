import 'package:flutter/material.dart';

import 'app_strings.dart';

/// Til o'zgarganda ekranni qayta chizadigan o'ram.
///
/// NIMAGA KERAK: ilova ildizida (`main.dart`) `AnimatedBuilder` bor, lekin u
/// faqat `MaterialApp` daraxtini qayta chizadi. `Navigator.push` bilan
/// ochilgan ekranlar esa Overlay ichida alohida element daraxtida turadi va
/// ota-onasi qayta chizilganda ular yangilanmaydi. Natijada profil ichidagi
/// ekranlarda til o'zgarmay qolardi.
///
/// Shu sabab har bir ochiladigan ekran o'z `Scaffold`ini shu widget bilan
/// o'raydi:
///
/// ```dart
/// @override
/// Widget build(BuildContext context) => LocaleBuilder(
///       builder: (context, loc) => Scaffold(
///         appBar: AppBar(title: Text(loc.t('profile_title'))),
///       ),
///     );
/// ```
class LocaleBuilder extends StatelessWidget {
  const LocaleBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context, AppLocale loc) builder;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppLocale.instance,
      builder: (context, _) => builder(context, AppLocale.instance),
    );
  }
}
