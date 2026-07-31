class AppCategory {
  final int id;
  final String name;
  final String? icon;

  AppCategory({
    required this.id,
    required this.name,
    this.icon,
  });

  factory AppCategory.fromJson(Map<String, dynamic> json) {
    return AppCategory(
      id: json['id'] as int,
      name: json['name'] as String,
      icon: json['icon'] as String?,
    );
  }
}
