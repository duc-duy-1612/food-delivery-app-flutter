import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// Import các model và provider
import '../../models/order_model.dart';
import '../../services/api_service.dart';
import '../../providers/user_provider.dart';
import 'order_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<OrderModel>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<UserProvider>(context, listen: false).user;
    _ordersFuture = _apiService.getOrdersByUserId(user?.id ?? "");
  }

  Future<void> _refresh() async {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    setState(() {
      _ordersFuture = _apiService.getOrdersByUserId(user?.id ?? "");
    });
  }

  String formatCurrency(double price) {
    final format = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    return format.format(price);
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'Placed': return Colors.blue;
      case 'Preparing': return Colors.orange;
      case 'Shipping': return Colors.purple;
      case 'Completed': return Colors.green;
      case 'Cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  String getStatusText(String status) {
    switch (status) {
      case 'Placed': return "Đã đặt";
      case 'Preparing': return "Đang chuẩn bị";
      case 'Shipping': return "Đang giao";
      case 'Completed': return "Hoàn thành";
      case 'Cancelled': return "Đã hủy";
      default: return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Lịch Sử Đơn Hàng")),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<OrderModel>>(
          future: _ordersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text("Lỗi: ${snapshot.error}"));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text("Bạn chưa có đơn hàng nào."));
            }

            final orders = snapshot.data!;
            // Sắp xếp đơn mới nhất lên đầu
            orders.sort((a, b) => (b.createdAt).compareTo(a.createdAt));

            return ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(15),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Đơn #${order.id}", style: const TextStyle(fontWeight: FontWeight.bold)),
                        // Hiển thị trạng thái (Badge)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                              color: getStatusColor(order.status ?? "").withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10)
                          ),
                          child: Text(
                            getStatusText(order.status ?? ""),
                            style: TextStyle(
                                color: getStatusColor(order.status ?? ""),
                                fontSize: 12,
                                fontWeight: FontWeight.bold
                            ),
                          ),
                        )
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 5),
                        Text("Ngày: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(order.createdAt ?? DateTime.now().toString()))}"),
                        Text("Tổng tiền: ${formatCurrency(order.totalPrice ?? 0)}", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500)),
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () async {
                      // Chuyển sang màn hình chi tiết
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order)),
                      );
                      _refresh();
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
