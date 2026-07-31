import 'package:flutter/material.dart';

/// Kategoriya nomiga mos MINIMAL (monoxrom chiziqli) Material icon qaytaradi.
/// Ilgari rang-barang emoji ishlatilardi; dizaynga (minimal ko'rinish) mos
/// kelishi uchun endi bitta rangli chiziqli iconlar ishlatiladi.
IconData categoryIconFor(String name) {
  final n = name.toLowerCase();
  if (n.contains('restoran') || n.contains('restaurant')) return Icons.restaurant_outlined;
  if (n.contains('kafe') || n.contains('cafe') || n.contains('кафе')) return Icons.local_cafe_outlined;
  if (n.contains('barber')) return Icons.content_cut_outlined;
  if (n.contains('salon')) return Icons.spa_outlined;
  if (n.contains('fitness') || n.contains('gym')) return Icons.fitness_center_outlined;
  if (n.contains('supermarket') || n.contains('market') || n.contains('do\'kon')) {
    return Icons.local_grocery_store_outlined;
  }
  if (n.contains('tibbiyot') || n.contains('klinika') || n.contains('med') || n.contains('health')) {
    return Icons.local_hospital_outlined;
  }
  if (n.contains('kiyim') || n.contains('cloth') || n.contains('fashion')) return Icons.checkroom_outlined;
  if (n.contains('ta\'lim') || n.contains('talim') || n.contains('education') || n.contains('school')) {
    return Icons.school_outlined;
  }
  if (n.contains('elektron') || n.contains('electron')) return Icons.devices_outlined;
  if (n.contains('taxi') || n.contains('taksi')) return Icons.local_taxi_outlined;
  if (n.contains('travel') || n.contains('sayohat')) return Icons.flight_outlined;
  if (n.contains('avto') || n.contains('auto')) return Icons.directions_car_outlined;
  return Icons.local_offer_outlined;
}
