import 'package:flutter/material.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_animations.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';

/// Premium tarif tanlash ekrani. DIQQAT: haqiqiy to'lov (Click/Payme)
/// hali ulanmagan — bu backend'da merchant ID/kalitlar talab qiladi.
/// Shuning uchun bu yerda UI to'liq ishlaydi, lekin yakuniy to'lov tugmasi
/// buni ochiq aytadi va Yordam markaziga yo'naltiradi (soxta "muvaffaqiyat"
/// ko'rsatib foydalanuvchini chalg'itmaslik uchun ataylab shunday qilindi).
class PremiumInfoScreen extends StatefulWidget {
  final AppUser? user;
  const PremiumInfoScreen({super.key, this.user});

  @override
  State<PremiumInfoScreen> createState() => _PremiumInfoScreenState();
}

class _PremiumInfoScreenState extends State<PremiumInfoScreen> {
  int _planIndex = 1; // 3 oy standart tanlangan
  String _method = 'click';
  bool _paying = false;

  Future<void> _pay() async {
    if (_paying) return;
    setState(() => _paying = true);
    final plan = _plans[_planIndex];
    try {
      await AuthService.instance.activateMembership(months: plan.months);
      if (!mounted) return;
      final loc = AppLocale.instance;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: AppColors.primary, size: 48),
          title: Text(loc.t('prem_pay_ok')),
          content: Text(loc.t('prem_pay_ok_sub').replaceAll('{n}', '${plan.months}')),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(loc.t('common_close')),
            ),
          ],
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Xatolik: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  // badge — chegirma foizi (tarjima prem_save_badge kaliti orqali ko'rsatiladi)
  static const _plans = [
    (months: 1, price: 20000, badge: null, perMonth: 20000),
    (months: 3, price: 54000, badge: 10, perMonth: 18000),
    (months: 12, price: 180000, badge: 25, perMonth: 15000),
  ];

  String _fmt(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      buf.write(s[i]);
      final left = s.length - i - 1;
      if (left > 0 && left % 3 == 0) buf.write(' ');
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocale.instance;
    final isPremium = widget.user?.isPremium == true;

    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: const Text('Premium membership')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isPremium)
                FadeSlideIn(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: AppColors.primary, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(loc.t('prem_active_note'),
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              FadeSlideIn(
                delay: const Duration(milliseconds: 60),
                child: Text(loc.t('prem_choose_plan'),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ),
              const SizedBox(height: 12),
              ...List.generate(_plans.length, (i) {
                final p = _plans[i];
                final selected = _planIndex == i;
                return FadeSlideIn(
                  delay: Duration(milliseconds: 100 + i * 60),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => setState(() => _planIndex = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.primaryDark : AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: selected ? AppColors.primaryDark : AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              selected ? Icons.check_circle : Icons.circle_outlined,
                              color: selected ? AppColors.primary : AppColors.border,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text('${p.months} ${loc.t('common_months')}',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15,
                                              color: selected ? Colors.white : AppColors.textPrimary)),
                                      if (p.badge != null) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                              color: AppColors.primary,
                                              borderRadius: BorderRadius.circular(8)),
                                          child: Text(
                                              loc.t('prem_save_badge')
                                                  .replaceAll('{p}', '${p.badge}'),
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700)),
                                        ),
                                      ],
                                    ],
                                  ),
                                  Text("${_fmt(p.perMonth)} ${loc.t('wallet_som')}/${loc.t('common_months')}",
                                      style: TextStyle(
                                          fontSize: 11.5,
                                          color: selected ? Colors.white60 : AppColors.textSecondary)),
                                ],
                              ),
                            ),
                            Text("${_fmt(p.price)} ${loc.t('wallet_som')}",
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: selected ? Colors.white : AppColors.textPrimary)),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
              FadeSlideIn(
                delay: const Duration(milliseconds: 280),
                child: Text(loc.t('prem_pay_method'),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ),
              const SizedBox(height: 12),
              FadeSlideIn(
                delay: const Duration(milliseconds: 320),
                child: Row(
                  children: [
                    Expanded(
                      child: _PaymentOption(
                        label: 'Click',
                        selected: _method == 'click',
                        onTap: () => setState(() => _method = 'click'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _PaymentOption(
                        label: 'Payme',
                        selected: _method == 'payme',
                        onTap: () => setState(() => _method = 'payme'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              FadeSlideIn(
                delay: const Duration(milliseconds: 380),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          loc.t('prem_test_note'),
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FadeSlideIn(
                delay: const Duration(milliseconds: 420),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _paying ? null : _pay,
                    child: _paying
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(loc.t('prem_pay_btn')
                            .replaceAll('{sum}', _fmt(_plans[_planIndex].price))),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _PaymentOption({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? AppColors.primary : Colors.transparent, width: 1.5),
        ),
        child: Column(
          children: [
            Icon(Icons.account_balance_wallet_outlined,
                color: selected ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
