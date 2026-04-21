class Job {
  final int id;
  final int userId;
  final int? tukangProfileId;
  final int serviceId;
  final int categoryId;
  final String deskripsi;
  final int price;
  final String? alamat;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Relations - NULL SAFE
  final String? customerName;
  final String? customerPhoto;
  final String? tukangName;
  final String? tukangPhoto;
  final String? serviceName;
  final String? categoryName;
  final double? rating;
  final String? review;

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
      // 🔥 NULL-SAFE INT CASTING
      id: (json['id'] ?? 0).toInt(),
      userId: (json['user_id'] ?? 0).toInt(),
      tukangProfileId: json['tukang_profile_id']?.toInt(),
      serviceId: (json['service_id'] ?? 0).toInt(),
      categoryId: (json['category_id'] ?? 0).toInt(),
      
      // 🔥 STRING SAFE
      deskripsi: json['deskripsi'] ?? '',
      alamat: json['alamat'],
      status: json['status'] ?? 'pending',
      
      // 🔥 PRICE SAFE
      price: (json['price'] ?? 0).toInt(),
      
      // 🔥 DATETIME SAFE
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
      
      // 🔥 RELATIONS - MATCH PHP CONTROLLER FORMAT
      customerName: json['user']?['name'] ?? '',
      customerPhoto: json['user']?['photo'],
      
      tukangName: json['tukang']?['name'] ?? 
                   json['tukangProfile']?['user']?['name'] ?? 
                   json['tukang_profile']?['name'],
      tukangPhoto: json['tukang']?['foto'] ?? 
                   json['tukangProfile']?['foto'] ?? 
                   json['tukang_profile']?['foto'],
      
      serviceName: json['service']?['deskripsi'] ?? '',
      categoryName: json['service']?['category_name'] ?? 
                    json['category']?['name'] ?? '',
      
      rating: (json['tukang']?['rating'] ?? 0.0).toDouble(),
      review: json['review'],
    );
  }

  // 🔥 SAFE DATETIME PARSER
  static DateTime _parseDateTime(dynamic date) {
    if (date == null) return DateTime.now();
    try {
      if (date is String) {
        return DateTime.parse(date);
      } else if (date is int) {
        return DateTime.fromMillisecondsSinceEpoch(date);
      }
      return DateTime.now();
    } catch (e) {
      return DateTime.now();
    }
  }

  // 🔥 FORMATTER UNTUK UI
  String get formattedCreatedAt {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}';
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
    };
  }
}