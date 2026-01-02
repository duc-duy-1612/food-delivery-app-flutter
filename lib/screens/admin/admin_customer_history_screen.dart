import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../models/order_model.dart';
import '../../services/api_service.dart';
import 'admin_order_detail_screen.dart';

class AdminCustomerHistoryScreen extends StatefulWidget {
  final UserModel user;
  const AdminCustomerHistoryScreen({super.key, required this.user});

  @override
  State<AdminCustomerHistoryScreen> createState() => _AdminCustomerHistoryScreenState();
}

class _AdminCustomerHistoryScreenState extends State<AdminCustomerHistoryScreen> {
  final ApiService _apiService = ApiService();
  List<OrderModel> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserOrders();
  }

  Future<void> _loadUserOrders() async {
    // Tận dụng hàm getOrdersByUserId có sẵn
    final data = await _apiService.getOrdersByUserId(widget.user.id!);
    setState(() {
      _orders = data;
      _isLoading = false;
    });
  }

  String formatCurrency(dynamic price) {
    if (price == null) return "0 đ";
    double realPrice = double.tryParse(price.toString()) ?? 0.0;
    final format = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    return format.format(realPrice);
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'Placed': return Colors.blue;
      case 'Preparing': return Colors.orange;
      case 'Shipping': return Colors.purple;
      case 'Completed': return Colors.green;
      case 'Canceled': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lịch sử: ${widget.user.name}"),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Thông tin tóm tắt khách hàng
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blueGrey.withOpacity(0.1),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage(widget.user.avatar ?? "https://i.pravatar.cc/150?img=3"),
                  onBackgroundImageError: (_,__) {},
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.user.name ?? "Không tên", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text("SĐT: ${widget.user.phone}"),
                      Text("Địa chỉ: ${widget.user.address}", maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                )
              ],
            ),
          ),
          const Divider(height: 1),

          // Danh sách đơn hàng
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _orders.isEmpty
                ? const Center(child: Text("Khách hàng này chưa có đơn nào."))
                : ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: _orders.length,
              itemBuilder: (context, index) {
                final order = _orders[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Đơn #${order.id}", style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                            order.status ?? "",
                            style: TextStyle(color: getStatusColor(order.status ?? ""), fontWeight: FontWeight.bold, fontSize: 12)
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Ngày: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(order.createdAt!))}"),
                        Text("Tổng: ${formatCurrency(order.totalPrice)}", style: const TextStyle(color: Colors.red)),
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () {
                      // Xem chi tiết đơn hàng
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AdminOrderDetailScreen(order: order)),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
