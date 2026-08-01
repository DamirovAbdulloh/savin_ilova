import 'dart:io';
import 'package:flutter/material.dart';

import '../../core/i18n/locale_builder.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_animations.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';

/// Profilni tahrirlash — ism, familiya, email. Telefon raqam
/// o'zgartirilmaydi (xavfsizlik uchun — SMS tasdiqlash talab qiladi).
class EditProfileScreen extends StatefulWidget {
  final AppUser? user;
  const EditProfileScreen({super.key, this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _email;
  bool _saving = false;
  String? _error;
  bool _saved = false;

  // Profil rasmi: tanlangan mahalliy fayl (yuklanayotgan) yoki serverdan
  // kelgan mavjud rasm manzili.
  File? _pickedAvatar;
  String? _avatarUrl;
  bool _uploadingAvatar = false;
  bool _avatarChanged = false;

  @override
  void initState() {
    super.initState();
    _firstName = TextEditingController(text: widget.user?.firstName ?? '');
    _lastName = TextEditingController(text: widget.user?.lastName ?? '');
    _email = TextEditingController(text: widget.user?.email ?? '');
    _avatarUrl = widget.user?.avatarUrl;
  }

  Future<void> _pickAvatar() async {
    if (_uploadingAvatar) return;
    final picker = ImagePicker();
    XFile? picked;
    try {
      picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        imageQuality: 85,
      );
    } catch (_) {
      if (mounted) {
        setState(() => _error =
            "Rasm tanlashda xatolik. Galereyaga ruxsat berilganini tekshiring.");
      }
      return;
    }
    if (picked == null) return;

    setState(() {
      _pickedAvatar = File(picked!.path);
      _uploadingAvatar = true;
      _error = null;
    });
    try {
      final updated = await AuthService.instance.updateAvatar(_pickedAvatar!);
      if (!mounted) return;
      setState(() {
        _avatarUrl = updated.avatarUrl;
        _avatarChanged = true;
      });
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _pickedAvatar = null;
      });
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await AuthService.instance.updateProfile(
        firstName: _firstName.text.trim(),
        lastName: _lastName.text.trim(),
        email: _email.text.trim(),
      );
      setState(() => _saved = true);
      await Future.delayed(const Duration(milliseconds: 900));
      if (mounted) Navigator.of(context).pop(true);
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final initial =
        _firstName.text.isNotEmpty ? _firstName.text[0].toUpperCase() : 'S';

    return LocaleBuilder(

      builder: (context, loc) => Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => Navigator.of(context).pop(_avatarChanged),
        ),
        title: Text(loc.t('edit_profile_title')),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _saving
                  ? const SizedBox(
                      key: ValueKey('l'),
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_saved ? 'Saqlandi ✓' : 'Saqlash',
                      key: const ValueKey('t'),
                      style: TextStyle(
                          color: _saved ? AppColors.primary : AppColors.primary,
                          fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: FadeSlideIn(
                  child: GestureDetector(
                    onTap: _pickAvatar,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 44,
                          backgroundColor: AppColors.primaryLight,
                          backgroundImage: _pickedAvatar != null
                              ? FileImage(_pickedAvatar!) as ImageProvider
                              : (_avatarUrl != null
                                  ? NetworkImage(_avatarUrl!) as ImageProvider
                                  : null),
                          child: (_pickedAvatar == null && _avatarUrl == null)
                              ? Text(initial,
                                  style: const TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 32,
                                      fontWeight: FontWeight.w700))
                              : null,
                        ),
                        if (_uploadingAvatar)
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.35),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.4, color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                                color: AppColors.primaryDark, shape: BoxShape.circle),
                            // Boshqa (aniqroq "rasm qo'shish") ikonka bilan almashtirildi.
                            child: const Icon(Icons.add_a_photo_rounded,
                                size: 14, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: GestureDetector(
                  onTap: _pickAvatar,
                  child: const Text('Rasmni o\'zgartirish',
                      style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 28),
              FadeSlideIn(
                delay: const Duration(milliseconds: 80),
                child: _Field(label: 'Ism *', controller: _firstName, onChanged: () => setState(() {})),
              ),
              const SizedBox(height: 16),
              FadeSlideIn(
                delay: const Duration(milliseconds: 140),
                child: _Field(label: 'Familiya', controller: _lastName),
              ),
              const SizedBox(height: 16),
              FadeSlideIn(
                delay: const Duration(milliseconds: 200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(loc.t('edit_phone'), style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.lock_outline, size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(widget.user?.phoneNumber ?? '',
                                style: const TextStyle(color: AppColors.textSecondary)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text("O'zgartirish uchun yordam markaziga murojaat qiling",
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FadeSlideIn(
                delay: const Duration(milliseconds: 260),
                child: _Field(
                  label: 'Email (ixtiyoriy)',
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                child: _error == null
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(_error!,
                            style: const TextStyle(color: AppColors.danger, fontSize: 13)),
                      ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final VoidCallback? onChanged;
  const _Field({required this.label, required this.controller, this.keyboardType, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: (_) => onChanged?.call(),
        ),
      ],
    );
  }
}
