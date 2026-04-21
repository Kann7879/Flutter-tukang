import 'package:flutter/material.dart';
import '../models/tukang.dart';
import '../models/service.dart';  // ✅ Model Service Anda
import '../models/user.dart';
import '../services/api_service.dart';

class CreateOrderPage extends StatefulWidget {
  const CreateOrderPage({super.key});

  @override
  State<CreateOrderPage> createState() => _CreateOrderPageState();
}

class _CreateOrderPageState extends State<CreateOrderPage> {
  final _deskripsiController = TextEditingController();
  final _priceController = TextEditingController();
  bool _isLoading = false;
  String? _selectedAddress;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadUserProfileAndAddresses();
  }

  Future<void> _loadUserProfileAndAddresses() async {
    try {
      final profileRes = await _apiService.getProfile();
      final userData = profileRes.data['data'] ?? profileRes.data;
      final user = User.fromJson(userData);
      
      if (user.address != null && user.address!.isNotEmpty) {
        _selectedAddress = user.address!;
        if (mounted) setState(() {});
      }
    } catch (e) {
      debugPrint('❌ Error load profile: $e');
    }
  }

  @override
Widget build(BuildContext context) {
  // ✅ FIXED: Safe cast dengan null check
  final Object? rawArgs = ModalRoute.of(context)?.settings.arguments;
  
  if (rawArgs == null || rawArgs is! Map<String, dynamic>) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          'Data tidak lengkap.\nSilakan pilih layanan dari halaman tukang.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
  
  final Map<String, dynamic> args = rawArgs;
  
  final Tukang? tukang = args['tukang'] is Tukang ? args['tukang'] as Tukang : null;
  final Service? service = args['service'] is Service ? args['service'] as Service : null;

  // ✅ Early check
  if (tukang == null || service == null) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          'Data tukang atau layanan tidak valid.\nSilakan pilih ulang.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }


    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Pesanan'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_location),
            onPressed: _showAddressManager,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔥 INFO TUKANG & SERVICE
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF2563EB).withOpacity(0.08),
                    Colors.white,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFFE8F5E9),
                    backgroundImage: tukang.foto != null && tukang.foto!.isNotEmpty
                        ? NetworkImage(tukang.foto!)
                        : null,
                    child: tukang.foto == null || tukang.foto!.isEmpty
                        ? const Icon(Icons.person, color: Color(0xFF2563EB))
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tukang.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          service.categoryName ?? 'Layanan Umum',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // ✅ FIXED: priceRange sekarang getter (tidak nullable)
                        Text(
                          service.priceRange,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // 🔥 DETAIL PESANAN
            Text(
              'Detail Pesanan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 20),

            // DESKRIPSI
            TextField(
              controller: _deskripsiController,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Deskripsi Pekerjaan *',
                hintText: 'Jelaskan detail pekerjaan yang dibutuhkan...',
                prefixIcon: Icon(Icons.description, color: Colors.grey[400]),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 🔥 ALAMAT
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Alamat *',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GestureDetector(
                      onTap: _showAddressManager,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_location_alt, 
                              size: 18, color: const Color(0xFF2563EB)),
                          const SizedBox(width: 4),
                          Text('Kelola', style: TextStyle(
                            color: const Color(0xFF2563EB),
                            fontWeight: FontWeight.w600,
                          )),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.location_on,
                          color: const Color(0xFF2563EB), size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedAddress ?? 'Masukkan alamat lengkap',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: _showAddressInputDialog,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // HARGA PENAWARAN
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Penawaran Harga (Rp) *',
                hintText: 'Contoh: 75000',
                prefixIcon: const Icon(Icons.payments, color: Color(0xFF2563EB)),
                prefixText: 'Rp ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
                ),
              ),
              onChanged: (value) {
                final numbersOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
                if (numbersOnly != value) {
                  _priceController.value = TextEditingValue(
                    text: numbersOnly,
                    selection: TextSelection.collapsed(offset: numbersOnly.length),
                  );
                }
              },
            ),

            const SizedBox(height: 40),

            // TOMBOL KIRIM
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : () => _submitOrder(context, service),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('MENGIRIM...'),
                        ],
                      )
                    : const Text(
                        'Kirim Pesanan',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // DIALOG INPUT ALAMAT
  void _showAddressInputDialog() {
    final controller = TextEditingController(text: _selectedAddress);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah Alamat'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Masukkan alamat lengkap',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final newAddress = controller.text.trim();
              if (newAddress.isNotEmpty) {
                setState(() => _selectedAddress = newAddress);
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
            ),
            child: const Text('Simpan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // MANAGER ALAMAT
  void _showAddressManager() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Kelola Alamat',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.green, size: 20),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_selectedAddress ?? 'Tidak ada alamat')),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() => _selectedAddress = null);
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
              
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF2563EB),
                  child: Icon(Icons.add, color: Colors.white),
                ),
                title: const Text('Tambah Alamat Baru'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pop(context);
                  _showAddressInputDialog();
                },
              ),
              
              ListTile(
                leading: const Icon(Icons.account_circle, color: Color(0xFF2563EB)),
                title: const Text('Ambil dari Profil'),
                subtitle: Text(_selectedAddress ?? 'Loading...'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () async {
                  await _loadUserProfileAndAddresses();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ FIXED: Terima Service object
  Future<void> _submitOrder(BuildContext context, Service service) async {
    // Validasi deskripsi
    if (_deskripsiController.text.trim().isEmpty) {
      _showError('Deskripsi pekerjaan wajib diisi!');
      return;
    }
    
    // Validasi harga
    if (_priceController.text.trim().isEmpty) {
      _showError('Penawaran harga wajib diisi!');
      return;
    }

    final price = int.tryParse(_priceController.text.trim());
    if (price == null || price <= 0) {
      _showError('Harga tidak valid!');
      return;
    }

    // Validasi alamat
    if (_selectedAddress == null || _selectedAddress!.trim().isEmpty) {
      _showError('Alamat wajib diisi!');
      return;
    }

    setState(() => _isLoading = true);

    try {
      debugPrint('🔍 Submitting order: serviceId=${service.id}, price=$price');
      
      await _apiService.createJob(
        serviceId: service.id,  // ✅ Langsung akses property (int, tidak nullable)
        deskripsi: _deskripsiController.text.trim(),
        price: price,
        alamat: _selectedAddress!.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Pesanan berhasil dikirim!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('❌ Submit error: $e');
      if (mounted) {
        _showError(e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  void dispose() {
    _deskripsiController.dispose();
    _priceController.dispose();
    super.dispose();
  }
}