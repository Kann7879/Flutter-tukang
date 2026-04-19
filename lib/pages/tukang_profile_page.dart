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
  File? _pickedImage;
  List<Service> _services = [];
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      print("🔍 Loading user profile data...");
      
      // Load user data
      final userResponse = await _apiService.getProfile();
      print("✅ User Response: ${userResponse.data}");
      
      if (userResponse.data != null) {
        _user = User.fromJson(userResponse.data);
        print("✅ USER DATA LOADED - Name: ${_user?.name}, Phone: ${_user?.phone}, Email: ${_user?.email}");
      }
      
      // Update UI dengan user data - show early
      setState(() {
        _nameController.text = _user?.name ?? '';
        _phoneController.text = _user?.phone ?? '';
        _emailController.text = _user?.email ?? '';
        _isLoading = false;
      });
      
      print("✅ PROFIL LOADED - UI shown");
      
      // Load tukang profile data in background
      Future.microtask(() async {
        try {
          final tukangResponse = await _apiService.getTukangProfile();
          print("📍 Tukang Response: ${tukangResponse.data}");
          
          if (tukangResponse.data != null) {
            final tukangData = tukangResponse.data['data'] ?? tukangResponse.data;
            print("✅ TUKANG DATA - foto: ${tukangData['foto']}, deskripsi: ${tukangData['deskripsi']}, no_hp: ${tukangData['no_hp']}, kota: ${tukangData['kota']}, rating: ${tukangData['rating']}");
          }
        } catch (tukangError) {
          print("⚠️ Tukang profile belum dibuat: $tukangError");
        }
      });
      
      // Load services in background
      _loadServices();
    } catch (e, stackTrace) {
      print("❌ ERROR LOAD PROFILE: $e");
      print("❌ STACK TRACE: $stackTrace");
      setState(() => _isLoading = false);
      _showErrorDialog("Gagal memuat profil: $e");
    }
  }

  Future<void> _loadServices() async {
    try {
      final response = await _apiService.getMyServices();
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? response.data;
        setState(() {
          _services = data.map((service) => Service.fromJson(service)).toList();
        });
        print("✅ Services loaded: ${_services.length}");
      }
    } catch (e) {
      print("⚠️ Error loading services: $e");
    }
  }

  Future<void> _deleteService(int serviceId) async {
    try {
      final response = await _apiService.deleteService(serviceId);
      if (response.statusCode == 200 || response.statusCode == 204) {
        setState(() {
          _services.removeWhere((s) => s.id == serviceId);
        });
        _showSuccessMessage("Layanan berhasil dihapus");
      }
    } catch (e) {
      _showErrorDialog("Gagal menghapus layanan: $e");
    }
  }

  void _showErrorDialog(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
        setState(() {
          _pickedImage = File(image.path);
        });
      }
    } catch (e) {
      print("ERROR PICK IMAGE: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memilih foto')),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama dan No. Telpon tidak boleh kosong')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Update profile data
      await _apiService.updateProfile(
        name: _nameController.text,
        phone: _phoneController.text,
        email: _emailController.text,
      );

      // Upload photo jika ada
      if (_pickedImage != null) {
        final formData = FormData.fromMap({
          "foto": await MultipartFile.fromFile(_pickedImage!.path),
        });
        await _apiService.uploadProfilePhoto(formData);
      }

      setState(() => _isSaving = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil berhasil diperbarui')),
      );

      // Reload data
      _loadProfileData();
    } catch (e) {
      print("ERROR SAVE PROFILE: $e");
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan profil: $e')),
      );
    }
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Apakah Anda yakin ingin logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                
                // Backend logout - fire and forget (don't wait)
                _apiService.logout().ignore();
                
                // Clear local data immediately
                try {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();
                  print("✅ Local data cleared");
                } catch (e) {
                  print("❌ Error clear data: $e");
                }
                
                // Navigate langsung ke login
                if (mounted) {
                  Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                  print("✅ Logged out & navigated to login");
                }
              },
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void _navigateToPage(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('role') ?? 'tukang';
    
    switch (index) {
      case 0:
        if (role == 'tukang') {
          Navigator.pushReplacementNamed(context, '/dashboard_tukang');
        } else {
          Navigator.pushReplacementNamed(context, '/dashboard_customer');
        }
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
        // Sudah di profile
        break;
    }
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
              if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder: (BuildContext context) => [
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
            /// 🔹 FOTO PROFIL
            GestureDetector(
              onTap: _pickImage,
              child: Container(
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
                child: ClipOval(
                  child: _pickedImage != null
                      ? Image.file(
                          _pickedImage!,
                          fit: BoxFit.cover,
                        )
                      : _user?.foto != null && _user!.foto!.isNotEmpty
                          ? Image.network(
                              _user!.foto!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.grey,
                              ),
                            )
                          : const Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.grey,
                            ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            Text(
              'Tap untuk ganti foto',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),

            const SizedBox(height: 32),

            /// 🔹 FORM FIELDS
            /// 🔹 NAMA
            _buildTextField(
              controller: _nameController,
              label: 'Nama',
              hint: _nameController.text.isEmpty ? 'Nama belum ditambahkan' : '',
              icon: Icons.person,
              prefixIcon: true,
            ),

            const SizedBox(height: 16),

            /// 🔹 PROFESI
            _buildTextField(
              controller: TextEditingController(text: 'Tukang'),
              label: 'Profesi',
              icon: Icons.work,
              prefixIcon: true,
              readOnly: true,
            ),

            const SizedBox(height: 16),

            /// 🔹 NO TELPON
            _buildTextField(
              controller: _phoneController,
              label: 'No. Telpon',
              hint: _phoneController.text.isEmpty ? 'No. telpon belum ditambahkan' : '',
              icon: Icons.phone,
              prefixIcon: true,
              keyboardType: TextInputType.phone,
            ),

            const SizedBox(height: 16),

            /// 🔹 EMAIL
            _buildTextField(
              controller: _emailController,
              label: 'Email',
              hint: _emailController.text.isEmpty ? 'Email belum ditambahkan' : '',
              icon: Icons.email,
              prefixIcon: true,
              keyboardType: TextInputType.emailAddress,
            ),

            const SizedBox(height: 32),

            /// 🔹 SAVE BUTTON
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
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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

            /// 🔹 LAYANAN / SERVICES SECTION
            Center(
              child: Text(
                'Daftar Layanan Anda',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2563EB),
                ),
              ),
            ),

            const SizedBox(height: 16),

            /// Add Service Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddServicePage(
                        onServiceAdded: _loadServices,
                      ),
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

            /// Services List
            _services.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Text(
                        'Belum ada layanan. Tambahkan layanan pertama Anda!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _services.length,
                    itemBuilder: (context, index) {
                      final service = _services[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
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
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red),
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) =>
                                                AlertDialog(
                                              title: const Text('Hapus Layanan'),
                                              content: const Text(
                                                'Apakah Anda yakin ingin menghapus layanan ini?',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                  child: const Text('Batal'),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    _deleteService(
                                                        service.id);
                                                    Navigator.pop(context);
                                                  },
                                                  child: const Text(
                                                    'Hapus',
                                                    style: TextStyle(
                                                        color: Colors.red),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Harga: Rp${service.priceMin.toString().replaceAllMapped(RegExp(r'\d(?=(?:\d{3})+$)'), (m) => '${m.group(0)}.')} - Rp${service.priceMax.toString().replaceAllMapped(RegExp(r'\d(?=(?:\d{3})+$)'), (m) => '${m.group(0)}.')}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  if (service.deskripsi != null &&
                                      service.deskripsi!.isNotEmpty)
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(top: 8),
                                      child: Text(
                                        service.deskripsi!,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String hint = '',
    bool prefixIcon = false,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF2563EB)),
        hintText: hint.isNotEmpty ? hint : null,
        hintStyle: TextStyle(color: Colors.grey[400], fontStyle: FontStyle.italic),
        prefixIcon: prefixIcon ? Icon(icon, color: const Color(0xFF2563EB)) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2563EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF2563EB),
            width: 2,
          ),
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
    super.dispose();
  }
}
