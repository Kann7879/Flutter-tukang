import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../models/job.dart';
import '../widgets/main_bottom_navbar.dart';
import '../services/api_service.dart';

class TukangOrderPage extends StatefulWidget {
  const TukangOrderPage({super.key});

  @override
  State<TukangOrderPage> createState() => _TukangOrderPageState();
}

class _TukangOrderPageState extends State<TukangOrderPage>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 1;
  bool _isLoading = true;
  
  late TabController _tabController;
  final ApiService _apiService = ApiService();
  
  List<Job> _orderMasukList = [];
  List<Job> _pekerjaanAktifList = [];
  List<Job> _riwayatList = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadJobs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadJobs() async {
    try {
      final response = await _apiService.getMyJobs();
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? response.data;
        final jobs = data.map((job) => Job.fromJson(job)).toList();
        
        setState(() {
          // Separate jobs by status
          _orderMasukList = jobs.where((j) => 
              j.status == 'pending' || j.status == 'new').toList();
          
          _pekerjaanAktifList = jobs.where((j) => 
              j.status == 'diterima' || j.status == 'dikerjakan').toList();
          
          _riwayatList = jobs.where((j) => 
              j.status == 'selesai' || j.status == 'dibatalkan').toList();
          
          _isLoading = false;
        });
      }
    } catch (e) {
      print("❌ Error loading jobs: $e");
      setState(() => _isLoading = false);
    }
  }

  void _showAcceptJobDialog(String customerName, String service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terima Pekerjaan?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pelanggan: $customerName'),
            const SizedBox(height: 8),
            Text('Layanan: $service'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tolak'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Pesanan diterima! Silakan mulai bekerja.')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text(
              'Terima',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showCompleteJobDialog(String customerName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selesaikan Pekerjaan?'),
        content: Text('Tandai pekerjaan untuk $customerName sebagai selesai?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Pekerjaan ditandai selesai ✅')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text(
              'Selesaikan',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
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
        // Sudah di pesanan
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
      appBar: AppBar(
        title: const Text('Pesanan'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: [
            const Tab(
              icon: Icon(Icons.inbox),
              text: 'Order Masuk',
            ),
            const Tab(
              icon: Icon(Icons.build),
              text: 'Pekerjaan Aktif',
            ),
            const Tab(
              icon: Icon(Icons.history),
              text: 'Riwayat',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Order Masuk
                _buildOrderMasukTab(),
                // Tab 2: Pekerjaan Aktif
                _buildPekerjaanAktifTab(),
                // Tab 3: Riwayat
                _buildRiwayatTab(),
              ],
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

  Widget _buildOrderMasukTab() {
    return _orderMasukList.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text('Tidak ada pesanan baru',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14)),
              ],
            ),
          )
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _orderMasukList.length,
              itemBuilder: (context, index) {
                final job = _orderMasukList[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildIncomingOrderCard(
                    job: job,
                    onAccept: () => _showAcceptJobDialog(
                        job.customerName ?? 'Pelanggan', job.serviceName ?? 'Layanan'),
                  ),
                );
              },
            ),
          );
  }

  Widget _buildPekerjaanAktifTab() {
    return _pekerjaanAktifList.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.build_outlined, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text('Tidak ada pekerjaan aktif',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14)),
              ],
            ),
          )
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _pekerjaanAktifList.length,
              itemBuilder: (context, index) {
                final job = _pekerjaanAktifList[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildActiveJobCard(
                    job: job,
                    onComplete: () =>
                        _showCompleteJobDialog(job.customerName ?? 'Pelanggan'),
                  ),
                );
              },
            ),
          );
  }

  Widget _buildRiwayatTab() {
    return _riwayatList.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history_outlined, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text('Belum ada riwayat pekerjaan',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14)),
              ],
            ),
          )
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _riwayatList.length,
              itemBuilder: (context, index) {
                final job = _riwayatList[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildHistoryCard(
                    job: job,
                  ),
                );
              },
            ),
          );
  }

  Widget _buildIncomingOrderCard({
    required Job job,
    required VoidCallback onAccept,
  }) {
    final formatter = DateFormat('dd MMMM yyyy, HH:mm', 'id_ID');
    String formattedDate = formatter.format(job.createdAt);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.red.withOpacity(0.3), width: 2),
        borderRadius: BorderRadius.circular(12),
        color: Colors.red.withOpacity(0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  job.serviceName ?? 'Layanan',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'BARU',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Pelanggan: ${job.customerName ?? '-'}',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'Lokasi: ${job.alamat ?? '-'}',
            style: TextStyle(color: Colors.grey[700], fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            'Waktu: $formattedDate',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          const SizedBox(height: 12),
          Text(
            'Rp ${job.price.toString().replaceAllMapped(RegExp(r'\d(?=(?:\d{3})+$)'), (m) => '${m.group(0)}.')}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2563EB),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onAccept,
              icon: const Icon(Icons.check_circle),
              label: const Text('Terima Pesanan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveJobCard({
    required Job job,
    required VoidCallback onComplete,
  }) {
    final formatter = DateFormat('dd MMMM yyyy', 'id_ID');
    String formattedDate = formatter.format(job.createdAt);
    int progress = 50; // Default progress, can be from API if available
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.orange.withOpacity(0.5), width: 2),
        borderRadius: BorderRadius.circular(12),
        color: Colors.orange.withOpacity(0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                job.serviceName ?? 'Layanan',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'AKTIF',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Pelanggan: ${job.customerName ?? '-'}',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'Lokasi: ${job.alamat ?? '-'}',
            style: TextStyle(color: Colors.grey[700], fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            'Dimulai: $formattedDate',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          const SizedBox(height: 12),
          // Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Progress', style: TextStyle(fontSize: 12)),
                  Text('$progress%',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress / 100,
                  minHeight: 8,
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF2563EB)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onComplete,
              icon: const Icon(Icons.check),
              label: const Text('Selesaikan Pekerjaan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard({
    required Job job,
  }) {
    final formatter = DateFormat('dd MMMM yyyy', 'id_ID');
    String formattedDate = formatter.format(job.createdAt);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.green.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                job.serviceName ?? 'Layanan',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'SELESAI',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Pelanggan: ${job.customerName ?? '-'}',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'Selesai: $formattedDate',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          const SizedBox(height: 12),
          // Rating Stars
          if (job.rating != null) ...[
            Row(
              children: [
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < job.rating!.toInt() ? Icons.star : Icons.star_border,
                      color: const Color(0xFFFFB800),
                      size: 16,
                    );
                  }),
                ),
                const SizedBox(width: 8),
                Text(
                  '${job.rating}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          if (job.review != null && job.review!.isNotEmpty) ...[
            Text(
              'Review: "${job.review}"',
              style: TextStyle(color: Colors.grey[700], fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
          ],
          Text(
            'Rp ${job.price.toString().replaceAllMapped(RegExp(r'\d(?=(?:\d{3})+$)'), (m) => '${m.group(0)}.')}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2563EB),
            ),
          ),
        ],
      ),
    );
  }
}
