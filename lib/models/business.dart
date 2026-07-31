class Business {
  final int id;
  final String name;
  final String categoryName;
  final String discount;
  final String rating;
  final String distance;
  final String? logo;

  Business({
    required this.id,
    required this.name,
    required this.categoryName,
    required this.discount,
    required this.rating,
    required this.distance,
    this.logo,
  });

  factory Business.fromJson(Map<String, dynamic> json) {
    return Business(
      id: json['id'] as int,
      name: json['name'] as String,
      categoryName: (json['category'] is Map) 
          ? json['category']['name'] 
          : (json['category_name'] ?? 'Kategoriya'),
      discount: json['discount']?.toString() ?? '0%',
      rating: json['rating']?.toString() ?? '5.0',
      distance: json['distance']?.toString() ?? '0 km',
      logo: json['logo'] as String?,
    );
  }
}
