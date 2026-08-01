import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_animations.dart';
import '../../core/widgets/confetti_overlay.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/catalog_service.dart';
import '../../services/wallet_service.dart';
import '../profile/premium_info_screen.dart';

String _formatQrSum(num v) {
  final loc = AppLocale.instance;
  final s = v.round().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    buf.write(s[i]);
    final left = s.length - i - 1;
    if (left > 0 && left % 3 == 0) buf.write(' ');
  }
  return "${buf.toString()} ${loc.t('wallet_som')}";
}

/// QR ekrani вЂ” to'q yashil fonda, foydalanuvchining haqiqiy ma'lumotlari
/// bilan. Kod har 5 daqiqada avtomatik yangilanadi. Qo'shimcha holatlar:
/// internet yo'qligida kesh QR, obuna tugaganda blok, va (hozircha kassa
/// integratsiyasi yo'qligi sababli) demo tasdiqlash oqimi konfetti bilan.
class QrScreen extends StatefulWidget {
  const QrScreen({super.key});

  @override
  State<QrScreen> createState() => _QrScreenState();
}

class _QrScreenState extends State<QrScreen> {
  static const _validitySeconds = 5 * 60;

  Timer? _timer;
  int _secondsLeft = _validitySeconds;
  AppUser? _user;
  String _qrData = _generateQrData(null);
  bool _offline = false;
  bool _loadedOnce = false;
  bool _showSuccess = false;
  bool _redeeming = false;
  TransactionItem? _lastRedeem;
  WalletStats? _walletStats;

  static String _generateQrData(AppUser? user) =>
      'SAVIN-USER-${user?.id ?? 'guest'}-${DateTime.now().millisecondsSinceEpoch}';

  /// QR skanerlanmasa kassir qo'lda kiritadigan kod — telefon raqami.
  /// Backend uni ham qabul qiladi (UUID/email bilan bir qatorda).
  String get _manualCode {
    final phone = _user?.phoneNumber ?? '';
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 9) return phone.isEmpty ? '—' : phone;
    final d = digits.substring(digits.length - 9);
    return '+998 ${d.substring(0, 2)} ${d.substring(2, 5)} '
        '${d.substring(5, 7)} ${d.substring(7, 9)}';
  }

  Future<void> _copyManualCode() async {
    final code = _manualCode;
    if (code == '—') return;
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocale.instance.t('qr_manual_copied')),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Til o'zgarganda QR ekrani ham darhol yangi tilda chizilsin
    AppLocale.instance.addListener(_onLocaleChanged);
    _startTimer();
    _loadUser();
  }

  void _onLocaleChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadUser() async {
    try {
      final user = await AuthService.instance.fetchMe();
      if (!mounted) return;
      setState(() {
        _user = user;
        _qrData = _generateQrData(user);
        _offline = false;
        _loadedOnce = true;
      });
      // Hamyon statistikasi ixtiyoriy вЂ” muvaffaqiyatsiz bo'lsa ham QR
      // ekranining asosiy ishlashiga ta'sir qilmasin.
      try {
        final stats = await WalletService.instance.fetchStats();
        if (mounted) setState(() => _walletStats = stats);
      } catch (_) {
        // jim o'tkazib yuboriladi вЂ” pastdagi karta "вЂ”" ko'rsatadi
      }
    } catch (_) {
      // Internet/server bilan bog'lanib bo'lmadi вЂ” birinchi marta bo'lsa
      // "offline" bannerini ko'rsatamiz, keshdagi (joriy) QR ishlatiladi.
      if (!mounted) return;
      setState(() {
        _offline = true;
        _loadedOnce = true;
      });
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_secondsLeft <= 1) {
        setState(() {
          _qrData = _generateQrData(_user);
          _secondsLeft = _validitySeconds;
        });
        // Vaqti-vaqti bilan tarmoqni qayta tekshiramiz вЂ” internet qaytgan
        // bo'lishi mumkin.
        if (_offline) _loadUser();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _refreshNow() {
    setState(() {
      _qrData = _generateQrData(_user);
      _secondsLeft = _validitySeconds;
    });
    _startTimer();
    if (_offline) _loadUser();
  }


  String get _formattedTime {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  /// QR kod BLOKLANGANmi? вЂ” Premium a'zolik bo'lmasa (yoki muddati tugagan
  /// bo'lsa) chegirma QR kodi BERILMAYDI. Foydalanuvchi ma'lumoti hali
  /// yuklanmagan bo'lsa (null) bloklamaymiz вЂ” yuklashni kutamiz.
  bool get _isLocked {
    if (_user == null) return false;
    return _user!.isPremium != true;
  }

  @override
  void dispose() {
    AppLocale.instance.removeListener(_onLocaleChanged);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocale.instance;
    final name = _user?.fullName.isNotEmpty == true ? _user!.fullName : 'Savin foydalanuvchisi';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primaryDark, Color(0xFF0A2E1B)],
        ),
      ),
      child: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 24),
                FadeSlideIn(
                  child: Text(loc.t('qr_title'),
                      style: const TextStyle(
                          color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 4),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 80),
                  child: Text(loc.t('qr_subtitle'),
                      style: const TextStyle(color: Colors.white54, fontSize: 13)),
                ),
                if (_offline) ...[
                  const SizedBox(height: 14),
                  FadeSlideIn(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.wifi_off, color: AppColors.warning, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(loc.t('qr_offline'),
                                style: const TextStyle(color: AppColors.warning, fontSize: 11.5)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 160),
                  child: PressableScale(
                    onTap: _isLocked ? null : _refreshNow,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 30,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            transitionBuilder: (child, anim) =>
                                FadeTransition(opacity: anim, child: child),
                            child: ImageFiltered(
                              key: ValueKey(_qrData),
                              imageFilter: _isLocked
                                  ? ColorFilter.mode(
                                      Colors.white.withValues(alpha: 0.7), BlendMode.srcOver)
                                  : const ColorFilter.mode(
                                      Colors.transparent, BlendMode.dst),
                              child: QrImageView(
                                data: _qrData,
                                version: QrVersions.auto,
                                size: 220,
                              ),
                            ),
                          ),
                          if (_isLocked)
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: const BoxDecoration(
                                  color: Colors.white, shape: BoxShape.circle),
                              child: const Icon(Icons.lock_outline,
                                  size: 32, color: AppColors.textSecondary),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (_isLocked)
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 220),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 32),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                          color: Colors.white, borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        children: [
                          Text(loc.t('qr_expired_title'),
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                          const SizedBox(height: 6),
                          Text(loc.t('qr_expired_sub'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => Navigator.of(context).push(
                                  AppPageRoute(page: PremiumInfoScreen(user: _user))),
                              child: Text(loc.t('qr_extend')),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 240),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const _PulsingDot(),
                          const SizedBox(width: 8),
                          Text(loc.t('qr_refresh_wait').replaceAll('{time}', _formattedTime),
                              style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                if (!_isLocked && _loadedOnce)
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 280),
                    // QR skanerlanmasa kassir shu kodni qo'lda kiritadi
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Column(
                        children: [
                          Text(
                            loc.t('qr_manual_hint'),
                            style: const TextStyle(color: Colors.white54, fontSize: 11.5),
                          ),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: _copyManualCode,
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _manualCode,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.5,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.copy_rounded,
                                      color: Colors.white54, size: 15),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const Spacer(),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 320),
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: Colors.white10, borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_user?.isPremium == true
                                      ? loc.t('qr_member_premium')
                                      : loc.t('qr_member_standard'),
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
                              Text(name,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                            _walletStats == null
                                ? 'вЂ”'
                                : "${_formatQrSum(_walletStats!.savedAllTime)}\n${loc.t('qr_saved_label')}",
                            textAlign: TextAlign.end,
                            style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Muvaffaqiyatli tasdiqlash overlay (demo)
          if (_showSuccess)
            _SuccessOverlay(
              tx: _lastRedeem,
              onClose: () {
                setState(() => _showSuccess = false);
                // Yangi tejash Hamyon tarixiga yozilgan bo'lishi mumkin вЂ”
                // qaytganda karta yangilanishi uchun statistikani qayta olamiz.
                if (_lastRedeem != null) {
                  WalletService.instance.fetchStats().then((s) {
                    if (mounted) setState(() => _walletStats = s);
                  }).catchError((_) {});
                }
              },
              onNewQr: () {
                setState(() {
                  _showSuccess = false;
                  _qrData = _generateQrData(_user);
                  _secondsLeft = _validitySeconds;
                });
                _startTimer();
              },
            ),
        ],
      ),
    );
  }
}

class _SuccessOverlay extends StatelessWidget {
  final VoidCallback onClose;
  final VoidCallback onNewQr;
  // Haqiqiy backendga yozilgan tranzaksiya (bo'lsa) вЂ” shu yerdan ko'rsatiladi.
  // `null` bo'lsa (masalan internet yo'q edi), demo raqamlar bilan
  // ko'rsatiladi, lekin bu holat Hamyon tarixiga YOZILMAGAN bo'ladi.
  final TransactionItem? tx;
  const _SuccessOverlay({required this.onClose, required this.onNewQr, this.tx});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocale.instance;
    final businessName = tx?.businessName ?? 'Fresh Cut Barber';
    final original = tx?.originalAmount ?? 50000;
    final discountPct = tx?.discountPercent ?? 35;
    final discount = tx?.savedAmount ?? ((original * discountPct) ~/ 100);
    final toPay = original - discount;
    final som = loc.t('wallet_som');

    return Positioned.fill(
      child: Container(
        color: const Color(0xFF0A2E1B).withValues(alpha: 0.96),
        child: Stack(
          children: [
            const Positioned.fill(child: ConfettiOverlay(play: true)),
            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: FadeSlideIn(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.4, end: 1),
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.elasticOut,
                          builder: (context, v, child) =>
                              Transform.scale(scale: v, child: child),
                          child: Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.5),
                                    blurRadius: 30),
                              ],
                            ),
                            child: const Icon(Icons.check, color: Colors.white, size: 44),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(loc.t('qr_success_title'),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Text(loc.t('qr_success_sub').replaceAll('{name}', businessName),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white60, fontSize: 12.5)),
                        if (tx == null) ...[
                          const SizedBox(height: 4),
                          Text(loc.t('qr_success_offline'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white38, fontSize: 10.5)),
                        ],
                        const SizedBox(height: 22),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              Text(loc.t('qr_success_saved_title'),
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                              const SizedBox(height: 4),
                              CountUpText(
                                value: discount.toDouble(),
                                formatter: (v) => "${v.round()} $som",
                                style: const TextStyle(
                                    fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.primary),
                                duration: const Duration(milliseconds: 700),
                              ),
                              const Divider(height: 24),
                              _row(loc.t('qr_success_original'), '$original $som'),
                              const SizedBox(height: 6),
                              _row("${loc.t('qr_success_discount')} ($discountPct%)", '-$discount $som',
                                  color: AppColors.primary),
                              const SizedBox(height: 6),
                              _row(loc.t('qr_success_to_pay'), '$toPay $som', bold: true),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: onClose,
                            child: Text(loc.t('qr_success_back')),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: onNewQr,
                          child: Text(loc.t('qr_success_new'),
                              style: const TextStyle(color: Colors.white70)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {Color? color, bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                color: color ?? AppColors.textPrimary)),
      ],
    );
  }
}

/// Yashil "pulsatsiya" qiluvchi nuqta.
class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.35, end: 1).animate(_controller),
      child: const Icon(Icons.circle, size: 8, color: AppColors.primary),
    );
  }
}

