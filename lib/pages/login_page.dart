import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool obscurePassword = true;
  bool isLoading = false;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final ApiService api = ApiService();

  Future<void> handleLogin() async {
    setState(() => isLoading = true);

    try {
      final response = await api.login(
        emailController.text,
        passwordController.text,
      );

      final data = response.data;

      print("LOGIN RESPONSE: $data");

      // ✅ VALIDASI TOKEN
      if (data['access_token'] == null) {
        throw Exception("Token tidak ditemukan");
      }

      // ✅ SIMPAN TOKEN & ROLE
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("token", data['access_token']);

      // ✅ VALIDASI USER & ROLE
      final role = data['user']?['role'];

      if (role == null) {
        throw Exception("Role tidak ditemukan");
      }

      final roleLower = role.toString().toLowerCase();

      // ✅ SIMPAN ROLE
      await prefs.setString("role", roleLower);

      // ✅ NAVIGASI
      if (roleLower == "pelanggan") {
        Navigator.pushReplacementNamed(context, '/dashboard_customer');
      } else if (roleLower == "tukang") {
        Navigator.pushReplacementNamed(context, '/dashboard_tukang');
      } else {
        throw Exception("Role tidak dikenali: $roleLower");
      }

    } catch (e) {
      print("ERROR LOGIN: $e");

      String message = "Login gagal";

      if (e is DioException) {
        print("STATUS: ${e.response?.statusCode}");
        print("DATA: ${e.response?.data}");

        message = e.response?.data['message'] ?? message;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF6F7FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              const Text(
                "Masuk",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 30),

              const Text("Email"),
              const SizedBox(height: 8),

              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  hintText: "name@example.com",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),

              const Text("Password"),
              const SizedBox(height: 8),

              TextField(
                controller: passwordController,
                obscureText: obscurePassword,
                decoration: InputDecoration(
                  hintText: "Masukkan password",
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        obscurePassword = !obscurePassword;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : handleLogin,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text("Masuk"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
