import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/order_model.dart';
import '../../services/api_service.dart'; // THÊM import này để gọi API

class OrderDetailScreen extends StatefulWidget {
  final OrderModel order;
  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late OrderModel _currentOrder;
  final ApiService _apiService = ApiService(); // Khởi tạo ApiService
  bool _isCancelling = false; // Biến để kiểm soát trạng thái loading của nút hủy

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
  }

  // HÀM MỚI: Xử lý hủy đơn
  Future<void> _cancelOrder() async {
    // Hiển thị dialog xác nhận
    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xác nhận Hủy Đơn"),
        content: const Text("Bạn có chắc chắn muốn hủy đơn hàng này không?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text("Không"),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text("Hủy Đơn", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isCancelling = true);

    // Gọi API để cập nhật trạng thái
    bool success = await _apiService.updateOrderStatus(_currentOrder.id!, 'Canceled');

    setState(() => _isCancelling = false);

    if (success) {
      // Cập nhật lại trạng thái trên giao diện
      setState(() {
        _currentOrder = OrderModel(
          id: _currentOrder.id,
          userId: _currentOrder.userId,
          userName: _currentOrder.userName,
          totalPrice: _currentOrder.totalPrice,
          status: 'Canceled',
          address: _currentOrder.address,
          createdAt: _currentOrder.createdAt,
          items: _currentOrder.items,
          userEmail: _currentOrder.userEmail,
          userPhone: _currentOrder.userPhone,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đã hủy đơn hàng thành công.")),
      );
    }

  }


  String formatCurrency(dynamic price) {
    if (price == null) return "0 đ";
    double realPrice = double.tryParse(price.toString()) ?? 0.0;
    final format = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    return format.format(realPrice);
  }

  Map<String, dynamic> getStatusInfo(String status) {
    switch (status) {
      case 'Placed':
        return {'text': 'Đã đặt hàng', 'color': Colors.blue};
      case 'Preparing':
        return {'text': 'Đang chuẩn bị', 'color': Colors.orange};
      case 'Shipping':
        return {'text': 'Đang giao hàng', 'color': Colors.purple};
      case 'Completed':
        return {'text': 'Đã hoàn thành', 'color': Colors.green};
      case 'Canceled':
        return {'text': 'Đã hủy', 'color': Colors.red};
      default:
        return {'text': status, 'color': Colors.grey};
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusInfo = getStatusInfo(_currentOrder.status ?? "");
    final items = _currentOrder.items ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text("Chi tiết đơn hàng")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ... (Các phần hiển thị thông tin cũ giữ nguyên)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Mã đơn: #${_currentOrder.id}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 5),
            Text("Ngày đặt: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(_currentOrder.createdAt ?? DateTime.now().toString()))}"),
            const Divider(height: 30),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (statusInfo['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: statusInfo['color']),
              ),
              child: Row(
                children: [
                  Icon(Icons.local_shipping, color: statusInfo['color'], size: 40),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Trạng thái hiện tại:", style: TextStyle(color: Colors.black54)),
                      Text(
                        statusInfo['text'],
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: statusInfo['color']),
                      ),
                    ],
                  )
                ],
              ),
            ),

            const SizedBox(height: 20),

            const Text("Danh sách món:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...items.map((item) {
              final itemMap = item as Map<String, dynamic>;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 4)]),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: Image.network(
                          itemMap['image'] ?? "", width: 50, height: 50, fit: BoxFit.cover,
                          errorBuilder: (_,__,___)=>const Icon(Icons.fastfood, color: Colors.grey)
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(itemMap['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text("x${itemMap['quantity']}"),
                        ],
                      ),
                    ),
                    Text(formatCurrency((itemMap['price'] ?? 0) * (itemMap['quantity'] ?? 1)), style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            }).toList(),

            const Divider(height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Tổng tiền:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(formatCurrency(_currentOrder.totalPrice ?? 0), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red)),
              ],
            ),

            const SizedBox(height: 20),

            const Text("Địa chỉ nhận hàng:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.red),
                  const SizedBox(width: 10),
                  Expanded(child: Text(_currentOrder.address ?? "Chưa có địa chỉ", style: const TextStyle(fontSize: 15))),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // --- THÊM PHẦN NÀY VÀO ---
            // Chỉ hiển thị nút hủy khi đơn hàng ở trạng thái "Placed"
            if (_currentOrder.status == 'Placed')
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.cancel_schedule_send),
                  label: const Text("HỦY ĐƠN HÀNG"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                  onPressed: _isCancelling ? null : _cancelOrder,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
