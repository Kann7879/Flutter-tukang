class Service {
  final int id;
  final int tukangProfileId;
  final int categoryId;
  final int priceMin;
  final int priceMax;
  final String? deskripsi;
  final String? categoryName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Service({
    required this.id,
    required this.tukangProfileId,
    required this.categoryId,
    required this.priceMin,
    required this.priceMax,
    this.deskripsi,
    this.categoryName,
    this.createdAt,
    this.updatedAt,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: _parseInt(json['id']),                          // ✅ FIX
      tukangProfileId: _parseInt(json['tukang_profile_id']), // ✅ FIX
      categoryId: _parseInt(json['category_id']), 
      priceMin: _parseInt(json['price_min']),
      priceMax: _parseInt(json['price_max']),
      deskripsi: json['deskripsi'],
      categoryName: json['category_name'] ?? json['category']?['name'] ?? 'Umum',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  String get priceRange {
    return '${_formatRupiah(priceMin)} - ${_formatRupiah(priceMax)}';
  }

  static String _formatRupiah(int value) {
    final s = value.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      buffer.write(s[i]);
      count++;
      if (count == 3 && i != 0) {
        buffer.write('.');
        count = 0;
      }
    }
    return 'Rp ${buffer.toString().split('').reversed.join()}';
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
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