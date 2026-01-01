import 'package:flutter/material.dart';
import 'admin_order_screen.dart';
import 'admin_food_screen.dart';
import '../auth/login_screen.dart';
import 'admin_stats_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("TRANG QUẢN TRỊ (ADMIN)"),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white, // Chữ màu trắng cho nổi bật trên nền đỏ
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Đăng xuất thì về lại màn hình Login
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildAdminButton(context, "QUẢN LÝ ĐƠN HÀNG", Icons.list_alt, const AdminOrderScreen()),

            // Tăng khoảng cách lên 40 cho thoáng
            const SizedBox(height: 40),

            _buildAdminButton(context, "QUẢN LÝ THỰC ĐƠN", Icons.restaurant_menu, const AdminFoodScreen()),

            // Tăng khoảng cách lên 40 cho thoáng
            const SizedBox(height: 40),

            _buildAdminButton(context, "THỐNG KÊ & BÁO CÁO", Icons.bar_chart, const AdminStatsScreen()),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminButton(BuildContext context, String title, IconData icon, Widget page) {
    return SizedBox(
      width: 280, // Tăng chiều rộng một chút cho đẹp
      height: 65, // Tăng chiều cao một chút
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueGrey,
            foregroundColor: Colors.white,
            elevation: 5, // Thêm đổ bóng
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)) // Bo tròn góc
        ),
        icon: Icon(icon, size: 30),
        label: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => page));
        },
      ),
    );
  }
}
