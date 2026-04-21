class User {
  final int id;
  final String username;
  final String name;
  final String email;
  final String? foto;
  final String? phone;
  final String? address;
  final String? role;
  final int? totalJobs;
  final int? pendingJobs;
  final int? completedJobs;
  final double? rating;

  User({
    required this.id,
    required this.username,
    required this.name,
    required this.email,
    this.foto,
    this.phone,
    this.address,
    this.role,
    this.totalJobs,
    this.pendingJobs,
    this.completedJobs,
    this.rating,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: _parseInt(json['id']),              // ✅ FIX: safe cast
      username: json['username'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      foto: json['foto'],
      phone: json['no_telepon'] ?? json['phone'],
      address: json['alamat'] ?? json['address'],
      role: json['role'],
      totalJobs: _parseInt(json['total_jobs']),        // ✅ FIX
      pendingJobs: _parseInt(json['pending_jobs']),    // ✅ FIX
      completedJobs: _parseInt(json['completed_jobs']),// ✅ FIX
      rating: _parseDouble(json['rating']),            // ✅ FIX
    );
  }

  // ✅ Helper safe parse int
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  // ✅ Helper safe parse double
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}