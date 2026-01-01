import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/order_model.dart';
import '../../services/api_service.dart';

class AdminStatsScreen extends StatefulWidget {
  const AdminStatsScreen({super.key});

  @override
  State<AdminStatsScreen> createState() => _AdminStatsScreenState();
}

class _AdminStatsScreenState extends State<AdminStatsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;

  double _totalRevenue = 0;
  int _totalOrders = 0;
  int _completedOrders = 0;
  List<Map<String, dynamic>> _topProducts = []; // {name, count}

  @override
  void initState() {
    super.initState();
    _calculateStats();
  }

  Future<void> _calculateStats() async {
    final orders = await _apiService.getAllOrders();

    double revenue = 0;
    int completed = 0;
    Map<String, int> productCount = {}; // Đếm số lượng từng món

    for (var order in orders) {
      // Chỉ tính đơn đã hoàn thành
      if (order.status == 'Completed') {
        revenue += order.totalPrice ?? 0;
        completed++;

        // Đếm món ăn
        if (order.items != null) {
          for (var item in order.items!) {
            final i = item as Map<String, dynamic>;
            String name = i['name'];
            int qty = i['quantity'];

            if (productCount.containsKey(name)) {
              productCount[name] = productCount[name]! + qty;
            } else {
              productCount[name] = qty;
            }
          }
        }
      }
    }

    // Sắp xếp top món ăn
    List<Map<String, dynamic>> sortedProducts = [];
    productCount.forEach((key, value) {
      sortedProducts.add({'name': key, 'count': value});
    });
    sortedProducts.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int)); // Giảm dần

    setState(() {
      _totalRevenue = revenue;
      _totalOrders = orders.length;
      _completedOrders = completed;
      _topProducts = sortedProducts.take(5).toList(); // Lấy top 5
      _isLoading = false;
    });
  }

  String formatCurrency(double price) {
    final format = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    return format.format(price);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Thống Kê Doanh Thu")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thẻ tổng quan
            _buildStatCard("TỔNG DOANH THU", formatCurrency(_totalRevenue), Colors.green, Icons.attach_money),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(child: _buildStatCard("Tổng đơn", "$_totalOrders", Colors.blue, Icons.list)),
                const SizedBox(width: 15),
                Expanded(child: _buildStatCard("Hoàn thành", "$_completedOrders", Colors.orange, Icons.check_circle)),
              ],
            ),

            const SizedBox(height: 30),
            const Text("🏆 TOP MÓN BÁN CHẠY", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            // Danh sách top món
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 5)]),
              child: Column(
                children: _topProducts.map((p) => ListTile(
                  leading: const Icon(Icons.emoji_events, color: Colors.amber),
                  title: Text(p['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: Text("${p['count']} đã bán", style: const TextStyle(color: Colors.grey)),
                )).toList(),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))]
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 30),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 5),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
