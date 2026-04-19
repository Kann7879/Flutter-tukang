import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/main_bottom_navbar.dart';

class CustomerChatPage extends StatefulWidget {
  const CustomerChatPage({super.key});

  @override
  State<CustomerChatPage> createState() => _CustomerChatPageState();
}

class _CustomerChatPageState extends State<CustomerChatPage> {
  int _selectedIndex = 2;

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
        // Sudah di chat
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
        title: const Text('Chat Tukang'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.chat,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'Tidak ada chat',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Anda belum memiliki percakapan aktif',
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
