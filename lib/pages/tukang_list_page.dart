import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/tukang.dart';

class TukangListPage extends StatefulWidget {
  final int categoryId;
  final String categoryName;

  const TukangListPage({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<TukangListPage> createState() => _TukangListPageState();
}

class _TukangListPageState extends State<TukangListPage> {
  final ApiService _apiService = ApiService();
  List<Tukang> _tukangList = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTukang();
  }

  Future<void> _loadTukang() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiService.getTukangByCategory(widget.categoryId);
      final List<dynamic> data = response.data['data'] ?? [];
      setState(() {
        _tukangList = data.map((json) => Tukang.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memuat data: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: Text(widget.categoryName),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _loadTukang,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                        const SizedBox(height: 12),
                        Text(_errorMessage!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _loadTukang,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  )
                : _tukangList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.construction, size: 48, color: Colors.grey[300]),
                            const SizedBox(height: 12),
                            Text(
                              'Belum ada tukang untuk kategori ${widget.categoryName}',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: _tukangList.length,
                        itemBuilder: (context, index) =>
                            _buildTukangCard(_tukangList[index]),
                      ),
      ),
    );
  }

 Widget _buildTukangCard(Tukang tukang) {
  final firstService = tukang.services?.firstOrNull;
  final displayPrice = firstService?.priceRange ?? '-';
  
  // 🔥 HAPUS BAGIAN KOTA INI
  // if (tukang.kota != null) // ❌ HAPUS

  return GestureDetector(
    onTap: () => Navigator.pushNamed(
      context,
      '/tukang_detail',
      arguments: {'tukang': tukang},
    ),
    child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 10)
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
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.person,
                        size: 32,
                        color: Color(0xFF2563EB),
                      ),
                    ),
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
                    Expanded(
                      child: Text(
                        tukang.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: Color(0xFFFFB800)),
                        const SizedBox(width: 2),
                        Text('${tukang.rating}',
                            style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8), // 🔥 GANTI spacing
                // 🔥 HAPUS BAGIAN KOTA INI
                // if (tukang.kota != null)
                //   Row(...)
                
                // 🔥 TAMBAH KATEGORI SERVICE SEBAGAI PENGGANTI
                if (firstService?.categoryName != null)
                  Row(
                    children: [
                      Icon(Icons.work_outline, size: 12, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        firstService!.categoryName!,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                
                const SizedBox(height: 4),
                Text(
                  displayPrice,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => Navigator.pushNamed(
              context,
              '/create_order',
              arguments: {'tukang': tukang, 'service': firstService},
            ),
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
    ),
  );
}
}