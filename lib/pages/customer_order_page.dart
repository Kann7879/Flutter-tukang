import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/main_bottom_navbar.dart';
import '../services/api_service.dart';
import '../models/job.dart';
import 'package:intl/intl.dart';

class CustomerOrderPage extends StatefulWidget {
  const CustomerOrderPage({super.key});

  @override
  State<CustomerOrderPage> createState() => _CustomerOrderPageState();
}

class _CustomerOrderPageState extends State<CustomerOrderPage> {
  int _selectedIndex = 1;
  bool _isLoading = true;
  
  final ApiService _apiService = ApiService();
  List<Job> _activeJobs = [];
  List<Job> _completedJobs = [];

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    try {
      final response = await _apiService.getMyJobs();
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? response.data;
        final jobs = data.map((job) => Job.fromJson(job)).toList();
        
        setState(() {
          _activeJobs = jobs.where((j) => j.status != 'selesai' && j.status != 'dibatalkan').toList();
          _completedJobs = jobs.where((j) => j.status == 'selesai' || j.status == 'dibatalkan').toList();
          _isLoading = false;
        });
        print("✅ Jobs loaded: ${jobs.length}");
      }
    } catch (e) {
      print("❌ Error loading jobs: $e");
      setState(() => _isLoading = false);
      _showErrorSnackBar("Gagal memuat pekerjaan: $e");
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

  void _showRatingDialog(int jobId, String tukangName) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          double _rating = 5.0;
          final TextEditingController _reviewController =
              TextEditingController();

          return AlertDialog(
            title: Text('Rating untuk $tukangName'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                      'Berapa rating Anda untuk pekerjaan ini?',
                      style: TextStyle(
                          color: Colors.grey[600], fontSize: 13)),
                  const SizedBox(height: 16),
                  // Rating Stars - Interactive
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () {
                          setState(
                              () => _rating = (index + 1).toDouble());
                        },
                        child: Icon(
                          index < _rating
                              ? Icons.star
                              : Icons.star_border,
                          color: const Color(0xFFFFB800),
                          size: 36,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_rating.toInt()} dari 5 bintang',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFB800),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Review Text
                  TextField(
                    controller: _reviewController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Tulis review Anda (opsional)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await _apiService.rateJob(
                      jobId: jobId,
                      rating: _rating,
                      review: _reviewController.text,
                    );
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Rating berhasil dikirim ✅')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                ),
                child: const Text(
                  'Kirim Rating',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
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
        title: const Text('Pesanan Saya'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pesanan Aktif
                  Text(
                    'Pesanan Sedang Berjalan',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2563EB),
                        ),
                  ),
                  const SizedBox(height: 12),
                  _activeJobs.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Text(
                              'Tidak ada pesanan aktif',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _activeJobs.length,
                          itemBuilder: (context, index) {
                            final job = _activeJobs[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildJobCardFromData(
                                job: job,
                                onRate: () => _showRatingDialog(
                                    job.id, job.tukangName ?? 'Tukang'),
                                onRepeat: () => print('Repeat Job'),
                              ),
                            );
                          },
                        ),
                  const SizedBox(height: 24),

                  // Riwayat Transaksi
                  Text(
                    'Riwayat Transaksi',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2563EB),
                        ),
                  ),
                  const SizedBox(height: 12),
                  _completedJobs.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Text(
                              'Tidak ada riwayat transaksi',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _completedJobs.length,
                          itemBuilder: (context, index) {
                            final job = _completedJobs[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildJobCardFromData(
                                job: job,
                                onRate: () => _showRatingDialog(
                                    job.id, job.tukangName ?? 'Tukang'),
                                onRepeat: () => print('Repeat Job'),
                              ),
                            );
                          },
                        ),
                  const SizedBox(height: 20),
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

  Widget _buildJobCardFromData({
    required Job job,
    required VoidCallback onRate,
    required VoidCallback onRepeat,
  }) {
    Color statusColor = (job.status == 'selesai' || job.status == 'dibatalkan')
        ? Colors.green
        : Colors.orange;
    
    Map<String, String> statusMap = {
      'pending': 'PENDING',
      'diterima': 'DITERIMA',
      'dikerjakan': 'DIKERJAKAN',
      'selesai': 'SELESAI',
      'dibatalkan': 'DIBATALKAN',
    };
    String statusDisplay = statusMap[job.status] ?? job.status.toUpperCase();
    
    final formatter = DateFormat('dd MMMM yyyy', 'id_ID');
    String formattedDate = formatter.format(job.createdAt);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
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
                overflow: TextOverflow.ellipsis,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusDisplay,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Tukang: ${job.tukangName ?? '-'}',
            style: TextStyle(color: Colors.grey[700]),
          ),
          const SizedBox(height: 8),
          Text(
            'Tanggal: $formattedDate',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            'Lokasi: ${job.alamat ?? '-'}',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
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
          if (job.rating != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Row(
                  children: List.generate(
                      5,
                      (index) => Icon(
                            index < job.rating!.toInt()
                                ? Icons.star
                                : Icons.star_border,
                            color: const Color(0xFFFFB800),
                            size: 14,
                          )),
                ),
                const SizedBox(width: 8),
                Text(
                  '${job.rating}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onRate,
                  icon: const Icon(Icons.star_outline, size: 18),
                  label: const Text('Rating'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onRepeat,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Repeat Order'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF2563EB)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard({
    required String status,
    required String tukangName,
    required String service,
    required String date,
    required String price,
    required VoidCallback onRate,
    required VoidCallback onRepeat,
  }) {
    Color statusColor = status == 'Selesai' ? Colors.green : Colors.orange;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                service,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Tukang: $tukangName',
            style: TextStyle(color: Colors.grey[700]),
          ),
          const SizedBox(height: 8),
          Text(
            'Tanggal: $date',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          const SizedBox(height: 12),
          Text(
            price,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2563EB),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onRate,
                  icon: const Icon(Icons.star_outline, size: 18),
                  label: const Text('Rating'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onRepeat,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Repeat Order'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF2563EB)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
