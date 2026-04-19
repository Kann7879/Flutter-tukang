import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/main_bottom_navbar.dart';
import '../services/api_service.dart';
import '../models/user.dart';

class DashboardTukangPage extends StatefulWidget {
  const DashboardTukangPage({super.key});

  @override
  State<DashboardTukangPage> createState() => _DashboardTukangPageState();
}

class _DashboardTukangPageState extends State<DashboardTukangPage> {
  int _selectedIndex = 0;
  
  // Statistics
  String _totalJob = "0";
  String _pending = "0";
  String _selesai = "0";
  String _rating = "0.0";

  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    try {
      final response = await _apiService.getProfile();
      print("📍 TUKANG PROFILE DATA: ${response.data}");
      
      if (response.data != null && response.data['data'] != null) {
        final userData = User.fromJson(response.data['data']);
        
        setState(() {
          // Ambil dari user object yang sudah di-parse dari database
          _totalJob = (userData.totalJobs ?? 0).toString();
          _pending = (userData.pendingJobs ?? 0).toString();
          _selesai = (userData.completedJobs ?? 0).toString();
          _rating = (userData.rating ?? 0.0).toString();
        });
        
        print("✅ STATISTIK LOADED - Total: $_totalJob, Pending: $_pending, Selesai: $_selesai, Rating: $_rating");
      }
    } catch (e) {
      print("❌ ERROR LOAD STATISTICS: $e");
      // Default ke 0 untuk tukang baru jika error
      setState(() {
        _totalJob = "0";
        _pending = "0";
        _selesai = "0";
        _rating = "0.0";
      });
    }
  }

  void _navigateToPage(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('role') ?? 'tukang';
    
    switch (index) {
      case 0:
        // Sudah di dashboard
        break;
      case 1:
        if (role == 'tukang') {
          Navigator.pushReplacementNamed(context, '/tukang_order');
        } else {
          Navigator.pushReplacementNamed(context, '/customer_order');
        }
        break;
      case 2:
        if (role == 'tukang') {
          Navigator.pushReplacementNamed(context, '/tukang_chat');
        } else {
          Navigator.pushReplacementNamed(context, '/customer_chat');
        }
        break;
      case 3:
        if (role == 'tukang') {
          Navigator.pushReplacementNamed(context, '/tukang_profile');
        } else {
          Navigator.pushReplacementNamed(context, '/customer_profile');
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF6F7FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// 🔹 HEADER
              const Text(
                "Halo, Tukang 👋",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                "Siap kerja hari ini?",
                style: TextStyle(color: Colors.grey[600]),
              ),

              const SizedBox(height: 24),

              /// 🔹 STATISTIK
              Row(
                children: [
                  _buildStatCard("Total Job", _totalJob, Icons.work),
                  const SizedBox(width: 12),
                  _buildStatCard("Pending", _pending, Icons.access_time),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  _buildStatCard("Selesai", _selesai, Icons.check_circle),
                  const SizedBox(width: 12),
                  _buildStatCard("Rating", _rating, Icons.star),
                ],
              ),

              const SizedBox(height: 30),

              /// 🔹 COMING SOON
              Center(
                child: Column(
                  children: [
                    const Icon(
                      Icons.work_outline,
                      size: 80,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Fitur Tawaran Pekerjaan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Coming Soon',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      bottomNavigationBar: MainBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
          _navigateToPage(index);
        },
      ),
    );
  }

  /// 🔹 CARD STATISTIK
  Widget _buildStatCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xff2F6BFF)),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}