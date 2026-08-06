import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/i18n/locale_builder.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_animations.dart';
import '../home/main_shell.dart';
import 'payment_result_screens.dart';

/// "To'lov usulini tanlang" — ro'yxatdan o'tib SMS kodni tasdiqlagandan
/// keyin obunasi yo'q foydalanuvchiga ko'rsatiladigan ekran
/// (dizayn: Auth — To'lov usuli).
///
/// Bu yerda tarif qat'iy: bir oylik Premium. Ko'p tarifli variant
/// profildagi Membership ekranida.
class PaymentMethodScreen extends StatefulWidget {
  const PaymentMethodScreen({super.key});

  static const monthlyPrice = 20000;

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  String _method = 'click';
  bool _saveCard = true;

  final _cardController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();

  String? _error;

  @override
  void dispose() {
    _cardController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  bool get _cardValid =>
      _cardController.text.replaceAll(' ', '').length == 16 &&
      _expiryController.text.length == 5 &&
      _cvvController.text.length == 3;

  void _submit() {
    if (!_cardValid) {
      setState(() => _error = 'invalid');
      return;
    }
    Navigator.of(context).push(
      AppPageRoute(
        page: PaymentProcessingScreen(
          months: 1,
          amount: PaymentMethodScreen.monthlyPrice,
          method: _method,
          firstTime: true,
        ),
      ),
    );
  }

  /// Obunani hozir olmaydiganlar ham ilovaga kira olishi kerak —
  /// QR chegirmasi Premiumsiz ishlamaydi, lekin katalog va xarita ochiq.
  void _skip() {
    Navigator.of(context).pushAndRemoveUntil(
      AppPageRoute(page: const MainShell()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LocaleBuilder(
      builder: (context, loc) => Scaffold(
        appBar: AppBar(
          leading: const BackButton(),
          actions: [
            TextButton(
              onPressed: _skip,
              child: Text(loc.t('pay_skip_for_now'),
                  style: const TextStyle(color: AppColors.textSecondary)),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dizayn: to'rtta qadamdan hammasi bosib o'tilgan
                Row(
                  children: List.generate(4, (i) {
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(right: 6),
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 26),
                FadeSlideIn(
                  child: Text(loc.t('pay_title'),
                      style: const TextStyle(
                          fontSize: 25, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(height: 4),
                Text(loc.t('pay_sub'),
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 18),

                // To'lanadigan summa — to'q yashil karta
                FadeSlideIn(
                  delay: const Duration(milliseconds: 60),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryDark,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(loc.t('pay_due'),
                                  style: const TextStyle(
                                      color: Colors.white60, fontSize: 11.5)),
                              const SizedBox(height: 2),
                              Text(loc.t('pay_plan_1m'),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(fmtSum(PaymentMethodScreen.monthlyPrice),
                                style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 21,
                                    fontWeight: FontWeight.w800)),
                            const SizedBox(width: 4),
                            Text(loc.t('wallet_som'),
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                _label(loc.t('pay_method')),
                const SizedBox(height: 8),
                _MethodRow(
                  code: 'C',
                  codeColor: const Color(0xFF00AEEF),
                  title: 'Click',
                  subtitle: loc.t('pay_click_sub'),
                  selected: _method == 'click',
                  onTap: () => setState(() => _method = 'click'),
                ),
                const SizedBox(height: 10),
                _MethodRow(
                  code: 'P',
                  codeColor: const Color(0xFF3B5BDB),
                  title: 'Payme',
                  subtitle: loc.t('pay_payme_sub'),
                  selected: _method == 'payme',
                  onTap: () => setState(() => _method = 'payme'),
                ),
                const SizedBox(height: 20),

                _label(loc.t('pay_card_info')),
                const SizedBox(height: 10),
                Text(loc.t('pay_card_number'),
                    style: const TextStyle(
                        fontSize: 12.5, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: _cardController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [_CardNumberFormatter()],
                  onChanged: (_) => setState(() => _error = null),
                  decoration: InputDecoration(
                    hintText: '8600 1234 5678 9012',
                    suffixIcon: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Align(
                        widthFactor: 1,
                        child: Text(
                          _cardController.text.startsWith('9860')
                              ? 'HUMO'
                              : 'UZCARD',
                          style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(loc.t('pay_expiry'),
                              style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _expiryController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [_ExpiryFormatter()],
                            onChanged: (_) => setState(() => _error = null),
                            decoration:
                                const InputDecoration(hintText: '12/27'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(loc.t('pay_cvv'),
                              style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _cvvController,
                            keyboardType: TextInputType.number,
                            obscureText: true,
                            maxLength: 3,
                            onChanged: (_) => setState(() => _error = null),
                            decoration: const InputDecoration(
                                hintText: '•••', counterText: ''),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () => setState(() => _saveCard = !_saveCard),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: _saveCard
                              ? AppColors.primary
                              : Colors.transparent,
                          border: Border.all(
                              color: _saveCard
                                  ? AppColors.primary
                                  : AppColors.border,
                              width: 1.5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: _saveCard
                            ? const Icon(Icons.check,
                                size: 14, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(loc.t('pay_save_card'),
                            style: const TextStyle(fontSize: 12.5)),
                      ),
                    ],
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(loc.t('pay_card_invalid'),
                      style: const TextStyle(
                          color: AppColors.danger, fontSize: 12.5)),
                ],
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submit,
                    child: Text(loc.t('pay_submit')),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(
          fontSize: 10.5,
          letterSpacing: 0.6,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary));
}

/// Click / Payme qatori (dizayndagi rangli harf belgisi bilan).
class _MethodRow extends StatelessWidget {
  final String code;
  final Color codeColor;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _MethodRow({
    required this.code,
    required this.codeColor,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: selected ? AppColors.primary : Colors.transparent,
              width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: codeColor,
                borderRadius: BorderRadius.circular(9),
              ),
              alignment: Alignment.center,
              child: Text(code,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 11.5, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppColors.primary : AppColors.border,
              size: 21,
            ),
          ],
        ),
      ),
    );
  }
}

/// "8600 1234 5678 9012" ko'rinishida guruhlaydi.
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final capped = digits.length > 16 ? digits.substring(0, 16) : digits;
    final buf = StringBuffer();
    for (var i = 0; i < capped.length; i++) {
      if (i > 0 && i % 4 == 0) buf.write(' ');
      buf.write(capped[i]);
    }
    final text = buf.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// "12/27" ko'rinishida.
class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final capped = digits.length > 4 ? digits.substring(0, 4) : digits;
    final text = capped.length <= 2
        ? capped
        : '${capped.substring(0, 2)}/${capped.substring(2)}';
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
