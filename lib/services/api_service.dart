import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  // Constructor
  ApiService() {
    _setupInterceptors();
  }

  // Setup interceptors untuk token
  void _setupInterceptors() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Tambahkan token ke header jika ada
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString("token");
        
        if (token != null) {
          options.headers["Authorization"] = "Bearer $token";
        }
        
        return handler.next(options);
      },
      onError: (error, handler) async {
        // Jika token expired (401), logout
        if (error.response?.statusCode == 401) {
          await logout();
        }
        return handler.next(error);
      },
    ));
  }

  // ✅ SET TOKEN MANUAL
  Future<void> setToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    if (token != null) {
      _dio.options.headers["Authorization"] = "Bearer $token";
    }
  }

  // ✅ SAVE TOKEN AFTER LOGIN
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("token", token);
    _dio.options.headers["Authorization"] = "Bearer $token";
  }

  // ✅ LOGIN
  Future<Response> login(String email, String password) async {
    try {
      final response = await _dio.post(
        "/auth/login",
        data: {
          "email": email,
          "password": password,
        },
      );
      
      // Simpan token jika login berhasil
      if (response.statusCode == 200 && response.data['token'] != null) {
        await saveToken(response.data['token']);
      }
      
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ✅ REGISTER
  Future<Response> register({
    required String username,
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await _dio.post(
        "/auth/register",
        data: {
          "username": username,
          "name": name,
          "email": email,
          "password": password,
          "password_confirmation": passwordConfirmation,
        },
      );
      
      // Simpan token jika register berhasil
      if (response.statusCode == 201 && response.data['token'] != null) {
        await saveToken(response.data['token']);
      }
      
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ✅ GET USER PROFILE
  Future<Response> getProfile() async {
    try {
      await setToken();
      return await _dio.get("/auth/me");
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ✅ GET ALL CATEGORIES
  Future<Response> getCategories() async {
    try {
      await setToken();
      return await _dio.get("/categories");
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ✅ GET TOP TUKANG (BEST RATED)
  Future<Response> getTopTukang() async {
    try {
      await setToken();
      return await _dio.get("/tukang/top");
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ✅ GET ALL TUKANG
  Future<Response> getAllTukang() async {
    try {
      await setToken();
      return await _dio.get("/tukang");
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ✅ GET TUKANG BY CATEGORY
  Future<Response> getTukangByCategory(int categoryId) async {
    try {
      await setToken();
      return await _dio.get("/tukang/category/$categoryId");
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ✅ GET TUKANG DETAIL
  Future<Response> getTukangDetail(int tukangId) async {
    try {
      await setToken();
      return await _dio.get("/tukang/$tukangId");
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ✅ SEARCH TUKANG
  Future<Response> searchTukang(String keyword) async {
    try {
      await setToken();
      return await _dio.get("/tukang/search", queryParameters: {
        "q": keyword,
      });
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ✅ CREATE JOB
  Future<Response> createJob({
    required int serviceId,
    required int categoryId,
    required String deskripsi,
    required int price,
    String? alamat,
  }) async {
    try {
      await setToken();
      return await _dio.post("/jobs", data: {
        "service_id": serviceId,
        "category_id": categoryId,
        "deskripsi": deskripsi,
        "price": price,
        "alamat": alamat,
      });
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ✅ GET MY JOBS
  Future<Response> getMyJobs() async {
    try {
      await setToken();
      return await _dio.get("/jobs");
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ✅ GET JOB DETAIL
  Future<Response> getJobDetail(int jobId) async {
    try {
      await setToken();
      return await _dio.get("/jobs/$jobId");
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ✅ CANCEL JOB
  Future<Response> cancelJob(int jobId) async {
    try {
      await setToken();
      return await _dio.put("/jobs/$jobId/cancel");
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ✅ RATE JOB
  Future<Response> rateJob({
    required int jobId,
    required double rating,
    required String review,
  }) async {
    try {
      await setToken();
      return await _dio.post("/jobs/$jobId/rating", data: {
        "rating": rating,
        "review": review,
      });
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ✅ GET FAVORITE TUKANG
  Future<Response> getFavoriteTukang() async {
    try {
      await setToken();
      return await _dio.get("/favorites");
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ✅ ADD TO FAVORITE
  Future<Response> addToFavorite(int tukangId) async {
    try {
      await setToken();
      return await _dio.post("/favorites", data: {
        "tukang_id": tukangId,
      });
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ✅ REMOVE FROM FAVORITE
  Future<Response> removeFromFavorite(int favoriteId) async {
    try {
      await setToken();
      return await _dio.delete("/favorites/$favoriteId");
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ✅ UPDATE PROFILE
  Future<Response> updateProfile({
    String? name,
    String? username,
    String? email,
    String? phone,
    String? address,
    String? foto,
  }) async {
    try {
      await setToken();
      return await _dio.put("/profile", data: {
        if (name != null) "name": name,
        if (username != null) "username": username,
        if (email != null) "email": email,
        if (phone != null) "phone": phone,
        if (address != null) "address": address,
        if (foto != null) "foto": foto,
      });
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ✅ GET TUKANG PROFILE (SPECIAL endpoint untuk tukang)
  Future<Response> getTukangProfile() async {
    try {
      await setToken();
      return await _dio.get("/tukang/profile");
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ✅ UPDATE TUKANG PROFILE
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

  // ✅ UPLOAD PROFILE PHOTO
  Future<Response> uploadProfilePhoto(FormData formData) async {
    try {
      await setToken();
      return await _dio.post("/profile/upload-photo", data: formData);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ✅ CHANGE PASSWORD
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

  // ✅ LOGOUT
  Future<void> logout() async {
    try {
      await setToken();
      await _dio.post("/auth/logout");
      print("✅ Server logout success");
    } catch (e) {
      print("⚠️ Server logout error: $e (akan clear local token anyway)");
    }
    
    // Selalu clear token lokal regardless backend success/fail
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove("token");
      _dio.options.headers.remove("Authorization");
      print("✅ Local token cleared");
    } catch (e) {
      print("❌ Error clearing local token: $e");
    }
  }

  // ✅ CHECK TOKEN VALIDITY
  Future<bool> isTokenValid() async {
    try {
      await getProfile();
      return true;
    } catch (e) {
      return false;
    }
  }

  // ✅ GET MY SERVICES
  Future<Response> getMyServices() async {
    try {
      await setToken();
      return await _dio.get("/services");
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ✅ CREATE SERVICE
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

  // ✅ UPDATE SERVICE
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

  // ✅ DELETE SERVICE
  Future<Response> deleteService(int serviceId) async {
    try {
      await setToken();
      return await _dio.delete("/services/$serviceId");
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ✅ GET NOTIFICATIONS
  Future<Response> getNotifications() async {
    try {
      await setToken();
      return await _dio.get("/notifications");
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ✅ MARK NOTIFICATION AS READ
  Future<Response> markNotificationAsRead(int notificationId) async {
    try {
      await setToken();
      return await _dio.put("/notifications/$notificationId/read");
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Error handler
  String _handleError(DioException error) {
    if (error.response != null) {
      // Server responded with error status
      final data = error.response?.data;
      if (data != null && data is Map) {
        if (data['message'] != null) {
          return data['message'];
        }
        if (data['errors'] != null) {
          final errors = data['errors'] as Map;
          return errors.values.first.first;
        }
      }
      return "Terjadi kesalahan: ${error.response?.statusCode}";
    } else if (error.type == DioExceptionType.connectionTimeout) {
      return "Koneksi timeout, silakan coba lagi";
    } else if (error.type == DioExceptionType.receiveTimeout) {
      return "Server tidak merespons, silakan coba lagi";
    } else if (error.type == DioExceptionType.connectionError) {
      return "Tidak dapat terhubung ke server";
    } else {
      return "Terjadi kesalahan: ${error.message}";
    }
  }

  // Getter untuk dio (jika perlu akses langsung)
  Dio get dio => _dio;
}