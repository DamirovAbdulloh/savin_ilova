import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_animations.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  int? _expanded;

  static const _faqs = [
    (
      q: 'Premium membership qancha turadi?',
      a: 'Premium membership oyiga 20 000 so\'m. 3 oylik obuna olib, 10% tejashingiz mumkin (54 000 so\'m). 12 oylik — 25% tejash.',
    ),
    (
      q: 'QR kod qancha vaqt amal qiladi?',
      a: 'Har bir QR kod 5 daqiqa amal qiladi, keyin xavfsizlik uchun avtomatik yangilanadi. Kassaga ko\'rsatishdan oldin QR ekranini oching.',
    ),
    (
      q: 'Chegirma to\'lov chekida ko\'rinadimi?',
      a: 'Ha, hamkor tomonidan chegirma to\'g\'ridan-to\'g\'ri chekda hisoblanadi. Tranzaksiya tarixini Hamyon bo\'limida ko\'rishingiz mumkin.',
    ),
    (
      q: 'Membership\'ni qanday bekor qilaman?',
      a: 'Profil → Membership holati → Uzaytirish bo\'limidan boshqarishingiz mumkin. Bekor qilingandan keyin ham muddat tugagunga qadar amal qiladi.',
    ),
    (
      q: 'Internet bo\'lmasa QR ishlaydimi?',
      a: 'Ha — QR ekrani oxirgi yuklangan kodni keshda saqlaydi va internet yo\'q bo\'lganda ham ko\'rsatish mumkin, lekin yangilanish uchun internet kerak bo\'ladi.',
    ),
  ];

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Havolani ochib bo\'lmadi')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: const Text('Yordam markazi')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const FadeSlideIn(
              child: TextField(
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Savolingizni qidiring...',
                ),
              ),
            ),
            const SizedBox(height: 18),
            FadeSlideIn(
              delay: const Duration(milliseconds: 60),
              child: Row(
                children: [
                  Expanded(
                    child: _ContactTile(
                        icon: Icons.chat_bubble_outline,
                        label: 'Chat',
                        color: AppColors.primary,
                        onTap: () => _open('https://t.me/savinapp_support')),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ContactTile(
                        icon: Icons.call_outlined,
                        label: "Qo'ng'iroq",
                        color: const Color(0xFF3B82F6),
                        onTap: () => _open('tel:+998781505050')),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ContactTile(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        color: const Color(0xFFF59E0B),
                        onTap: () => _open('mailto:hello@savin.uz')),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const Text("KO'P SO'RALADIGAN SAVOLLAR",
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.5)),
            const SizedBox(height: 8),
            ...List.generate(_faqs.length, (i) {
              final faq = _faqs[i];
              final open = _expanded == i;
              return FadeSlideIn(
                delay: Duration(milliseconds: 100 + i * 50),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: open ? AppColors.primaryLight : AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        title: Text(faq.q,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                        trailing: Icon(open ? Icons.remove : Icons.add,
                            color: AppColors.primary),
                        onTap: () => setState(() => _expanded = open ? null : i),
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 220),
                        child: open
                            ? Padding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(faq.a,
                                      style: const TextStyle(
                                          color: AppColors.textSecondary, fontSize: 12.5, height: 1.4)),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
            FadeSlideIn(
              delay: const Duration(milliseconds: 400),
              child: PressableScale(
                onTap: () => _open('https://t.me/savinapp_support'),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    children: [
                      Text('👋', style: TextStyle(fontSize: 20)),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text('Yana yordam kerakmi?\nBizning support 24/7 ishlaydi',
                            style: TextStyle(color: Colors.white, fontSize: 12.5)),
                      ),
                      Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ContactTile({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
