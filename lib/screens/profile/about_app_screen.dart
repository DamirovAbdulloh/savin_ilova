import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_animations.dart';
import '../../core/widgets/savin_logo.dart';
import 'terms_screen.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  Future<void> _open(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: const Text('Ilova haqida')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            FadeSlideIn(
              child: Container(
                padding: const EdgeInsets.all(24),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const SavinLogo(height: 38, color: Colors.white),
                    const SizedBox(height: 14),
                    const Text('Versiya 1.0.0 (Build 142)',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text('+ Tejash sizning odatingiz bo\'lsin',
                          style: TextStyle(color: Colors.white, fontSize: 11.5)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            FadeSlideIn(
              delay: const Duration(milliseconds: 80),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Column(
                  children: [
                    _InfoRow(icon: Icons.business_outlined, label: 'Kompaniya', value: 'Savin Tech LLC'),
                    _InfoRow(icon: Icons.location_on_outlined, label: 'Manzil', value: "Toshkent, Yunusobod"),
                    _InfoRow(icon: Icons.email_outlined, label: 'Email', value: 'hello@savin.uz'),
                    _InfoRow(icon: Icons.support_agent_outlined, label: "Qo'llab-quvvatlash", value: '+998 78 150 50 50'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            FadeSlideIn(
              delay: const Duration(milliseconds: 140),
              child: Row(
                children: [
                  Expanded(
                    child: _SocialTile(
                        label: 'Telegram',
                        icon: Icons.send,
                        onTap: () => _open('https://t.me/savinapp')),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SocialTile(
                        label: 'Instagram',
                        icon: Icons.camera_alt_outlined,
                        onTap: () => _open('https://instagram.com/savinapp')),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SocialTile(
                        label: 'YouTube',
                        icon: Icons.play_circle_outline,
                        onTap: () => _open('https://youtube.com/@savinapp')),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FadeSlideIn(
              delay: const Duration(milliseconds: 200),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Foydalanish shartlari'),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                    onTap: () => Navigator.of(context).push(
                        AppPageRoute(page: const TermsScreen())),
                  ),
                  // "Maxfiylik siyosati" bandi olib tashlandi — matni hali
                  // yozilmagan edi va bosilganda hech narsa qilmasdi.
                  // Matn tayyor bo'lgach, TermsScreen kabi ekran qo'shiladi.
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Litsenziyalar'),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                    onTap: () => showLicensePage(
                      context: context,
                      applicationName: 'Savin',
                      applicationVersion: '1.0.0',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Center(
              child: Text('© 2026 Savin Tech LLC',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            ),
            const Center(
              child: Text('Made with 💚 in Tashkent',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary, size: 20),
      title: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
      trailing: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
    );
  }
}

class _SocialTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _SocialTile({required this.label, required this.icon, required this.onTap});

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
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
