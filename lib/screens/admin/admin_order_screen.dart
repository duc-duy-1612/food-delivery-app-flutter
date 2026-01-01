import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/order_model.dart';
import '../../services/api_service.dart';
import 'admin_order_detail_screen.dart';

class AdminOrderScreen extends StatefulWidget {
  const AdminOrderScreen({super.key});

  @override
  State<AdminOrderScreen> createState() => _AdminOrderScreenState();
}

class _AdminOrderScreenState extends State<AdminOrderScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();

  List<OrderModel> _allOrders = []; // Danh sách gốc
  List<OrderModel> _displayOrders = []; // Danh sách hiển thị (sau khi lọc/tìm)

  bool _isLoading = true;
  String _searchKeyword = "";
  late TabController _tabController;

  final List<String> _tabs = ["All", "Placed", "Preparing", "Shipping", "Completed", "Canceled"];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_filterOrders);
    _loadAllOrders();
  }

  Future<void> _loadAllOrders() async {
    setState(() => _isLoading = true);
    final data = await _apiService.getAllOrders();
    setState(() {
      _allOrders = data;
      _isLoading = false;
    });
    _filterOrders(); // Lọc ngay lần đầu
  }

  // Hàm lọc dữ liệu theo Tab và Từ khóa tìm kiếm
  void _filterOrders() {
    String currentTab = _tabs[_tabController.index];

    setState(() {
      _displayOrders = _allOrders.where((order) {
        // 1. Lọc theo Tab Status
        bool statusMatch = (currentTab == "All") || (order.status == currentTab);

        // 2. Lọc theo Search (Tìm ID hoặc SĐT - SĐT nằm trong userId do ta lưu tạm)
        bool searchMatch = true;
        if (_searchKeyword.isNotEmpty) {
          String id = order.id?.toLowerCase() ?? "";
          String user = order.userId?.toLowerCase() ?? "";
          String address = order.address?.toLowerCase() ?? "";
          String kw = _searchKeyword.toLowerCase();
          searchMatch = id.contains(kw) || user.contains(kw) || address.contains(kw);
        }

        return statusMatch && searchMatch;
      }).toList();
    });
  }

  void _updateStatus(OrderModel order, String newStatus) async {
    bool success = await _apiService.updateOrderStatus(order.id!, newStatus);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Đơn #${order.id}: Đã chuyển sang $newStatus")));
      _loadAllOrders(); // Tải lại để cập nhật giao diện
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quản Lý Đơn Hàng"),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: Column(
        children: [
          // Thanh tìm kiếm
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: "Tìm kiếm (Mã đơn, Địa chỉ...)",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 10),
              ),
              onChanged: (value) {
                _searchKeyword = value;
                _filterOrders();
              },
            ),
          ),

          // Danh sách đơn hàng
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _displayOrders.isEmpty
                ? const Center(child: Text("Không tìm thấy đơn hàng nào"))
                : ListView.builder(
              itemCount: _displayOrders.length,
              itemBuilder: (context, index) {
                final order = _displayOrders[index];
                return _buildOrderItem(order);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(OrderModel order) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      elevation: 3,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        leading: CircleAvatar(
          backgroundColor: getStatusColor(order.status ?? ""),
          child: const Icon(Icons.receipt, color: Colors.white, size: 20),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Đơn #${order.id}", style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(formatCurrency(order.totalPrice ?? 0), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Ngày: ${DateFormat('dd/MM HH:mm').format(DateTime.parse(order.createdAt!))}"),
            Text("Khách: ${order.address}", maxLines: 1, overflow: TextOverflow.ellipsis),
            Text("Trạng thái: ${order.status}", style: TextStyle(color: getStatusColor(order.status!), fontWeight: FontWeight.bold)),
          ],
        ),
        children: [
          ListTile(
            leading: const Icon(Icons.info_outline, color: Colors.blue),
            title: const Text("Xem chi tiết đầy đủ (Khách & Món ăn)", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AdminOrderDetailScreen(order: order)),
              );
            },
          ),
          const Divider(),
          // Chi tiết món ăn
          if (order.items != null)
            ...order.items!.map((item) {
              final i = item as Map<String, dynamic>;
              return ListTile(
                contentPadding: const EdgeInsets.only(left: 20, right: 20),
                title: Text(i['name']),
                // Ép kiểu sang double trước khi nhân để tránh lỗi
                trailing: Text(
                  "x${i['quantity']}  ${formatCurrency(
                      ((i['price'] ?? 0).toDouble()) * ((i['quantity'] ?? 1).toDouble())
                  )}",
                ),
                dense: true,
              );
            }).toList(),

          const Divider(),
          // Nút hành động (Action Buttons)
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Wrap(
              spacing: 10,
              alignment: WrapAlignment.end,
              children: [
                // Logic hiển thị nút theo quy trình
                if (order.status == 'Placed')
                  ElevatedButton.icon(
                    icon: const Icon(Icons.soup_kitchen, size: 16),
                    label: const Text("Xác nhận nấu"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                    onPressed: () => _updateStatus(order, 'Preparing'),
                  ),
                if (order.status == 'Preparing')
                  ElevatedButton.icon(
                    icon: const Icon(Icons.delivery_dining, size: 16),
                    label: const Text("Giao Shipper"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
                    onPressed: () => _updateStatus(order, 'Shipping'),
                  ),
                if (order.status == 'Shipping')
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle, size: 16),
                    label: const Text("Đã giao xong"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    onPressed: () => _updateStatus(order, 'Completed'),
                  ),
                // Nút Hủy (Chỉ hiện khi chưa hoàn thành hoặc chưa hủy)
                if (order.status != 'Completed' && order.status != 'Canceled')
                  OutlinedButton.icon(
                    icon: const Icon(Icons.cancel, size: 16),
                    label: const Text("Hủy đơn"),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                    onPressed: () => _updateStatus(order, 'Canceled'),
                  ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
