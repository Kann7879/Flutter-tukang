// lib/models/service_category.dart
class ServiceCategory {
  final int id;
  final String name;
  final String icon;
  final double? rating;

  ServiceCategory({
    required this.id,
    required this.name,
    required this.icon,
    this.rating,
  });

  factory ServiceCategory.fromJson(Map<String, dynamic> json) {
    return ServiceCategory(
      id: json['id'],
      name: json['name'],
      icon: json['icon'] ?? 'construction',
      rating: json['rating']?.toDouble(),
    );
  }
}

// lib/models/tukang.dart
class Tukang {
  final int id;
  final String name;
  final String username;
  final String role;
  final String pricePerHour;
  final double rating;
  final String? foto;
  final String? deskripsi;

  Tukang({
    required this.id,
    required this.name,
    required this.username,
    required this.role,
    required this.pricePerHour,
    required this.rating,
    this.foto,
    this.deskripsi,
  });

  factory Tukang.fromJson(Map<String, dynamic> json) {
    return Tukang(
      id: json['id'],
      name: json['name'],
      username: json['username'],
      role: json['role'] ?? 'Tukang',
      pricePerHour: json['price_per_hour'] ?? 'Rp 0',
      rating: json['rating']?.toDouble() ?? 4.5,
      foto: json['foto'],
      deskripsi: json['deskripsi'],
    );
  }
}

// lib/models/user.dart
class UserModel {
  final int id;
  final String name;
  final String username;
  final String email;
  final String? foto;

  UserModel({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    this.foto,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      username: json['username'],
      email: json['email'],
      foto: json['foto'],
    );
  }
}