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
  String? _errorMessage;

  // 🔥 TAMBAHIN: mapping kategori ke ID database
  final List<Map<String, dynamic>> _categories = [
    {'name': 'Ledeng', 'icon': Icons.plumbing, 'id': 1},
    {'name': 'Listrik', 'icon': Icons.electrical_services, 'id': 2},
    {'name': 'Kebersihan', 'icon': Icons.cleaning_services, 'id': 3},
    {'name': 'Servis AC', 'icon': Icons.ac_unit, 'id': 4},
    {'name': 'Taman', 'icon': Icons.grass, 'id': 5},
    {'name': 'Pengecatan', 'icon': Icons.format_paint, 'id': 6},
  ];

  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Ambil data user
      final userRes = await _apiService.getProfile();
      User? user;
      if (userRes.data != null && userRes.data['data'] != null) {
        user = User.fromJson(userRes.data['data']);
      }

      // 🔥 AMBIL SEMUA TUKANG (bukan cuma top)
      final tukangRes = await _apiService.getAllTukang();
      List<Tukang> tukangList = [];
      
      if (tukangRes.data != null && tukangRes.data['data'] != null) {
        final rawData = List<Map<String, dynamic>>.from(tukangRes.data['data']);
        print('📦 Total tukang dari API: ${rawData.length}'); // DEBUG
        
        tukangList = rawData.map((json) {
          print('🔍 Tukang: ${json['name']} - Services: ${json['services']?.length ?? 0}');
          return Tukang.fromJson(json);
        }).toList();
      }

      setState(() {
        _userName = user?.name ?? 'Pelanggan';
        _userUsername = user?.username ?? '';
        _userAddress = user?.address ?? '';
        _topTukang = tukangList;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error load data: $e');
      setState(() {
        _userName = 'Pelanggan';
        _userAddress = '';
        _topTukang = [];
        _isLoading = false;
        _errorMessage = 'Gagal memuat data: $e';
      });
    }
  }

  // 🔥 NAVIGASI KE LIST TUKANG BY KATEGORI
  void _onCategoryTap(int categoryId, String categoryName) {
    Navigator.pushNamed(
      context, 
      '/tukang_list',
      arguments: {
        'categoryId': categoryId,
        'categoryName': categoryName,
      },
    );
  }

  void _navigateToPage(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('role') ?? 'pelanggan';

    switch (index) {
      case 0:
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
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
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
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2563EB),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)
        ],
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

  // 🔥 KATEGORI BISA DIKLIK
  Widget _buildServicesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Layanan',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.9,
          children: _categories.map((cat) {
            return GestureDetector(
              onTap: () => _onCategoryTap(cat['id'], cat['name']),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.08),
                      blurRadius: 8,
                    )
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      cat['icon'] as IconData,
                      size: 32,
                      color: const Color(0xFF2563EB),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      cat['name'] as String,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
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
            const Text(
              'Tukang Terbaik',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: _loadData,
              child: const Text(
                'Refresh',
                style: TextStyle(color: Color(0xFF2563EB)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // 🔥 TAMBAHIN: tampilin error kalau ada
        if (_errorMessage != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red[400]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red[600], fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_topTukang.isEmpty)
          Column(
            children: [
              Icon(Icons.construction, size: 48, color: Colors.grey[300]),
              const SizedBox(height: 12),
              Text(
                'Belum ada tukang yang punya layanan.',
                style: TextStyle(color: Colors.grey[500]),
              ),
              const SizedBox(height: 8),
              Text(
                'Pastikan:\n1. Tukang sudah bikin profil\n2. Tukang sudah tambah layanan\n3. Services ter-link ke category',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.grey[400]),
              ),
            ],
          )
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
    final firstService = tukang.services?.firstOrNull;
    final displayPrice = firstService?.priceRange ?? 'Rp 0';
    final displayCategory = firstService?.categoryName ??
        (tukang.categories?.isNotEmpty == true ? tukang.categories!.first : 'Umum');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 10,
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: tukang.foto != null && tukang.foto!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      tukang.foto!,
                      fit: BoxFit.cover,
                      width: 60,
                      height: 60,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.person,
                          size: 32,
                          color: Color(0xFF2563EB),
                        );
                      },
                    ),
                  )
                : const Icon(
                    Icons.person,
                    size: 32,
                    color: Color(0xFF2563EB),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        tukang.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          size: 14,
                          color: Color(0xFFFFB800),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${tukang.rating}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          ' (${tukang.totalReviews})',
                          style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.work_outline,
                      size: 12,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      displayCategory,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  tukang.deskripsi ?? firstService?.deskripsi ?? '-',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  displayPrice,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2563EB),
                  ),
                ),
                if (tukang.services != null && tukang.services!.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '+${tukang.services!.length - 1} layanan lainnya',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[400],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              // TODO: Navigate to order page
              // Navigator.pushNamed(context, '/order', arguments: {'tukangId': tukang.id});
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Pesan',
                style: TextStyle(
                  color: Color(0xFF2563EB),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}