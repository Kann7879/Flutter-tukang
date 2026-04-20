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
    // Debug print
    print("   📝 Parsing JSON: $json");
    
    return Service(
      id: json['id'] ?? 0,
      tukangProfileId: json['tukang_profile_id'] ?? 0,
      categoryId: json['category_id'] ?? 0,
      priceMin: _parseInt(json['price_min']),
      priceMax: _parseInt(json['price_max']),
      deskripsi: json['deskripsi'],
      // 🔥 PRIORITAS: category_name (dari mapped response) > category.name (dari Eloquent)
      categoryName: json['category_name'] ?? json['category']?['name'] ?? 'Umum',
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    try {
      return DateTime.parse(value.toString());
    } catch (e) {
      return DateTime.now();
    }
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