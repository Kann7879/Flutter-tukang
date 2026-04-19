class Order {
  final int id;
  final int userId;
  final int tukangId;
  final String status;
  final DateTime date;
  final String address;
  final int hours;
  final String? notes;
  final int totalPrice;
  final String? review;
  final double? rating;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Relations
  final String? tukangName;
  final String? tukangPhoto;
  final String? customerName;
  final String? service;

  Order({
    required this.id,
    required this.userId,
    required this.tukangId,
    required this.status,
    required this.date,
    required this.address,
    required this.hours,
    this.notes,
    required this.totalPrice,
    this.review,
    this.rating,
    required this.createdAt,
    required this.updatedAt,
    this.tukangName,
    this.tukangPhoto,
    this.customerName,
    this.service,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      tukangId: json['tukang_id'] ?? 0,
      status: json['status'] ?? 'pending',
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      address: json['address'] ?? '',
      hours: json['hours'] ?? 0,
      notes: json['notes'],
      totalPrice: json['total_price'] ?? 0,
      review: json['review'],
      rating: json['rating']?.toDouble(),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
      tukangName: json['tukang']?['user']?['name'] ?? json['tukang_name'],
      tukangPhoto: json['tukang']?['foto'] ?? json['tukang_photo'],
      customerName: json['user']?['name'] ?? json['customer_name'],
      service: json['service_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'tukang_id': tukangId,
      'status': status,
      'date': date.toIso8601String(),
      'address': address,
      'hours': hours,
      'notes': notes,
      'total_price': totalPrice,
      'review': review,
      'rating': rating,
    };
  }
}
