import 'package:flutter/material.dart';

import '../../core/i18n/app_strings.dart';
import '../../core/i18n/locale_builder.dart';
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
  String _query = '';

  /// Savol-javoblar soni. Matnlar `app_strings.dart` da uch tilda
  /// (`faq_1_q` / `faq_1_a` ...) — ilgari ular shu yerda faqat o'zbekcha
  /// yozilgan edi va til almashtirilganda o'zgarmasdi.
  static const _faqCount = 5;

  /// Qidiruvga mos savollar (savol ham, javob ham tekshiriladi).
  List<int> get _visibleFaqs {
    final loc = AppLocale.instance;
    final q = _query.trim().toLowerCase();
    final all = List.generate(_faqCount, (i) => i + 1);
    if (q.isEmpty) return all;
    return all.where((n) {
      final text = '${loc.t('faq_${n}_q')} ${loc.t('faq_${n}_a')}'.toLowerCase();
      return text.contains(q);
    }).toList();
  }

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocale.instance.t('help_link_error'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LocaleBuilder(
      builder: (context, loc) => Scaffold(
      appBar: AppBar(leading: BackButton(), title: Text(loc.t('help_title'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            FadeSlideIn(
              child: TextField(
                onChanged: (v) => setState(() {
                  _query = v;
                  _expanded = null;
                }),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: loc.t('help_search_hint'),
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
                        label: loc.t('help_chat'),
                        color: AppColors.primary,
                        onTap: () => _open('https://t.me/savinapp_support')),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ContactTile(
                        icon: Icons.call_outlined,
                        label: loc.t('help_call'),
                        color: const Color(0xFF3B82F6),
                        onTap: () => _open('tel:+998781505050')),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ContactTile(
                        icon: Icons.email_outlined,
                        label: loc.t('help_email'),
                        color: const Color(0xFFF59E0B),
                        onTap: () => _open('mailto:hello@savin.uz')),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Text(loc.t('help_faq'),
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.5)),
            const SizedBox(height: 8),
            if (_visibleFaqs.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(loc.t('help_no_results'),
                      style: const TextStyle(color: AppColors.textSecondary)),
                ),
              ),
            ...List.generate(_visibleFaqs.length, (i) {
              final n = _visibleFaqs[i];
              final open = _expanded == n;
              return FadeSlideIn(
                key: ValueKey('faq$n'),
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
                        title: Text(loc.t('faq_${n}_q'),
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13.5)),
                        trailing: Icon(open ? Icons.remove : Icons.add,
                            color: AppColors.primary),
                        onTap: () => setState(() => _expanded = open ? null : n),
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 220),
                        child: open
                            ? Padding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(loc.t('faq_${n}_a'),
                                      style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12.5,
                                          height: 1.4)),
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
                  child: Row(
                    children: [
                      const Text('👋', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                            '${loc.t('help_more_title')}\n${loc.t('help_more_sub')}',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12.5)),
                      ),
                      const Icon(Icons.arrow_forward,
                          color: Colors.white, size: 18),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
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
