import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import '../services/api_service.dart';
import '../models/user.dart';
import '../widgets/main_bottom_navbar.dart';

class CustomerProfilePage extends StatefulWidget {
  const CustomerProfilePage({super.key});

  @override
  State<CustomerProfilePage> createState() => _CustomerProfilePageState();
}

class _CustomerProfilePageState extends State<CustomerProfilePage> {
  int _selectedIndex = 3;
  
  final ApiService _apiService = ApiService();
  
  bool _isLoading = true;
  bool _isSaving = false;
  
  User? _user;
  File? _pickedImage;
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      print("🔍 Loading profile data...");
      final response = await _apiService.getProfile();
      
      print("📍 FULL RESPONSE: ${response.data}");
      print("📍 DATA TYPE: ${response.data['data'].runtimeType}");
      
      if (response.data['success'] == true && response.data['data'] != null) {
        final userData = response.data['data'] as Map<String, dynamic>;
        
        print("📍 Raw user data: $userData");
        
        _user = User.fromJson(userData); // Model sudah handle mapping
        
        setState(() {
          _nameController.text = _user!.name;
          _addressController.text = _user!.address ?? '';
          _phoneController.text = _user!.phone ?? '';
          _emailController.text = _user!.email;
          _isLoading = false;
        });
        
        print("✅ LOADED: ${_user!.name}, ${_user!.address}, ${_user!.phone}");
      } else {
        setState(() => _isLoading = false);
        _showErrorDialog("Data profil kosong");
      }
    } catch (e, stackTrace) {
      print("❌ ERROR: $e");
      print("❌ STACK: $stackTrace");
      setState(() => _isLoading = false);
      _showErrorDialog("Gagal memuat profil: $e");
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
    if (_nameController.text.isEmpty || _addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama dan Alamat tidak boleh kosong')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Update profile data
      await _apiService.updateProfile(
        name: _nameController.text,
        address: _addressController.text,
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
    final role = prefs.getString('role') ?? 'pelanggan';
    
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
          title: const Text('Profil Pelanggan'),
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Pelanggan'),
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

            /// 🔹 ALAMAT
            _buildTextField(
              controller: _addressController,
              label: 'Alamat',
              hint: _addressController.text.isEmpty ? 'Alamat belum ditambahkan' : '',
              icon: Icons.location_on,
              prefixIcon: true,
              maxLines: 3,
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
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}
