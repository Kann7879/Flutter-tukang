import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/main_bottom_navbar.dart';

class TukangHistoryPage extends StatefulWidget {
  const TukangHistoryPage({super.key});

  @override
  State<TukangHistoryPage> createState() => _TukangHistoryPageState();
}

class _TukangHistoryPageState extends State<TukangHistoryPage> {
  int _selectedIndex = 1;

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
        // Sudah di history
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
        title: const Text('Histori Pekerjaan'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.history,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'Histori kosong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Anda belum memiliki riwayat pekerjaan',
              style: TextStyle(color: Colors.grey[500]),
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
}
