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
      id: json['id'],
      username: json['username'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      foto: json['foto'],
      phone: json['no_telepon'] ?? json['phone'],
      address: json['alamat'] ?? json['address'],
      role: json['role'],
      totalJobs: json['total_jobs'] ?? 0,
      pendingJobs: json['pending_jobs'] ?? 0,
      completedJobs: json['completed_jobs'] ?? 0,
      rating: (json['rating'] is int) 
          ? (json['rating'] as int).toDouble()
          : (json['rating'] as double?) ?? 0.0,
    );
  }
}