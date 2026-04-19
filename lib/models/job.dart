class Job {
  final int id;
  final int userId;
  final int? tukangProfileId;
  final int serviceId;
  final int categoryId;
  final String deskripsi;
  final int price;
  final String? alamat;
  final String status; // pending, diterima, dikerjakan, selesai, dibatalkan
  final DateTime createdAt;
  final DateTime updatedAt;

  // Relations
  String? customerName;
  String? customerPhoto;
  String? tukangName;
  String? tukangPhoto;
  String? serviceName;
  String? categoryName;
  double? rating;
  String? review;

  Job({
    required this.id,
    required this.userId,
    this.tukangProfileId,
    required this.serviceId,
    required this.categoryId,
    required this.deskripsi,
    required this.price,
    this.alamat,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.customerName,
    this.customerPhoto,
    this.tukangName,
    this.tukangPhoto,
    this.serviceName,
    this.categoryName,
    this.rating,
    this.review,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      tukangProfileId: json['tukang_profile_id'] as int?,
      serviceId: json['service_id'] as int,
      categoryId: json['category_id'] as int,
      deskripsi: json['deskripsi'] as String? ?? '',
      price: json['price'] as int? ?? 0,
      alamat: json['alamat'] as String?,
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(json['created_at'] as String? ?? DateTime.now().toString()),
      updatedAt: DateTime.parse(json['updated_at'] as String? ?? DateTime.now().toString()),
      // Relations
      customerName: json['user']?['name'] as String?,
      customerPhoto: json['user']?['photo'] as String?,
      tukangName: json['tukang_profile']?['user']?['name'] as String?,
      tukangPhoto: json['tukang_profile']?['user']?['photo'] as String?,
      serviceName: json['service']?['nama_service'] as String?,
      categoryName: json['category']?['nama_category'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      review: json['review'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'tukang_profile_id': tukangProfileId,
      'service_id': serviceId,
      'category_id': categoryId,
      'deskripsi': deskripsi,
      'price': price,
      'alamat': alamat,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'rating': rating,
      'review': review,
    };
  }
}
