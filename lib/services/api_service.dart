import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/job.dart'; 

class ApiService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: "http://192.168.100.9:8000/api",
      headers: {
        "Accept": "application/json",
        "Content-Type": "application/json",
      },
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  ApiService() {
    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString("token");
        
        if (token != null) {
          options.headers["Authorization"] = "Bearer $token";
        }
        
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          await logout();
        }
        return handler.next(error);
      },
    ));
  }

  // ✅ SET TOKEN MANUAL (REMAIN)
  Future<void> setToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    if (token != null) {
      _dio.options.headers["Authorization"] = "Bearer $token";
    }
  }

  // ✅ SAVE TOKEN AFTER LOGIN (REMAIN)
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("token", token);
    _dio.options.headers["Authorization"] = "Bearer $token";
  }

  // ✅ LOGIN (MATCH ✅)
  Future<Response> login(String email, String password) async {
    try {
      final response = await _dio.post("/auth/login", data: {
        "email": email,
        "password": password,
      });
      
      if (response.statusCode == 200 && response.data['token'] != null) {
        await saveToken(response.data['token']);
      }
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ✅ REGISTER (MATCH ✅)
  Future<Response> register({
    required String username,
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await _dio.post("/auth/register", data: {
        "username": username,
        "name": name,
        "email": email,
        "password": password,
        "password_confirmation": passwordConfirmation,
      });
      
      if (response.statusCode == 201 && response.data['token'] != null) {
        await saveToken(response.data['token']);
      }
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ✅ GET FULL PROFILE (uses /customer/profile)
  Future<Response> getProfile() async {
    try {
      await setToken();
      final response = await _dio.get("/customer/profile");
      print("🔍 Profile API Response: ${response.data}");
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ✅ GET ALL CATEGORIES (MATCH ✅ - Public)
  Future<Response> getCategories() async {
    try {
      return await _dio.get("/categories"); // No auth needed
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ✅ GET TOP TUKANG (MATCH ✅ - Public)
  Future<Response> getTopTukang() async {
    try {
      return await _dio.get("/tukang/top"); // No auth needed
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ✅ GET ALL TUKANG (MATCH ✅ - Public)
  Future<Response> getAllTukang() async {
    try {
      return await _dio.get("/tukangs"); // ✅ fix
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ✅ GET TUKANG BY CATEGORY (MATCH ✅ - Public)
  Future<Response> getTukangByCategory(int categoryId) async {
    try {
      return await _dio.get("/tukangs/category/$categoryId"); // ✅ fix
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ✅ GET TUKANG DETAIL (MATCH ✅ - Public)
  Future<Response> getTukangDetail(int tukangId) async {
    try {
      return await _dio.get("/tukang/$tukangId"); // No auth needed
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ✅ SEARCH TUKANG (REMAIN - tambah route nanti)
  Future<Response> searchTukang(String keyword) async {
    try {
      await setToken();
      return await _dio.get("/tukang/search", queryParameters: {"q": keyword});
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Job>> getJobs({String? status, String? type}) async {
    try {
      final response = await _dio.get("/jobs", 
        queryParameters: {
          if (status != null) 'status': status,
          if (type != null) 'type': type,
        }
      );
      
      print("🔍 Jobs API Response: ${response.data}");
      
      if (response.statusCode == 200) {
        final List<dynamic> dataList = response.data['data'] ?? [];
        return dataList.map((json) => Job.fromJson(json)).toList();
      }
      return [];
    } on DioException catch (e) {
      print('❌ getJobs ERROR: ${e.response?.data}');
      rethrow;
    }
  }

  // ✅ FIXED createJob() - HAPUS categoryId parameter
  Future<Job> createJob({
  required int serviceId,
  required String deskripsi,
  required int price,
  required String alamat,
}) async {
  try {
    final response = await _dio.post("/jobs", data: {
      "service_id": serviceId,
      "deskripsi": deskripsi,
      "price": price,
      "alamat": alamat,
    });
    
    print("🔍 CREATE JOB RESPONSE STATUS: ${response.statusCode}");
    print("🔍 CREATE JOB RESPONSE DATA: ${response.data}");
    
    // ✅ FIXED: Handle semua kemungkinan Laravel response
    if (response.statusCode == 201 || response.statusCode == 200) {
      final jobData = response.data['data'] ?? response.data;
      return Job.fromJson(jobData);
    }
    
    // Handle Laravel error response
    final message = response.data['message'] ?? 'Gagal membuat pesanan';
    throw Exception(message);
    
  } on DioException catch (e) {
    print('❌ createJob DioException: ${e.response?.statusCode}');
    print('❌ createJob Response: ${e.response?.data}');
    
    // ✅ FIXED: Laravel validation error (422)
    if (e.response?.statusCode == 422) {
      final data = e.response?.data;
      if (data != null && data['errors'] != null) {
        final errors = data['errors'] as Map;
        String errorMsg = 'Validasi gagal:\n';
        errors.forEach((key, value) {
          errorMsg += '• $key: ${value.first}\n';
        });
        throw Exception(errorMsg.trim());
      }
    }
    
    // ✅ FIXED: Laravel auth error (401/403)
    if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
      throw Exception('Token tidak valid. Silakan login ulang.');
    }
    
    // ✅ FIXED: Service not found (404)
    if (e.response?.statusCode == 404) {
      throw Exception('Layanan tidak ditemukan.');
    }
    
    throw Exception(_handleError(e));
    
  } catch (e) {
    print('❌ createJob General Error: $e');
    rethrow;
  }
}

  // ✅ GET MY JOBS (MATCH ✅)
  Future<Response> getMyJobs() async {
    try {
      await setToken();
      return await _dio.get("/jobs");
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ✅ GET JOB DETAIL (MATCH ✅)
  Future<Response> getJobDetail(int jobId) async {
    try {
      await setToken();
      return await _dio.get("/jobs/$jobId");
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ✅ CANCEL JOB (REMAIN - pakai update job)
  Future<Response> cancelJob(int jobId) async {
    try {
      await setToken();
      return await _dio.put("/jobs/$jobId", data: {"status": "cancelled"});
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ✅ RATE JOB (REMAIN - pakai reviews)
  Future<Response> rateJob({
    required int jobId,
    required double rating,
    required String review,
  }) async {
    try {
      await setToken();
      return await _dio.post("/reviews", data: {
        "job_id": jobId,
        "rating": rating,
        "review": review,
      });
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ✅ GET FAVORITE TUKANG (REMAIN - tambah route nanti)
  Future<Response> getFavoriteTukang() async {
    try {
      await setToken();
      return await _dio.get("/favorites");
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ✅ ADD TO FAVORITE (REMAIN)
  Future<Response> addToFavorite(int tukangId) async {
    try {
      await setToken();
      return await _dio.post("/favorites", data: {"tukang_id": tukangId});
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ✅ REMOVE FROM FAVORITE (REMAIN)
  Future<Response> removeFromFavorite(int favoriteId) async {
    try {
      await setToken();
      return await _dio.delete("/favorites/$favoriteId");
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ✅ UPDATE FULL PROFILE (uses /customer/profile)
Future<Response> updateProfile({
  String? name,
  String? address,
  String? phone,
  String? email,
}) async {
  try {
    await setToken();
    return await _dio.post("/customer/profile", data: {
      if (name != null) "name": name,
      if (email != null) "email": email,
      if (address != null) "alamat": address,
      if (phone != null) "no_telepon": phone,
    });
  } on DioException catch (e) {
    throw _handleError(e);
  }
}

  // ✅ GET TUKANG PROFILE (MATCH ✅)
  Future<Response> getTukangProfile() async {
    try {
      await setToken();
      return await _dio.get("/tukang/profile");
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ✅ UPDATE TUKANG PROFILE (MATCH ✅)
  Future<Response> updateTukangProfile({
    String? deskripsi,
    String? noHp,
    String? kota,
  }) async {
    try {
      await setToken();
      return await _dio.post("/tukang/profile", data: {
        if (deskripsi != null) "deskripsi": deskripsi,
        if (noHp != null) "no_hp": noHp,
        if (kota != null) "kota": kota,
      });
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> uploadTukangPhoto(FormData formData) async {
    try {
      await setToken();
      return await _dio.post("/tukang/profile/photo", data: formData);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ✅ GET TUKANG DASHBOARD (MATCH ✅)
  Future<Response> getTukangDashboard() async {
    try {
      await setToken();
      return await _dio.get("/tukang/dashboard");
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ✅ UPLOAD PHOTO (buat route baru nanti, sementara kosong)
  Future<Response> uploadProfilePhoto(FormData formData) async {
    try {
      await setToken();
      // TODO: Buat route /api/profile/upload-photo
      return await _dio.post("/profile/upload-photo", data: formData);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ✅ CHANGE PASSWORD (REMAIN - tambah route nanti)
  Future<Response> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    try {
      await setToken();
      return await _dio.put("/profile/change-password", data: {
        "current_password": currentPassword,
        "password": newPassword,
        "password_confirmation": newPasswordConfirmation,
      });
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ✅ LOGOUT (MATCH ✅)
  Future<void> logout() async {
    try {
      await setToken();
      await _dio.post("/auth/logout");
      print("✅ Server logout success");
    } catch (e) {
      print("⚠️ Server logout error: $e");
    }
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove("token");
      _dio.options.headers.remove("Authorization");
      print("✅ Local token cleared");
    } catch (e) {
      print("❌ Error clearing local token: $e");
    }
  }

  // ✅ CHECK TOKEN VALIDITY (REMAIN)
  Future<bool> isTokenValid() async {
    try {
      await getProfile();
      return true;
    } catch (e) {
      return false;
    }
  }

  // ✅ GET MY SERVICES (MATCH ✅)
  Future<Response> getMyServices() async {
    try {
      await setToken();
      return await _dio.get("/services/my");
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ✅ CREATE SERVICE (MATCH ✅)
  Future<Response> createService({
    required int categoryId,
    required int priceMin,
    required int priceMax,
    String? deskripsi,
  }) async {
    try {
      await setToken();
      return await _dio.post("/services", data: {
        "category_id": categoryId,
        "price_min": priceMin,
        "price_max": priceMax,
        if (deskripsi != null) "deskripsi": deskripsi,
      });
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ✅ UPDATE SERVICE (REMAIN - tambah route nanti)
  Future<Response> updateService({
    required int serviceId,
    int? categoryId,
    int? priceMin,
    int? priceMax,
    String? deskripsi,
  }) async {
    try {
      await setToken();
      return await _dio.put("/services/$serviceId", data: {
        if (categoryId != null) "category_id": categoryId,
        if (priceMin != null) "price_min": priceMin,
        if (priceMax != null) "price_max": priceMax,
        if (deskripsi != null) "deskripsi": deskripsi,
      });
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ✅ DELETE SERVICE (REMAIN - tambah route nanti)
  Future<Response> deleteService(int serviceId) async {
    try {
      await setToken();
      return await _dio.delete("/services/$serviceId");
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ✅ GET NOTIFICATIONS (REMAIN - tambah route nanti)
  Future<Response> getNotifications() async {
    try {
      await setToken();
      return await _dio.get("/notifications");
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ✅ MARK NOTIFICATION AS READ (REMAIN)
  Future<Response> markNotificationAsRead(int notificationId) async {
    try {
      await setToken();
      return await _dio.put("/notifications/$notificationId/read");
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ✅ NEW: CUSTOMER HISTORY (MATCH ✅)
  Future<Response> getCustomerLastOrder() async {
    try {
      await setToken();
      return await _dio.get("/customer/last-order");
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> getCustomerHistory() async {
    try {
      await setToken();
      return await _dio.get("/customer/history");
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ✅ NEW: TUKANG HISTORY (MATCH ✅)
  Future<Response> getTukangHistory() async {
    try {
      await setToken();
      return await _dio.get("/tukang/history");
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> getTukangLastJob() async {
    try {
      await setToken();
      return await _dio.get("/tukang/last-job");
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ✅ NEW: TRANSACTIONS (MATCH ✅)
  Future<Response> createTransaction(Map<String, dynamic> data) async {
    try {
      await setToken();
      return await _dio.post("/transactions", data: data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> getMyTransactions() async {
    try {
      await setToken();
      return await _dio.get("/transactions/my");
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> payTransaction(int transactionId) async {
    try {
      await setToken();
      return await _dio.patch("/transactions/$transactionId/pay");
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ✅ NEW: MESSAGES (MATCH ✅)
  Future<Response> sendMessage(Map<String, dynamic> data) async {
    try {
      await setToken();
      return await _dio.post("/messages", data: data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> getMessages(int jobId) async {
    try {
      await setToken();
      return await _dio.get("/messages/$jobId");
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException error) {
    if (error.response != null) {
      final data = error.response?.data;
      if (data != null && data is Map) {
        if (data['message'] != null) return data['message'];
        if (data['errors'] != null) {
          final errors = data['errors'] as Map;
          return errors.values.first.first;
        }
      }
      return "Terjadi kesalahan: ${error.response?.statusCode}";
    } else if (error.type == DioExceptionType.connectionTimeout) {
      return "Koneksi timeout";
    } else if (error.type == DioExceptionType.receiveTimeout) {
      return "Server tidak merespons";
    } else if (error.type == DioExceptionType.connectionError) {
      return "Tidak dapat terhubung ke server";
    }
    return "Terjadi kesalahan: ${error.message}";
  }

  Dio get dio => _dio;
}