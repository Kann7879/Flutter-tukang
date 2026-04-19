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
  });

  factory Tukang.fromJson(Map<String, dynamic> json) {
    return Tukang(
      id: json['id'],
      name: json['name'] ?? '',
      username: json['username'] ?? '',
      foto: json['foto'],
      deskripsi: json['deskripsi'],
      pricePerHour: json['price_per_hour'] ?? 'Rp 0',
      rating: (json['rating'] ?? 0).toDouble(),
      totalReviews: json['total_reviews'] ?? 0,
      categories: json['categories'] != null 
          ? List<String>.from(json['categories']) 
          : null,
    );
  }
}