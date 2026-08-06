import 'package:flutter/material.dart';

import '../../core/i18n/locale_builder.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_animations.dart';
import '../../models/user.dart';
import '../payment/payment_result_screens.dart';

/// "Membership" — profildan obuna olish/uzaytirish ekrani
/// (dizayn: Membership — Uzaytirish).
///
/// Ro'yxatdan o'tgandan keyingi birinchi to'lov boshqa oqim:
/// `PaymentMethodScreen` (bir oylik, karta ma'lumotlari bilan).
class PremiumInfoScreen extends StatefulWidget {
  final AppUser? user;
  const PremiumInfoScreen({super.key, this.user});

  @override
  State<PremiumInfoScreen> createState() => _PremiumInfoScreenState();
}

class _PremiumInfoScreenState extends State<PremiumInfoScreen> {
  int _planIndex = 1; // dizaynda 3 oy tavsiya etiladi
  String _method = 'click';

  // badge — chegirma foizi
  static const _plans = [
    (months: 1, price: 20000, badge: null, perMonth: 20000),
    (months: 3, price: 54000, badge: 10, perMonth: 18000),
    (months: 12, price: 180000, badge: 25, perMonth: 15000),
  ];

  int? get _daysLeft {
    final exp = widget.user?.membershipExpiresAt;
    if (exp == null) return null;
    final d = exp.difference(DateTime.now()).inDays;
    return d < 0 ? 0 : d;
  }

  Future<void> _pay() async {
    final plan = _plans[_planIndex];
    final ok = await Navigator.of(context).push<bool>(
      AppPageRoute(
        page: PaymentProcessingScreen(
          months: plan.months,
          amount: plan.price,
          method: _method,
        ),
      ),
    );
    if (ok == true && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = widget.user?.isPremium == true;
    final expires = widget.user?.membershipExpiresAt;

    return LocaleBuilder(
      builder: (context, loc) => Scaffold(
        appBar: AppBar(
          leading: const BackButton(),
          centerTitle: true,
          title: Text(loc.t('mem_title'),
              style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Joriy holat — to'q yashil karta
                FadeSlideIn(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryDark,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(loc.t('mem_current'),
                                      style: const TextStyle(
                                          color: Colors.white60,
                                          fontSize: 11)),
                                  const SizedBox(height: 2),
                                  const Text('Premium',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: isPremium
                                    ? AppColors.primary
                                    : Colors.white24,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isPremium) ...[
                                    const Icon(Icons.check,
                                        size: 12, color: Colors.white),
                                    const SizedBox(width: 3),
                                  ],
                                  Text(
                                      loc.t(isPremium
                                          ? 'mem_active'
                                          : 'mem_inactive'),
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (isPremium && expires != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            loc
                                .t('mem_until_days')
                                .replaceAll('{date}', fmtDate(expires))
                                .replaceAll('{n}', '${_daysLeft ?? 0}'),
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 22),

                Text(loc.t('mem_choose_plan'),
                    style: const TextStyle(
                        fontSize: 10.5,
                        letterSpacing: 0.6,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary)),
                const SizedBox(height: 10),
                ...List.generate(_plans.length, (i) {
                  final p = _plans[i];
                  final selected = _planIndex == i;
                  return FadeSlideIn(
                    delay: Duration(milliseconds: 60 + i * 60),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => setState(() => _planIndex = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.primaryLight
                                : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.border,
                                width: selected ? 1.6 : 1),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                selected
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.border,
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                            '${p.months} ${loc.t('common_months')}',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 15)),
                                        if (p.badge != null) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2),
                                            decoration: BoxDecoration(
                                                color: AppColors.primary,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        999)),
                                            child: Text(
                                                loc.t('mem_recommended'),
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight:
                                                        FontWeight.w700)),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                        '${fmtSum(p.perMonth)} ${loc.t('mem_per_month')}',
                                        style: const TextStyle(
                                            fontSize: 11.5,
                                            color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(fmtSum(p.price),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16)),
                                  Text(
                                    p.badge == null
                                        ? loc.t('wallet_som')
                                        : loc
                                            .t('mem_save_pct')
                                            .replaceAll('{p}', '${p.badge}'),
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: p.badge == null
                                            ? FontWeight.w400
                                            : FontWeight.w700,
                                        color: p.badge == null
                                            ? AppColors.textSecondary
                                            : AppColors.primary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 12),

                Text(loc.t('pay_method'),
                    style: const TextStyle(
                        fontSize: 10.5,
                        letterSpacing: 0.6,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _MethodCard(
                        code: 'C',
                        codeColor: const Color(0xFF00AEEF),
                        label: 'Click',
                        selected: _method == 'click',
                        onTap: () => setState(() => _method = 'click'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MethodCard(
                        code: 'P',
                        codeColor: const Color(0xFF3B5BDB),
                        label: 'Payme',
                        selected: _method == 'payme',
                        onTap: () => setState(() => _method = 'payme'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _pay,
                    child: Text(loc.t('mem_pay_btn').replaceAll(
                        '{sum}', fmtSum(_plans[_planIndex].price))),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text(loc.t('mem_autorenew'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Click / Payme kartochkasi (dizayndagi ikki ustunli variant).
class _MethodCard extends StatelessWidget {
  final String code;
  final Color codeColor;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _MethodCard({
    required this.code,
    required this.codeColor,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.6 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: codeColor,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(code,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14)),
            ),
            const SizedBox(height: 10),
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
