import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/order_model.dart';
import '../../services/api_service.dart';
import '../../screens/auth/login_screen.dart';

class AdminStatsScreen extends StatefulWidget {
  const AdminStatsScreen({super.key});

  @override
  State<AdminStatsScreen> createState() => _AdminStatsScreenState();
}

class _AdminStatsScreenState extends State<AdminStatsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;

  // Dữ liệu thống kê
  double _filteredRevenue = 0;
  int _filteredOrdersCount = 0;
  double _revenueToday = 0;
  List<Map<String, dynamic>> _topProducts = [];

  // Dữ liệu biểu đồ 7 ngày
  List<BarChartGroupData> _chartData = [];
  double _maxWeeklyRevenue = 0;
  List<String> _weekDays = []; // Bước 1: Khai báo biến cấp độ Class

  // Bộ lọc
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _calculateStats();
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _calculateStats() async {
    setState(() => _isLoading = true);

    final orders = await _apiService.getAllOrders();
    final now = DateTime.now();

    double revFiltered = 0;
    int countFiltered = 0;
    double revToday = 0;
    Map<String, int> productCount = {};

    // QUAN TRỌNG: Khởi tạo mảng dữ liệu 7 ngày với giá trị 0
    List<double> weeklyData = List.filled(7, 0.0);
    List<String> localWeekDays = [];

    // Bước 2: Tạo danh sách các thứ trong tuần (Mon, Tue...)
    for (int i = 6; i >= 0; i--) {
      localWeekDays.add(DateFormat('E').format(now.subtract(Duration(days: i))));
    }

    for (var order in orders) {
      if (order.status != 'Completed') continue;

      DateTime? orderDate = DateTime.tryParse(order.createdAt);
      if (orderDate == null) continue;

      double price = order.totalPrice ?? 0;

      if (isSameDay(orderDate, now)) {
        revToday += price;
      }

      bool matchFilter = false;
      switch (_selectedFilter) {
        case 'Today':
          matchFilter = isSameDay(orderDate, now);
          break;
        case 'Week':
          matchFilter = now.difference(orderDate).inDays < 7;
          break;
        case 'Month':
          matchFilter = orderDate.month == now.month && orderDate.year == now.year;
          break;
        case 'All':
          matchFilter = true;
          break;
      }

      if (matchFilter) {
        revFiltered += price;
        countFiltered++;
        // Kiểm tra items không null trước khi lặp
        final itemsList = order.items ?? []; // Ép kiểu về non-nullable
        for (var item in itemsList) {
          final i = item as Map<String, dynamic>;
          String name = i['name'] ?? 'Không tên';
          int qty = i['quantity'] ?? 0;
          productCount[name] = (productCount[name] ?? 0) + qty;
        }
      }

      // Tính toán dữ liệu biểu đồ (7 ngày gần nhất)
      // Dùng thời gian 0h00 để tính khoảng cách ngày chính xác
      DateTime startOfToday = DateTime(now.year, now.month, now.day);
      DateTime startOfOrder = DateTime(orderDate.year, orderDate.month, orderDate.day);
      int dayDiff = startOfToday.difference(startOfOrder).inDays;

      if (dayDiff >= 0 && dayDiff < 7) {
        int chartIndex = 6 - dayDiff;
        weeklyData[chartIndex] += price;
      }
    }

    // Xử lý top sản phẩm
    List<Map<String, dynamic>> sortedProducts = [];
    productCount.forEach((key, value) {
      sortedProducts.add({'name': key, 'count': value});
    });
    sortedProducts.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

    // Tạo các cột cho BarChart
    List<BarChartGroupData> chartBars = [];
    for (int i = 0; i < weeklyData.length; i++) {
      chartBars.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: weeklyData[i],
              color: Colors.amber,
              width: 16,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            )
          ],
        ),
      );
    }

    double maxRev = weeklyData.reduce((a, b) => a > b ? a : b);

    if (mounted) {
      setState(() {
        _revenueToday = revToday;
        _filteredRevenue = revFiltered;
        _filteredOrdersCount = countFiltered;
        _topProducts = sortedProducts.take(5).toList();
        _chartData = chartBars;
        _weekDays = localWeekDays; // Cập nhật danh sách ngày
        _maxWeeklyRevenue = maxRev == 0 ? 100000 : maxRev * 1.2;
        _isLoading = false;
      });
    }
  }

  String formatCurrency(double price) {
    return NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(price);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Thống Kê & Báo Cáo"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          )
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Xem theo:", style: TextStyle(fontWeight: FontWeight.bold)),
                DropdownButton<String>(
                  value: _selectedFilter,
                  items: const [
                    DropdownMenuItem(value: 'Today', child: Text('Hôm nay')),
                    DropdownMenuItem(value: 'Week', child: Text('Tuần này')),
                    DropdownMenuItem(value: 'Month', child: Text('Tháng này')),
                    DropdownMenuItem(value: 'All', child: Text('Tất cả')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedFilter = value);
                      _calculateStats();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _calculateStats,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: Colors.green,
                elevation: 4,
                child: ListTile(
                  leading: const Icon(Icons.today, color: Colors.white),
                  title: const Text('Doanh thu hôm nay', style: TextStyle(color: Colors.white)),
                  trailing: Text(formatCurrency(_revenueToday),
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
              Text("Tổng quan ($_selectedFilter)", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              _buildStatCard(formatCurrency(_filteredRevenue), "$_filteredOrdersCount đơn hàng thành công", Colors.blue, Icons.receipt_long),
              const SizedBox(height: 25),
              const Text("Biểu đồ doanh thu 7 ngày", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              Container(
                height: 250,
                padding: const EdgeInsets.only(top: 20, right: 20, left: 10, bottom: 10),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, spreadRadius: 2)]),
                child: BarChart(
                  BarChartData(
                    maxY: _maxWeeklyRevenue,
                    barGroups: _chartData,
                    titlesData: FlTitlesData(
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            // Bước 3: Sửa lỗi hiển thị tiêu đề ngày
                            int index = value.toInt();
                            if (index >= 0 && index < _weekDays.length) {
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                child: Text(_weekDays[index], style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                              );
                            }
                            return const SizedBox();
                          },
                          reservedSize: 30,
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: const FlGridData(show: true, drawVerticalLine: false),
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        // Thay vì getTooltipColor, hãy dùng tooltipBgColor (cho bản cũ)
                        // hoặc tooltipColor (cho bản mới nhất)
                        tooltipRoundedRadius: 8,
                        tooltipPadding: const EdgeInsets.all(8),
                        tooltipMargin: 8,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            '${_weekDays[groupIndex]}\n',
                            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            children: [
                              TextSpan(
                                text: formatCurrency(rod.toY),
                                style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.w500),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 25),
              Text("Top 5 món bán chạy ($_selectedFilter)", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              if (_topProducts.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: Text("Chưa có dữ liệu giao dịch thành công.")),
                )
              else
                Card(
                  child: Column(
                    children: _topProducts.map((p) => ListTile(
                      leading: const CircleAvatar(backgroundColor: Colors.orangeAccent, child: Icon(Icons.star, color: Colors.white, size: 18)),
                      title: Text(p['name'], style: const TextStyle(fontWeight: FontWeight.w600)),
                      trailing: Text("${p['count']} phần", style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                    )).toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String subtitle, Color color, IconData icon) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 30, color: color),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}