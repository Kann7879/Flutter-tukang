// lib/models/api_response.dart
class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final Map<String, dynamic>? errors;

  ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.errors,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(dynamic) fromJson) {
    return ApiResponse(
      success: json['success'] ?? false,
      message: json['message'],
      data: json['data'] != null ? fromJson(json['data']) : null,
      errors: json['errors'],
    );
  }
}

// lib/models/user.dart
class User {
  final int id;
  final String username;
  final String name;
  final String email;
  final String? foto;
  final String? phone;
  final String? address;
  final String? role;

  User({
    required this.id,
    required this.username,
    required this.name,
    required this.email,
    this.foto,
    this.phone,
    this.address,
    this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      foto: json['foto'],
      phone: json['phone'],
      address: json['address'],
      role: json['role'],
    );
  }
}

// lib/models/category.dart
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

// lib/models/tukang.dart
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

// lib/models/order.dart
class Order {
  final int id;
  final int tukangId;
  final String tukangName;
  final DateTime date;
  final String address;
  final int hours;
  final int totalPrice;
  final String status; // pending, confirmed, ongoing, completed, cancelled
  final String? notes;
  final DateTime createdAt;

  Order({
    required this.id,
    required this.tukangId,
    required this.tukangName,
    required this.date,
    required this.address,
    required this.hours,
    required this.totalPrice,
    required this.status,
    this.notes,
    required this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      tukangId: json['tukang_id'],
      tukangName: json['tukang_name'] ?? '',
      date: DateTime.parse(json['date']),
      address: json['address'] ?? '',
      hours: json['hours'] ?? 0,
      totalPrice: json['total_price'] ?? 0,
      status: json['status'] ?? 'pending',
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}