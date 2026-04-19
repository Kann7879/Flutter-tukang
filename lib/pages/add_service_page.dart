import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/category.dart';

class AddServicePage extends StatefulWidget {
  final VoidCallback onServiceAdded;

  const AddServicePage({super.key, required this.onServiceAdded});

  @override
  State<AddServicePage> createState() => _AddServicePageState();
}

class _AddServicePageState extends State<AddServicePage> {
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  bool _isLoadingCategories = true;

  List<Category> _categories = [];
  int? _selectedCategoryId;

  final TextEditingController _priceMinController = TextEditingController();
  final TextEditingController _priceMaxController = TextEditingController();
  final TextEditingController _deskripsiController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final response = await _apiService.getCategories();
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? response.data;
        setState(() {
          _categories = data.map((cat) => Category.fromJson(cat)).toList();
          _isLoadingCategories = false;
        });
        print("✅ Categories loaded: ${_categories.length}");
      }
    } catch (e) {
      print("⚠️ Error loading categories: $e");
      setState(() => _isLoadingCategories = false);
      _showErrorSnackBar("Gagal memuat kategori: $e");
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _submitForm() async {
    // Validasi
    if (_selectedCategoryId == null) {
      _showErrorSnackBar('Harap pilih kategori layanan');
      return;
    }

    if (_priceMinController.text.isEmpty) {
      _showErrorSnackBar('Harga minimum tidak boleh kosong');
      return;
    }

    if (_priceMaxController.text.isEmpty) {
      _showErrorSnackBar('Harga maksimum tidak boleh kosong');
      return;
    }

    try {
      int priceMin = int.parse(_priceMinController.text);
      int priceMax = int.parse(_priceMaxController.text);

      if (priceMin > priceMax) {
        _showErrorSnackBar('Harga minimum tidak boleh lebih besar dari harga maksimum');
        return;
      }

      setState(() => _isLoading = true);

      final response = await _apiService.createService(
        categoryId: _selectedCategoryId!,
        priceMin: priceMin,
        priceMax: priceMax,
        deskripsi:
            _deskripsiController.text.isNotEmpty ? _deskripsiController.text : null,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        setState(() => _isLoading = false);
        _showSuccessSnackBar('Layanan berhasil ditambahkan! ✅');

        // Panggil callback
        widget.onServiceAdded();

        // Kembali ke profile page
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      }
    } on FormatException {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Harga harus berupa angka');
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Error: $e');
      print("❌ Error creating service: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Layanan Baru'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoadingCategories
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Section
                  Text(
                    'Pilih Kategori Layanan',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2563EB),
                        ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: _selectedCategoryId,
                    hint: const Text('-- Pilih Kategori --'),
                    isExpanded: true,
                    items: _categories
                        .map((cat) => DropdownMenuItem<int>(
                              value: cat.id,
                              child: Text(cat.name),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() => _selectedCategoryId = value);
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF2563EB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF2563EB),
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF2563EB),
                          width: 2,
                        ),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Price Min Section
                  Text(
                    'Harga Minimum (Rp)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2563EB),
                        ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _priceMinController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Contoh: 100000',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF2563EB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF2563EB),
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF2563EB),
                          width: 2,
                        ),
                      ),
                      prefixIcon: const Icon(Icons.attach_money,
                          color: Color(0xFF2563EB)),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Price Max Section
                  Text(
                    'Harga Maksimum (Rp)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2563EB),
                        ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _priceMaxController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Contoh: 500000',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF2563EB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF2563EB),
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF2563EB),
                          width: 2,
                        ),
                      ),
                      prefixIcon: const Icon(Icons.attach_money,
                          color: Color(0xFF2563EB)),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Description Section
                  Text(
                    'Deskripsi Layanan (Opsional)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2563EB),
                        ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _deskripsiController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText:
                          'Jelaskan layanan yang Anda tawarkan, keahlian khusus, atau informasi penting lainnya...',
                      hintStyle:
                          TextStyle(color: Colors.grey[400], fontSize: 13),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF2563EB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF2563EB),
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF2563EB),
                          width: 2,
                        ),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        disabledBackgroundColor: Colors.grey[300],
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
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
                              'Tambah Layanan',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Cancel Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Color(0xFF2563EB),
                          width: 2,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Batal',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _priceMinController.dispose();
    _priceMaxController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }
}
