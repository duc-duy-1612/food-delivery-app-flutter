import 'package:flutter/material.dart';
import 'admin_order_screen.dart';
import 'admin_food_screen.dart';
import 'admin_stats_screen.dart';
import 'admin_customer_screen.dart';
import '../auth/login_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selectedIndex = 0;

  // 2. Cập nhật danh sách màn hình (Thêm AdminCustomerScreen vào vị trí thứ 2)
  static final List<Widget> _widgetOptions = <Widget>[
    const AdminOrderScreen(),
    const AdminFoodScreen(),
    const AdminCustomerScreen(),
    const AdminStatsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Body hiển thị màn hình tương ứng
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),

      // Thanh điều hướng dưới đáy
      bottomNavigationBar: NavigationBar(
        height: 65,
        elevation: 5,
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        backgroundColor: Colors.white,
        indicatorColor: Colors.redAccent.withOpacity(0.2),
        // 3. Cập nhật danh sách nút bấm (Thêm nút Khách hàng)
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt, color: Colors.redAccent),
            label: 'Đơn Hàng',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_menu_outlined),
            selectedIcon: Icon(Icons.restaurant_menu, color: Colors.redAccent),
            label: 'Thực Đơn',
          ),
          // --- THÊM MỚI ---
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people, color: Colors.redAccent),
            label: 'Khách Hàng',
          ),

          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart, color: Colors.redAccent),
            label: 'Thống Kê',
          ),
        ],
      ),
    );
  }
}
