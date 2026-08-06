import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/i18n/app_strings.dart';
import '../../core/i18n/locale_builder.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_animations.dart';
import '../../core/widgets/confetti_overlay.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../home/main_shell.dart';

/// To'lovning natijasi — chek uchun kerakli ma'lumot.
class PaymentResult {
  final int months;
  final int amount;
  final String method; // 'click' | 'payme'
  final DateTime paidAt;
  final DateTime validUntil;
  final String reference;

  const PaymentResult({
    required this.months,
    required this.amount,
    required this.method,
    required this.paidAt,
    required this.validUntil,
    required this.reference,
  });

  String get methodLabel => method == 'payme' ? 'Payme' : 'Click';
}

String fmtSum(int v) {
  final s = v.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    buf.write(s[i]);
    final left = s.length - i - 1;
    if (left > 0 && left % 3 == 0) buf.write(' ');
  }
  return buf.toString();
}

String fmtDate(DateTime d) {
  const months = [
    'yan', 'fev', 'mar', 'apr', 'may', 'iyn',
    'iyl', 'avg', 'sen', 'okt', 'noy', 'dek',
  ];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}

/// "To'lov amalga oshmoqda" (dizayn: Auth — To'lov amalga oshmoqda).
///
/// Uchta qadam ketma-ket yonadi, shu vaqtda backendga a'zolikni
/// faollashtirish so'rovi ketadi. Natijaga qarab muvaffaqiyat yoki
/// xatolik ekraniga o'tadi.
class PaymentProcessingScreen extends StatefulWidget {
  final int months;
  final int amount;
  final String method;

  /// Ro'yxatdan o'tgandan keyingi birinchi to'lovmi? (dizayndagi
  /// "Tabriklaymiz" ekrani) yoki profildan olingan obunami (chek ekrani).
  final bool firstTime;

  const PaymentProcessingScreen({
    super.key,
    required this.months,
    required this.amount,
    required this.method,
    this.firstTime = false,
  });

  @override
  State<PaymentProcessingScreen> createState() =>
      _PaymentProcessingScreenState();
}

class _PaymentProcessingScreenState extends State<PaymentProcessingScreen> {
  int _step = 0; // 0..2
  Timer? _stepTimer;

  @override
  void initState() {
    super.initState();
    _stepTimer = Timer.periodic(const Duration(milliseconds: 900), (t) {
      if (!mounted) return;
      if (_step < 2) setState(() => _step++);
    });
    _pay();
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    super.dispose();
  }

  Future<void> _pay() async {
    AppUser? user;
    String? error;
    try {
      user = await AuthService.instance.activateMembership(
        months: widget.months,
      );
    } catch (e) {
      error = e.toString();
    }

    // Qadamlar ko'rinib ulgursin
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;

    if (error != null || user == null) {
      Navigator.of(context).pushReplacement(
        AppPageRoute(
          page: PaymentFailedScreen(
            months: widget.months,
            amount: widget.amount,
            method: widget.method,
            firstTime: widget.firstTime,
          ),
        ),
      );
      return;
    }

    final now = DateTime.now();
    final result = PaymentResult(
      months: widget.months,
      amount: widget.amount,
      method: widget.method,
      paidAt: now,
      validUntil: user.membershipExpiresAt ??
          now.add(Duration(days: 30 * widget.months)),
      reference:
          'SVN-${now.year}-${now.millisecondsSinceEpoch.remainder(10000).toString().padLeft(4, '0')}',
    );

    Navigator.of(context).pushReplacement(
      AppPageRoute(
        page: widget.firstTime
            ? PaymentWelcomeScreen(user: user)
            : PaymentReceiptScreen(result: result),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LocaleBuilder(
      builder: (context, loc) => Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Aylanma indikator ichida karta ikonkasi
                  SizedBox(
                    width: 132,
                    height: 132,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 132,
                          height: 132,
                          child: CircularProgressIndicator(
                            strokeWidth: 10,
                            color: AppColors.primary,
                            backgroundColor:
                                AppColors.primary.withValues(alpha: 0.15),
                          ),
                        ),
                        Container(
                          width: 74,
                          height: 74,
                          decoration: const BoxDecoration(
                              color: AppColors.surface, shape: BoxShape.circle),
                          alignment: Alignment.center,
                          child: const Icon(Icons.credit_card,
                              size: 32, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(loc.t('pay_processing'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(loc.t('pay_processing_sub'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 26),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _stepRow(loc.t('pay_step_card'), 0),
                        const SizedBox(height: 14),
                        _stepRow(loc.t('pay_step_bank'), 1),
                        const SizedBox(height: 14),
                        _stepRow(loc.t('pay_step_tx'), 2),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.info_outline,
                          size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(loc.t('pay_processing_note'),
                            style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11.5)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _stepRow(String label, int index) {
    final done = _step > index;
    final active = _step == index;
    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: done
                ? AppColors.primary
                : (active
                    ? AppColors.primary.withValues(alpha: 0.25)
                    : AppColors.border.withValues(alpha: 0.5)),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: done
              ? const Icon(Icons.check, size: 13, color: Colors.white)
              : (active
                  ? const _Dot()
                  : const SizedBox.shrink()),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: done || active ? FontWeight.w600 : FontWeight.w400,
                color: done || active
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              )),
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration:
          const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
    );
  }
}

/// "Tabriklaymiz, Aziz!" — ro'yxatdan o'tib obuna olgandan keyingi ekran
/// (dizayn: Auth — Welcome (Premium)).
class PaymentWelcomeScreen extends StatelessWidget {
  final AppUser? user;
  const PaymentWelcomeScreen({super.key, this.user});

  void _enterApp(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      AppPageRoute(page: const MainShell()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = (user?.firstName.isNotEmpty == true)
        ? user!.firstName
        : (user?.fullName ?? '');

    return LocaleBuilder(
      builder: (context, loc) => Scaffold(
        backgroundColor: AppColors.primary,
        body: Stack(
          children: [
            const Positioned.fill(child: ConfettiOverlay(play: true)),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const Spacer(),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.4, end: 1),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.elasticOut,
                      builder: (context, v, child) =>
                          Transform.scale(scale: v, child: child),
                      child: Container(
                        width: 108,
                        height: 108,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.28),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Container(
                          width: 78,
                          height: 78,
                          decoration: const BoxDecoration(
                              color: Colors.white, shape: BoxShape.circle),
                          child: const Icon(Icons.check,
                              size: 42, color: AppColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    Text(
                      '${loc.t('pay_welcome_title').replaceAll('{name}', name)} 🎉',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Color(0xFF0B2D06),
                          fontSize: 26,
                          fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      loc.t('pay_welcome_sub'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Color(0xFF14401A),
                          fontSize: 13.5,
                          height: 1.45),
                    ),
                    const SizedBox(height: 26),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        children: [
                          Text(loc.t('pay_welcome_avg'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12)),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              const Text('200 000',
                                  style: TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.w800)),
                              const SizedBox(width: 6),
                              Text(
                                  "${loc.t('wallet_som')} ${loc.t('pay_welcome_saves')}",
                                  style: const TextStyle(
                                      fontSize: 12.5,
                                      color: AppColors.textSecondary)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryDark),
                        onPressed: () => _enterApp(context),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(loc.t('pay_welcome_cta')),
                            const SizedBox(width: 6),
                            const Icon(Icons.arrow_forward, size: 18),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
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

/// "To'lov amalga oshmadi" (dizayn: Pricing — Error).
class PaymentFailedScreen extends StatelessWidget {
  final int months;
  final int amount;
  final String method;
  final bool firstTime;

  const PaymentFailedScreen({
    super.key,
    required this.months,
    required this.amount,
    required this.method,
    this.firstTime = false,
  });

  void _retry(BuildContext context) {
    Navigator.of(context).pushReplacement(
      AppPageRoute(
        page: PaymentProcessingScreen(
          months: months,
          amount: amount,
          method: method,
          firstTime: firstTime,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LocaleBuilder(
      builder: (context, loc) => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const Spacer(),
                Container(
                  width: 132,
                  height: 132,
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    width: 74,
                    height: 74,
                    decoration: const BoxDecoration(
                        color: AppColors.danger, shape: BoxShape.circle),
                    child: const Icon(Icons.close,
                        size: 38, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 26),
                Text(loc.t('pay_failed_title'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                Text(loc.t('pay_failed_sub'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.45)),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 14, color: AppColors.danger),
                      const SizedBox(width: 6),
                      Text(
                          '${loc.t('pay_error_code')}: PAY_INSUFFICIENT_FUNDS',
                          style: const TextStyle(
                              color: AppColors.danger,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _retry(context),
                    child: Text(loc.t('pay_retry')),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(loc.t('pay_other_card')),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(loc.t('pay_need_help'),
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                    TextButton(
                      onPressed: () => launchUrl(
                        Uri.parse('https://t.me/savinapp_support'),
                        mode: LaunchMode.externalApplication,
                      ),
                      child: Text(loc.t('auth_otp_support'),
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "To'lov muvaffaqiyatli!" + chek (dizayn: Pricing — Success).
class PaymentReceiptScreen extends StatelessWidget {
  final PaymentResult result;
  const PaymentReceiptScreen({super.key, required this.result});

  String _chequeText(AppLocale loc) {
    return 'Savin — ${loc.t('pay_cheque')} #${result.reference}\n'
        '${loc.t('pay_cheque_plan')}: ${result.months} ${loc.t('common_months')} Premium\n'
        '${loc.t('pay_cheque_method')}: ${result.methodLabel}\n'
        '${loc.t('pay_cheque_date')}: ${fmtDate(result.paidAt)}\n'
        '${loc.t('pay_cheque_valid')}: ${loc.t('pay_until').replaceAll('{date}', fmtDate(result.validUntil))}\n'
        '${loc.t('pay_cheque_total')}: ${fmtSum(result.amount)} ${loc.t('wallet_som')}';
  }

  @override
  Widget build(BuildContext context) {
    return LocaleBuilder(
      builder: (context, loc) => Scaffold(
        backgroundColor: AppColors.primary,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 26),
                Container(
                  width: 92,
                  height: 92,
                  decoration: const BoxDecoration(
                      color: Colors.white, shape: BoxShape.circle),
                  child: const Icon(Icons.check,
                      size: 46, color: AppColors.primary),
                ),
                const SizedBox(height: 18),
                Text(loc.t('pay_ok_title'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Color(0xFF0B2D06),
                        fontSize: 23,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(loc.t('pay_ok_sub'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Color(0xFF14401A), fontSize: 12.5)),
                const SizedBox(height: 22),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(loc.t('pay_cheque'),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 15)),
                          Text('#${result.reference}',
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12)),
                        ],
                      ),
                      const Divider(height: 24),
                      _row(loc.t('pay_cheque_plan'),
                          '${result.months} ${loc.t('common_months')} Premium'),
                      _row(loc.t('pay_cheque_method'), result.methodLabel),
                      _row(loc.t('pay_cheque_date'),
                          '${fmtDate(result.paidAt)}, '
                          '${result.paidAt.hour.toString().padLeft(2, '0')}:'
                          '${result.paidAt.minute.toString().padLeft(2, '0')}'),
                      _row(
                          loc.t('pay_cheque_valid'),
                          loc
                              .t('pay_until')
                              .replaceAll('{date}', fmtDate(result.validUntil))),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(loc.t('pay_cheque_total'),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 15)),
                          Text(
                              '${fmtSum(result.amount)} ${loc.t('wallet_som')}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: AppColors.primary)),
                        ],
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryDark),
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(loc.t('pay_start_cta')),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: BorderSide.none,
                    ),
                    onPressed: () async {
                      await Clipboard.setData(
                          ClipboardData(text: _chequeText(loc)));
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(loc.t('pay_cheque_copied'))),
                      );
                    },
                    icon: const Icon(Icons.download, size: 17),
                    label: Text(loc.t('pay_download_cheque')),
                  ),
                ),
                const SizedBox(height: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12.5)),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.end,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 12.5)),
          ),
        ],
      ),
    );
  }
}
