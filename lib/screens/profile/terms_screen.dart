import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_animations.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  static const _sections = [
    (
      title: '1. Umumiy qoidalar',
      body:
          "Savin ilovasidan foydalanish orqali siz ushbu shartlarni qabul qilasiz. Ilova foydalanuvchilarga 12+ kategoriyada chegirmalar olish imkonini beradi. Premium a'zolik oyiga 20 000 so'm.",
    ),
    (
      title: "2. A'zolik va to'lov",
      body:
          "Premium a'zolik 30 kun davom etadi. To'lov Click yoki Payme orqali amalga oshiriladi. Avtomatik yangilanish bekor qilinmaguncha ishlaydi. Bekor qilish istalgan vaqtda mumkin.",
    ),
    (
      title: '3. Chegirmalarni ishlatish',
      body:
          "Har bir QR kod 5 daqiqa amal qiladi va bir marta ishlatiladi. Soxta yoki noto'g'ri foydalanish aniqlanganda akkount bloklanadi.",
    ),
    (
      title: '4. Maxfiylik',
      body:
          "Sizning shaxsiy ma'lumotlaringiz uchinchi shaxslarga berilmaydi. Batafsil: Maxfiylik siyosati hujjatida.",
    ),
    (
      title: '5. Javobgarlik chegarasi',
      body:
          "Savin — hamkor bizneslar bilan foydalanuvchilar o'rtasidagi vositachi platforma. Xizmat sifati uchun javobgarlik tegishli biznesga tegishli.",
    ),
    (
      title: "6. Shartlarning o'zgarishi",
      body:
          "Savin ushbu shartlarni istalgan vaqtda yangilashi mumkin. Muhim o'zgarishlar haqida bildirishnoma orqali xabar beriladi.",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: const Text('Foydalanish shartlari')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            FadeSlideIn(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Versiya 1.2',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    SizedBox(height: 2),
                    Text("18-may 2026 · O'zbekcha",
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 11.5)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            ...List.generate(_sections.length, (i) {
              final s = _sections[i];
              return FadeSlideIn(
                delay: Duration(milliseconds: 60 + i * 50),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.title,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      const SizedBox(height: 6),
                      Text(s.body,
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 13, height: 1.5)),
                    ],
                  ),
                ),
              );
            }),
            FadeSlideIn(
              delay: Duration(milliseconds: 60 + _sections.length * 50),
              child: TextButton(
                onPressed: () {},
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("To'liq matnni o'qish"),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward, size: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
