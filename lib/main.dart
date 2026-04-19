import 'package:flutter/material.dart';
import 'pages/login_page.dart';
import 'pages/dashboard_customer.dart';
import 'pages/dashboard_tukang.dart';
import 'pages/customer_order_page.dart';
import 'pages/customer_chat_page.dart';
import 'pages/customer_profile_page.dart';
import 'pages/tukang_order_page.dart';
import 'pages/tukang_chat_page.dart';
import 'pages/tukang_profile_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // 🔥 HALAMAN AWAL
      initialRoute: '/',

      // 🔥 DAFTAR ROUTE
      routes: {
        '/': (context) => const LoginPage(),
        '/dashboard_customer': (context) => const DashboardCustomerPage(),
        '/dashboard_tukang': (context) => const DashboardTukangPage(),
        '/customer_order': (context) => const CustomerOrderPage(),
        '/customer_chat': (context) => const CustomerChatPage(),
        '/customer_profile': (context) => const CustomerProfilePage(),
        '/tukang_order': (context) => const TukangOrderPage(),
        '/tukang_chat': (context) => const TukangChatPage(),
        '/tukang_profile': (context) => const TukangProfilePage(),
      },
    );
  }
}