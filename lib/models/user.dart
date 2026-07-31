class AppUser {
  final String id;
  final String firstName;
  final String? lastName;
  final String? phoneNumber;
  final String? email;
  final String role; // superadmin, admin, business_owner, cashier, customer
  final bool isPremium;
  final DateTime? membershipExpiresAt;
  final String? avatarUrl;

  AppUser({
    required this.id,
    required this.firstName,
    this.lastName,
    this.phoneNumber,
    this.email,
    required this.role,
    this.isPremium = false,
    this.membershipExpiresAt,
    this.avatarUrl,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id']?.toString() ?? '',
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String?,
      phoneNumber: json['phone_number'] as String?,
      email: json['email'] as String?,
      role: json['role'] as String? ?? 'customer',
      isPremium: json['is_premium'] as bool? ?? false,
      membershipExpiresAt: json['membership_expires_at'] != null
          ? DateTime.tryParse(json['membership_expires_at'] as String)
          : null,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  String get fullName => [firstName, lastName].where((e) => e != null && e.isNotEmpty).join(' ');
}
