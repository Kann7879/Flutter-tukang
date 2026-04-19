class Service {
  final int id;
  final int tukangProfileId;
  final int categoryId;
  final int priceMin;
  final int priceMax;
  final String? deskripsi;
  final String? categoryName;
  final DateTime createdAt;
  final DateTime updatedAt;

  Service({
    required this.id,
    required this.tukangProfileId,
    required this.categoryId,
    required this.priceMin,
    required this.priceMax,
    this.deskripsi,
    this.categoryName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'] ?? 0,
      tukangProfileId: json['tukang_profile_id'] ?? 0,
      categoryId: json['category_id'] ?? 0,
      priceMin: json['price_min'] ?? 0,
      priceMax: json['price_max'] ?? 0,
      deskripsi: json['deskripsi'],
      categoryName: json['category']?['name'] ?? json['category_name'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tukang_profile_id': tukangProfileId,
      'category_id': categoryId,
      'price_min': priceMin,
      'price_max': priceMax,
      'deskripsi': deskripsi,
    };
  }
}
