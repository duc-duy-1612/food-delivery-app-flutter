import 'dart:convert'; // Import thư viện này
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/order_model.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';

class AdminOrderDetailScreen extends StatefulWidget {
  final OrderModel order;

  const AdminOrderDetailScreen({super.key, required this.order});

  @override
  State<AdminOrderDetailScreen> createState() => _AdminOrderDetailScreenState();
}

class _AdminOrderDetailScreenState extends State<AdminOrderDetailScreen> {
  final ApiService _apiService = ApiService();
  UserModel? _customerInfo;
  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _loadCustomerInfo();
  }

  Future<void> _loadCustomerInfo() async {
    if (widget.order.userId != null && widget.order.userId!.isNotEmpty) {
      final user = await _apiService.getUserById(widget.order.userId!);
      if (mounted) {
        setState(() {
          _customerInfo = user;
          _isLoadingUser = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isLoadingUser = false);
      }
    }
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

  String getStatusText(String status) {
    switch (status) {
      case 'Placed': return "Đã đặt hàng";
      case 'Preparing': return "Đang chuẩn bị";
      case 'Shipping': return "Đang giao hàng";
      case 'Completed': return "Đã hoàn thành";
      case 'Canceled': return "Đã hủy";
      default: return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.order.items ?? [];
    final statusColor = getStatusColor(widget.order.status ?? "");

    return Scaffold(
      appBar: AppBar(
        // Hiển thị 5 số cuối của ID cho gọn
        title: Text("Chi Tiết Đơn #${widget.order.id != null && widget.order.id!.length > 5 ? widget.order.id!.substring(widget.order.id!.length - 5) : widget.order.id}"),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. TRẠNG THÁI ĐƠN HÀNG
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                border: Border.all(color: statusColor, width: 2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Text(
                    "TRẠNG THÁI HIỆN TẠI",
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    getStatusText(widget.order.status ?? ""),
                    style: TextStyle(color: statusColor, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 2. THÔNG TIN KHÁCH HÀNG
            const Text("Thông tin khách hàng", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _isLoadingUser
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                  children: [
                    _buildInfoRow(Icons.person, "Họ tên", _customerInfo?.name ?? "Khách vãng lai (${widget.order.userId})"),
                    const Divider(),
                    _buildInfoRow(Icons.phone, "Điện thoại", _customerInfo?.phone ?? "Không có SĐT"),
                    const Divider(),
                    _buildInfoRow(Icons.email, "Email", _customerInfo?.email ?? "Không có Email"),
                    const Divider(),
                    _buildInfoRow(Icons.calendar_today, "Ngày đặt",
                        DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(widget.order.createdAt ?? DateTime.now().toString()))),
                    const Divider(),
                    _buildInfoRow(Icons.location_on, "Địa chỉ nhận", widget.order.address ?? "Không có địa chỉ"),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 3. DANH SÁCH MÓN ĂN (CẬP NHẬT HIỂN THỊ NOTE)
            const Text("Danh sách món đã đặt", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index] as Map<String, dynamic>;
                final bool hasNote = item['note'] != null && item['note'].toString().trim().isNotEmpty;

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: Image.network(
                          item['image'] ?? "",
                          width: 50, height: 50, fit: BoxFit.cover,
                          errorBuilder: (_,__,___) => const Icon(Icons.fastfood),
                        ),
                      ),
                      title: Text(item['name'] ?? "Món ăn", style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Số lượng: ${item['quantity']}"),

                          // --- THÊM PHẦN HIỂN THỊ GHI CHÚ VÀO ĐÂY ---
                          if (hasNote)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.amber.shade200),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.edit_note, size: 16, color: Colors.deepOrange),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      "Ghi chú: ${item['note']}",
                                      style: const TextStyle(
                                        color: Colors.deepOrange,
                                        fontStyle: FontStyle.italic,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          // ------------------------------------
                        ],
                      ),
                      trailing: Text(
                        formatCurrency((item['price'] ?? 0) * (item['quantity'] ?? 1)),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                    ),
                  ),
                );
              },
            ),

            const Divider(height: 30),

            // 4. TỔNG TIỀN
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("TỔNG DOANH THU:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(
                  formatCurrency(widget.order.totalPrice ?? 0),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 10),
        SizedBox(width: 80, child: Text(label, style: const TextStyle(color: Colors.grey))),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
      ],
    );
  }
}
