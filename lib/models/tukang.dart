class Tukang {
  final int id;
  final String name;
  final String username;
  final String? foto;
  final String? deskripsi;
  final String? pricePerHour;
  final double rating;
  final int totalReviews;
  final List<String>? categories;
  final List<Service>? services;

  Tukang({
    required this.id,
    required this.name,
    required this.username,
    this.foto,
    this.deskripsi,
    this.pricePerHour,
    required this.rating,
    this.totalReviews = 0,
    this.categories,
    this.services,
  });

  factory Tukang.fromJson(Map<String, dynamic> json) {
    return Tukang(
      id: json['id'],
      name: json['name'] ?? '',
      username: json['username'] ?? '',
      foto: json['foto'],
      deskripsi: json['deskripsi'],
      pricePerHour: json['price_per_hour'],
      rating: (json['rating'] ?? 0).toDouble(),
      totalReviews: json['total_reviews'] ?? 0,
      categories: json['categories'] != null
          ? List<String>.from(json['categories'])
          : null,
      services: json['services'] != null
          ? List<Map<String, dynamic>>.from(json['services'])
              .map((e) => Service.fromJson(e))
              .toList()
          : null,
    );
  }
}

class Service {
  final int id;
  final int categoryId;
  final String categoryName;
  final int priceMin;
  final int priceMax;
  final String? deskripsi;

  Service({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.priceMin,
    required this.priceMax,
    this.deskripsi,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'],
      categoryId: json['category_id'],
      categoryName: json['category_name'] ?? 'Umum',
      priceMin: json['price_min'] ?? 0,
      priceMax: json['price_max'] ?? 0,
      deskripsi: json['deskripsi'],
    );
  }

  String get priceRange {
    final min = _formatRupiah(priceMin);
    final max = _formatRupiah(priceMax);
    return '$min - $max';
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
}