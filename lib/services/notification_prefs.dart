import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Bildirishnoma sozlamalari — endi `shared_preferences` orqali qurilmada
/// SAQLANADI (ilgari faqat xotirada edi, ilova qayta ochilganda standart
/// holatga qaytardi).
class NotificationPrefs extends ChangeNotifier {
  NotificationPrefs._internal();
  static final NotificationPrefs instance = NotificationPrefs._internal();

  // Umumiy (master) tugma — o'chirilsa hech qanday bildirishnoma kelmaydi.
  bool masterEnabled = true;

  bool newBusinesses = true;
  bool specialOffers = true;
  bool birthdayDiscount = false;
  bool membershipReminders = true;
  bool transactionReceipts = true;
  bool referralUpdates = true;
  bool emailNewsletter = false;
  bool smsAds = false;

  static const _keys = [
    'masterEnabled',
    'newBusinesses', 'specialOffers', 'birthdayDiscount', 'membershipReminders',
    'transactionReceipts', 'referralUpdates', 'emailNewsletter', 'smsAds',
  ];

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      masterEnabled = prefs.getBool('masterEnabled') ?? masterEnabled;
      newBusinesses = prefs.getBool('newBusinesses') ?? newBusinesses;
      specialOffers = prefs.getBool('specialOffers') ?? specialOffers;
      birthdayDiscount = prefs.getBool('birthdayDiscount') ?? birthdayDiscount;
      membershipReminders = prefs.getBool('membershipReminders') ?? membershipReminders;
      transactionReceipts = prefs.getBool('transactionReceipts') ?? transactionReceipts;
      referralUpdates = prefs.getBool('referralUpdates') ?? referralUpdates;
      emailNewsletter = prefs.getBool('emailNewsletter') ?? emailNewsletter;
      smsAds = prefs.getBool('smsAds') ?? smsAds;
      notifyListeners();
    } catch (_) {
      // Saqlangan qiymat o'qib bo'lmasa ham standart holat bilan davom etadi
    }
  }

  /// Umumiy tugmani yoqish/o'chirish — profil va sozlamalar ekranida ishlatiladi.
  void setMaster(bool value) {
    masterEnabled = value;
    notifyListeners();
    _persist('masterEnabled', value);
  }

  void set(String key, bool value) {
    switch (key) {
      case 'masterEnabled':
        masterEnabled = value;
        break;
      case 'newBusinesses':
        newBusinesses = value;
        break;
      case 'specialOffers':
        specialOffers = value;
        break;
      case 'birthdayDiscount':
        birthdayDiscount = value;
        break;
      case 'membershipReminders':
        membershipReminders = value;
        break;
      case 'transactionReceipts':
        transactionReceipts = value;
        break;
      case 'referralUpdates':
        referralUpdates = value;
        break;
      case 'emailNewsletter':
        emailNewsletter = value;
        break;
      case 'smsAds':
        smsAds = value;
        break;
    }
    notifyListeners();
    _persist(key, value);
  }

  Future<void> _persist(String key, bool value) async {
    if (!_keys.contains(key)) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (_) {
      // Saqlab bo'lmasa ham joriy seansda sozlama ishlayveradi
    }
  }
}
