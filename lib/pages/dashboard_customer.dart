import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/tukang.dart';
import '../models/user.dart';
import '../widgets/main_bottom_navbar.dart';

class DashboardCustomerPage extends StatefulWidget {
  const DashboardCustomerPage({super.key});

  @override
  State<DashboardCustomerPage> createState() => _DashboardCustomerPageState();
}

class _DashboardCustomerPageState extends State<DashboardCustomerPage> {
  int _selectedIndex = 0;
  String _userName = "Loading...";
  String _userUsername = "";
  String _userAddress = "";
  List<Tukang> _topTukang = [];
  bool _isLoading = true;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Ledeng', 'icon': Icons.plumbing},
    {'name': 'Listrik', 'icon': Icons.electrical_services},
    {'name': 'Kebersihan', 'icon': Icons.cleaning_services},
    {'name': 'Servis AC', 'icon': Icons.ac_unit},
    {'name': 'Taman', 'icon': Icons.grass},
    {'name': 'Pengecatan', 'icon': Icons.format_paint},
  ];

  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Ambil data user (untuk nama dan alamat/lokasi)
      final userRes = await _apiService.getProfile();
      User? user;
      if (userRes.data != null && userRes.data['data'] != null) {
        user = User.fromJson(userRes.data['data']);
      }

      // Ambil tukang terbaik dari API
      final tukangRes = await _apiService.getTopTukang();
      List<Tukang> tukangList = [];
      if (tukangRes.data != null && tukangRes.data['data'] != null) {
        tukangList = List<Map<String, dynamic>>.from(tukangRes.data['data'])
            .map((json) => Tukang.fromJson(json))
            .where((t) => t.rating == 5.0)
            .toList();
      }

      setState(() {
        _userName = user?.name ?? 'Pelanggan';
        _userUsername = user?.username ?? '';
        _userAddress = user?.address ?? '';
        _topTukang = tukangList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _userName = 'Pelanggan';
        _userAddress = '';
        _topTukang = [];
        _isLoading = false;
      });
    }
  }

  void _navigateToPage(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('role') ?? 'pelanggan';
    
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
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _buildLocationSection(),
                const SizedBox(height: 20),
                _buildGreetingSection(),
                const SizedBox(height: 24),
                _buildSearchBar(),
                const SizedBox(height: 28),
                _buildServicesSection(),
                const SizedBox(height: 28),
                _buildTopTukangSection(),
              ],
            ),
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

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.location_on, color: Color(0xFF2563EB), size: 20),
            SizedBox(width: 6),
            Text('Lokasi Anda', style: TextStyle(fontSize: 14)),
          ],
        ),
        Text(
          _userAddress.isNotEmpty ? _userAddress : '-',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildGreetingSection() {
    return Row(
      children: [
        Text('Hai, ', style: TextStyle(fontSize: 24, color: Colors.grey[800])),
        Text(
          _userUsername.isNotEmpty
              ? '$_userName (@$_userUsername) 😍'
              : '$_userName 😍',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)],
      ),
      child: const TextField(
        decoration: InputDecoration(
          hintText: 'Layanan apa yang Anda butuhkan...',
          prefixIcon: Icon(Icons.search),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildServicesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Layanan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.9,
          children: _categories.map((cat) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 8)],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(cat['icon'] as IconData, size: 32, color: const Color(0xFF2563EB)),
                  const SizedBox(height: 8),
                  Text(cat['name'] as String, style: const TextStyle(fontSize: 12)),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTopTukangSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Tukang Terbaik', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () {},
              child: const Text('Lihat Semua', style: TextStyle(color: Color(0xFF2563EB))),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_topTukang.isEmpty)
          const Text('Belum ada tukang bintang 5.')
        else
          Column(
            children: _topTukang.map((tukang) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildTukangCardFromModel(tukang),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildTukangCardFromModel(Tukang tukang) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(16)),
            child: tukang.foto != null && tukang.foto!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(tukang.foto!, fit: BoxFit.cover),
                  )
                : const Icon(Icons.person, size: 32, color: Color(0xFF2563EB)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(tukang.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: Color(0xFFFFB800)),
                        const SizedBox(width: 2),
                        Text(tukang.rating.toString(), style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(tukang.deskripsi ?? '-', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                const SizedBox(height: 6),
                Text(tukang.pricePerHour ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('Pesan', style: TextStyle(color: Color(0xFF2563EB))),
          ),
        ],
      ),
    );
  }

  Widget _buildTukangCard(Map<String, dynamic> tukang) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.person, size: 32, color: Color(0xFF2563EB)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(tukang['name'], style: const TextStyle(fontWeight: FontWeight.bold))),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: Color(0xFFFFB800)),
                        const SizedBox(width: 2),
                        Text(tukang['rating'].toString(), style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(tukang['role'], style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                const SizedBox(height: 6),
                Text(tukang['price'], style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('Pesan', style: TextStyle(color: Color(0xFF2563EB))),
          ),
        ],
      ),
    );
  }

  // BottomNavigationBar sudah dipindahkan ke widgets/main_bottom_navbar.dart
}