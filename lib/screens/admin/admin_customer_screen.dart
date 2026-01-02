import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../screens/auth/login_screen.dart'; // Để dùng nút logout nếu cần
import 'admin_customer_history_screen.dart'; // Import màn hình lịch sử vừa tạo

class AdminCustomerScreen extends StatefulWidget {
  const AdminCustomerScreen({super.key});

  @override
  State<AdminCustomerScreen> createState() => _AdminCustomerScreenState();
}

class _AdminCustomerScreenState extends State<AdminCustomerScreen> {
  final ApiService _apiService = ApiService();
  List<UserModel> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    final data = await _apiService.getAllUsers();

    // Lọc bỏ tài khoản admin (SĐT 02838212345) khỏi danh sách hiển thị
    final customers = data.where((u) => u.phone != "02838212345").toList();

    setState(() {
      _users = customers;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar để hiển thị tiêu đề và nút logout nếu dùng NavigationBar thì phần này có thể ẩn đi tùy cách bạn config
      appBar: AppBar(
        title: const Text("Danh Sách Khách Hàng"),
        automaticallyImplyLeading: false, // Ẩn nút back nếu nằm trong Tab
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final user = _users[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(user.avatar ?? "https://i.pravatar.cc/150?img=3"),
                onBackgroundImageError: (_,__) {},
                child: (user.avatar == null || user.avatar!.isEmpty) ? const Icon(Icons.person) : null,
              ),
              title: Text(user.name ?? "Không tên", style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("SĐT: ${user.phone}"),
                  Text("Email: ${user.email ?? 'Không có'}"),
                ],
              ),
              trailing: const Icon(Icons.history, color: Colors.blue),
              onTap: () {
                // Chuyển sang xem lịch sử mua hàng của khách này
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AdminCustomerHistoryScreen(user: user)),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
