import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/order_model.dart';
import '../../services/api_service.dart';
import 'admin_order_detail_screen.dart';
import '../auth/login_screen.dart';

class AdminOrderScreen extends StatefulWidget {
  const AdminOrderScreen({super.key});

  @override
  State<AdminOrderScreen> createState() => _AdminOrderScreenState();
}

class _AdminOrderScreenState extends State<AdminOrderScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();

  List<OrderModel> _orders = [];
  bool _isLoading = true;

  String _selectedStatus = "All";
  final List<String> _statuses = ["All", "Placed", "Preparing", "Shipping", "Completed", "Cancelled"];

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final data = await _apiService.getAllOrders();
      setState(() {
        _orders = data;
        _isLoading = false;
      });
    } catch (e) {
      print(e);
      setState(() => _isLoading = false);
    }
  }

  List<OrderModel> get _filteredOrders {
    List<OrderModel> temp = _selectedStatus == "All"
        ? _orders
        : _orders.where((o) => o.status == _selectedStatus).toList();

    if (_searchQuery.isNotEmpty) {
      String query = _searchQuery.toLowerCase().trim(); // Xóa khoảng trắng thừa
      temp = temp.where((o) {
        final id = o.id.toLowerCase();
        final address = (o.address ?? "").toLowerCase();
        final userId = o.userId.toLowerCase();

        // Lấy tên khách hàng để tìm kiếm
        final userName = (o.userName ?? "").toLowerCase();
        final userPhone = (o.userPhone ?? "").toLowerCase();
        final userEmail = (o.userEmail ?? "").toLowerCase();

        return id.contains(query) ||
            address.contains(query) ||
            userId.contains(query) ||
            userName.contains(query) ||
            userPhone.contains(query) ||
            userEmail.contains(query);
      }).toList();
    }

    if (_startDate != null && _endDate != null) {
      temp = temp.where((o) {
        if (o.createdAt == null) return false;
        DateTime orderDate = DateTime.parse(o.createdAt!);
        DateTime start = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
        DateTime end = DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59);
        return orderDate.isAfter(start) && orderDate.isBefore(end);
      }).toList();
    }

    temp.sort((a, b) => (b.createdAt ?? "").compareTo(a.createdAt ?? ""));
    return temp;
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.orange,
            colorScheme: const ColorScheme.light(primary: Colors.orange),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  String formatCurrency(double price) {
    return NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(price);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quản Lý Đơn Hàng"),

        actions: [
          IconButton(onPressed: _loadOrders, icon: const Icon(Icons.refresh)),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          )
        ],
      ),
      body: Column(
        children: [
          // 1. Tab trạng thái
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: _statuses.map((status) {
                final isSelected = _selectedStatus == status;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(status),
                    selected: isSelected,
                    onSelected: (bool selected) {
                      setState(() {
                        _selectedStatus = status;
                      });
                    },
                    backgroundColor: Colors.grey[200],
                    selectedColor: Colors.orange[100],
                    checkmarkColor: Colors.orange,
                  ),
                );
              }).toList(),
            ),
          ),

          // 2. Tìm kiếm
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Nhập tên khách hàng, mã đơn...",
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = "");
                      },
                    ) : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _selectDateRange(context),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.date_range, color: Colors.orange),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            (_startDate != null && _endDate != null)
                                ? "${DateFormat('dd/MM/yyyy').format(_startDate!)} - ${DateFormat('dd/MM/yyyy').format(_endDate!)}"
                                : "Lọc theo khoảng thời gian",
                            style: TextStyle(
                              color: (_startDate != null) ? Colors.black : Colors.grey[600],
                              fontWeight: (_startDate != null) ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (_startDate != null)
                          GestureDetector(
                            onTap: () => setState(() { _startDate = null; _endDate = null; }),
                            child: const Icon(Icons.close, color: Colors.grey),
                          )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 20),

          // 3. Danh sách
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredOrders.isEmpty
                ? const Center(child: Text("Không tìm thấy đơn hàng nào!"))
                : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _filteredOrders.length,
              itemBuilder: (context, index) {
                final order = _filteredOrders[index];

                // Logic hiển thị tên: Ưu tiên userName, nếu không có thì fallback
                String displayName = (order.userName != null && order.userName!.isNotEmpty)
                    ? order.userName!
                    : "Khách lẻ (Chưa cập nhật tên)";

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text("Đơn #${order.id}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 5),
                        Text("Ngày: ${DateFormat('dd/MM HH:mm').format(DateTime.parse(order.createdAt ?? DateTime.now().toString()))}"),

                        // --- HIỂN THỊ TÊN KHÁCH HÀNG ---
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(color: Colors.black87, fontSize: 14),
                            children: [
                              const TextSpan(text: "Khách: ", style: TextStyle(fontWeight: FontWeight.bold)),
                              TextSpan(
                                  text: "$displayName ",
                                  style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)
                              ),
                              TextSpan(text: "- ${order.address}"),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // --------------------------------

                        const SizedBox(height: 5),
                        Row(
                          children: [
                            const Text("Trạng thái: "),
                            Text(
                                order.status,
                                style: TextStyle(
                                    color: getStatusColor(order.status),
                                    fontWeight: FontWeight.bold
                                )
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(formatCurrency(order.totalPrice), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => AdminOrderDetailScreen(order: order))).then((_) => _loadOrders());
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
