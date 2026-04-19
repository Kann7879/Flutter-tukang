class Category {
  final int id;
  final String name;
  final String? icon;
  final String? description;
  final double? rating;

  Category({
    required this.id,
    required this.name,
    this.icon,
    this.description,
    this.rating,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'] ?? '',
      icon: json['icon'],
      description: json['description'],
      rating: json['rating']?.toDouble(),
    );
  }
}