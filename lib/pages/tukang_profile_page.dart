import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import '../services/api_service.dart';
import '../models/user.dart';
import '../models/service.dart';
import '../widgets/main_bottom_navbar.dart';
import 'add_service_page.dart';

class TukangProfilePage extends StatefulWidget {
  const TukangProfilePage({super.key});

  @override
  State<TukangProfilePage> createState() => _TukangProfilePageState();
}

class _TukangProfilePageState extends State<TukangProfilePage> {
  int _selectedIndex = 3;

  final ApiService _apiService = ApiService();

  bool _isLoading = true;
  bool _isSaving = false;

  User? _user;
  String? _fotoUrl; // FIX: simpan URL foto dari tukang profile, bukan dari User
  File? _pickedImage;
  List<Service> _services = [];

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _deskripsiController = TextEditingController();
  final TextEditingController _kotaController = TextEditingController();
  // FIX: buat controller profesi sebagai field agar bisa di-dispose
  final TextEditingController _profesiController =
      TextEditingController(text: 'Tukang');

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
  setState(() => _isLoading = true);

  try {
    print("🔍 [TUKANG] Loading profile...");
    
    final response = await _apiService.getTukangProfile();
    print("📍 FULL RESPONSE: ${response.data}");
    
    final data = response.data;
    
    if (data['data'] != null) {
      // Handle nested structure dari controller
      final nestedData = data['data'] as Map<String, dynamic>;
      final userData = {
        'id': nestedData['user']['id'],
        'name': nestedData['user']['name'],
        'username': nestedData['user']['username'],
        'email': nestedData['user']['email'],
        'foto': nestedData['profile']['foto'],
        'no_hp': nestedData['profile']['no_hp'],
        'kota': nestedData['profile']['kota'],
        'deskripsi': nestedData['profile']['deskripsi'],
      };
      
      _user = User.fromJson(userData);
      
      setState(() {
        _nameController.text = _user?.name ?? '';
        _emailController.text = _user?.email ?? '';
        _phoneController.text = nestedData['profile']['no_hp'] ?? '';
        _kotaController.text = nestedData['profile']['kota'] ?? '';
        _deskripsiController.text = nestedData['profile']['deskripsi'] ?? '';
        _fotoUrl = nestedData['profile']['foto'] ?? '';
        _isLoading = false;
      });
      
      print("✅ [TUKANG] Loaded: ${_user?.name}, ${_phoneController.text}");
      _loadServices();
    }
  } catch (e, stackTrace) {
    print("❌ [TUKANG] Error: $e\n$stackTrace");
    setState(() => _isLoading = false);
    _showErrorMessage('Gagal memuat profil: $e');
  }
}

  Future<void> _loadServices() async {
    try {
      final response = await _apiService.getMyServices();
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? response.data;
        if (!mounted) return;
        setState(() {
          _services = data.map((s) => Service.fromJson(s)).toList();
        });
        debugPrint('✅ Services loaded: ${_services.length}');
      }
    } catch (e) {
      debugPrint('⚠️ Error loading services: $e');
    }
  }

  Future<void> _deleteService(int serviceId) async {
    try {
      final response = await _apiService.deleteService(serviceId);
      if (response.statusCode == 200 || response.statusCode == 204) {
        if (!mounted) return;
        setState(() => _services.removeWhere((s) => s.id == serviceId));
        _showSuccessMessage('Layanan berhasil dihapus');
      }
    } catch (e) {
      _showErrorMessage('Gagal menghapus layanan: $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final XFile? image =
          await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (image != null) {
        if (!mounted) return;
        setState(() => _pickedImage = File(image.path));
      }
    } catch (e) {
      debugPrint('❌ Error pick image: $e');
      _showErrorMessage('Gagal memilih foto');
    }
  }

  Future<void> _saveProfile() async {
  if (_nameController.text.trim().isEmpty || _phoneController.text.trim().isEmpty) {
    _showErrorMessage('Nama & No. Telpon wajib diisi');
    return;
  }

  setState(() => _isSaving = true);

  try {
    // Update profile (tanpa foto)
    await _apiService.updateTukangProfile(
      noHp: _phoneController.text.trim(),
      kota: _kotaController.text.trim(),
      deskripsi: _deskripsiController.text.trim(),
    );

    // Upload foto TERPISAH (sesuai controller)
    if (_pickedImage != null) {
      final formData = FormData.fromMap({
        'foto': await MultipartFile.fromFile(_pickedImage!.path),
      });
      final photoResponse = await _apiService.uploadTukangPhoto(formData);
      _fotoUrl = photoResponse.data['foto_url']; // Update URL
      _pickedImage = null;
    }

    setState(() => _isSaving = false);
    _showSuccessMessage('Profil disimpan!');
    _loadProfileData();
  } catch (e) {
    setState(() => _isSaving = false);
    _showErrorMessage('$e');
  }
}

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Apakah Anda yakin ingin logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Fire-and-forget backend logout
    _apiService.logout().ignore();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      debugPrint('✅ Local data cleared');
    } catch (e) {
      debugPrint('❌ Error clear data: $e');
    }

    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  void _navigateToPage(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('role') ?? 'tukang';

    if (!mounted) return;
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(
          context,
          role == 'tukang' ? '/dashboard_tukang' : '/dashboard_customer',
        );
        break;
      case 1:
        Navigator.pushReplacementNamed(
          context,
          role == 'tukang' ? '/tukang_order' : '/customer_order',
        );
        break;
      case 2:
        Navigator.pushReplacementNamed(
          context,
          role == 'tukang' ? '/tukang_chat' : '/customer_chat',
        );
        break;
      case 3:
        break; // Sudah di halaman profil
    }
  }

  void _showErrorMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 4)),
    );
  }

  void _showSuccessMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profil Tukang'),
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Tukang'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') _logout();
            },
            itemBuilder: (_) => [
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text('Logout', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            /// FOTO PROFIL
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[300],
                      border: Border.all(
                        color: const Color(0xFF2563EB),
                        width: 3,
                      ),
                    ),
                    child: ClipOval(child: _buildProfileImage()),
                  ),
                  // FIX: tambah ikon kamera agar lebih jelas bisa di-tap
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF2563EB),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt,
                        color: Colors.white, size: 16),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),
            Text(
              'Tap untuk ganti foto',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),

            const SizedBox(height: 32),

            _buildTextField(
              controller: _nameController,
              label: 'Nama',
              hint: 'Nama belum ditambahkan',
              icon: Icons.person,
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _profesiController,
              label: 'Profesi',
              icon: Icons.work,
              readOnly: true,
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _phoneController,
              label: 'No. Telpon',
              hint: 'No. telpon belum ditambahkan',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _emailController,
              label: 'Email',
              hint: 'Email belum ditambahkan',
              icon: Icons.email,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _kotaController,
              label: 'Kota',
              hint: 'Kota belum ditambahkan',
              icon: Icons.location_city,
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _deskripsiController,
              label: 'Deskripsi',
              hint: 'Deskripsi belum ditambahkan',
              icon: Icons.description,
              maxLines: 3,
            ),

            const SizedBox(height: 32),

            /// SAVE BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Simpan Profil',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 32),

            /// SERVICES SECTION
            Text(
              'Daftar Layanan Anda',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2563EB),
                  ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          AddServicePage(onServiceAdded: _loadServices),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Tambah Layanan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            _services.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Text(
                      'Belum ada layanan. Tambahkan layanan pertama Anda!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _services.length,
                    itemBuilder: (context, index) =>
                        _buildServiceCard(_services[index]),
                  ),
          ],
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

  /// FIX: foto diambil dari _fotoUrl (tukang profile), bukan _user.foto
  Widget _buildProfileImage() {
    if (_pickedImage != null) {
      return Image.file(_pickedImage!, fit: BoxFit.cover);
    }
    if (_fotoUrl != null && _fotoUrl!.isNotEmpty) {
      return Image.network(
        _fotoUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.person,
          size: 60,
          color: Colors.grey,
        ),
      );
    }
    return const Icon(Icons.person, size: 60, color: Colors.grey);
  }

  Widget _buildServiceCard(Service service) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    service.categoryName ?? 'Kategori',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2563EB),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _confirmDeleteService(service.id),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Harga: ${_formatPrice(service.priceMin)} - ${_formatPrice(service.priceMax)}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            if (service.deskripsi != null && service.deskripsi!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  service.deskripsi!,
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteService(int serviceId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Layanan'),
        content:
            const Text('Apakah Anda yakin ingin menghapus layanan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteService(serviceId);
            },
            child:
                const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// FIX: format harga sebagai helper method, bukan inline regex panjang
  String _formatPrice(dynamic price) {
    if (price == null) return 'Rp0';
    final str = price.toString();
    final result = str.replaceAllMapped(
      RegExp(r'\d(?=(?:\d{3})+$)'),
      (m) => '${m.group(0)}.',
    );
    return 'Rp$result';
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String hint = '',
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF2563EB)),
        hintText: hint.isNotEmpty ? hint : null,
        hintStyle:
            TextStyle(color: Colors.grey[400], fontStyle: FontStyle.italic),
        prefixIcon: Icon(icon, color: const Color(0xFF2563EB)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2563EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
        ),
        filled: readOnly,
        fillColor: readOnly ? Colors.grey[200] : null,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _deskripsiController.dispose();
    _kotaController.dispose();
    _profesiController.dispose(); // FIX: dispose controller profesi
    super.dispose();
  }
}