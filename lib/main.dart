import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/user_provider.dart';
import 'providers/cart_provider.dart';
import 'screens/auth/login_screen.dart'; // Nó sẽ báo đỏ dòng này, đừng lo, bước sau sẽ hết

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()), // Quản lý User
        ChangeNotifierProvider(create: (_) => CartProvider()), // Quản lý Giỏ hàng
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Food Delivery',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange), // Màu chủ đạo Cam
        useMaterial3: true,
      ),
      // Màn hình đầu tiên là Đăng nhập
      home: const LoginScreen(),
    );
  }
}
