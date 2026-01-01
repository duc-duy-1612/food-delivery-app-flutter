import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../services/api_service.dart';
import '../../services/local_storage_service.dart'; // Import service mới
import '../home/home_screen.dart';
import 'register_screen.dart';
import '../admin/admin_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passController = TextEditingController();

  final ApiService _apiService = ApiService();
  final LocalStorageService _storageService = LocalStorageService(); // Khởi tạo

  bool _isLoading = false;
  List<Map<String, dynamic>> _savedUsers = []; // Danh sách gợi ý

  @override
  void initState() {
    super.initState();
    _loadSavedUsers(); // Tải danh sách gợi ý khi mở màn hình
  }

  Future<void> _loadSavedUsers() async {
    final list = await _storageService.getSavedUsers();
    setState(() {
      _savedUsers = list;
    });
  }

  void _handleLogin() async {
    if (_phoneController.text.isEmpty || _passController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng nhập đầy đủ thông tin")));
      return;
    }

    setState(() => _isLoading = true);

    // --- CHECK ADMIN ---
    if (_phoneController.text == "02838212345" && _passController.text == "123") {
      setState(() => _isLoading = false);

      // Lưu lịch sử đăng nhập Admin
      await _storageService.saveUserToHistory("02838212345", "123", "Quản Trị Viên", null);

      if(!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminHomeScreen()));
      return;
    }
    // -------------------

    // Đăng nhập User thường
    final user = await _apiService.login(_phoneController.text, _passController.text);

    setState(() => _isLoading = false);

    if (user != null) {
      if (!mounted) return;
      Provider.of<UserProvider>(context, listen: false).setUser(user);

      // --- LƯU LỊCH SỬ ĐĂNG NHẬP ---
      await _storageService.saveUserToHistory(
          user.phone ?? "",
          user.password ?? "",
          user.name ?? "User",
          user.avatar
      );
      // -----------------------------

      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sai số điện thoại hoặc mật khẩu!")));
    }
  }

  // Hàm điền nhanh thông tin khi chọn gợi ý
  void _fillAccount(Map<String, dynamic> account) {
    _phoneController.text = account['phone'];
    _passController.text = account['password'];
  }

  // Hàm xóa gợi ý
  void _removeAccount(String phone) async {
    await _storageService.removeUserFromHistory(phone);
    _loadSavedUsers(); // Tải lại danh sách
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.fastfood, size: 80, color: Colors.orange),
              const SizedBox(height: 20),
              const Text("Đăng Nhập", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),

              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: "Số điện thoại", border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone)),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _passController,
                decoration: const InputDecoration(labelText: "Mật khẩu", border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock)),
                obscureText: true,
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("ĐĂNG NHẬP", style: TextStyle(fontSize: 18)),
                ),
              ),

              const SizedBox(height: 20),

              // --- PHẦN GỢI Ý TÀI KHOẢN ---
              if (_savedUsers.isNotEmpty) ...[
                const Divider(),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Đăng nhập nhanh:", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 10),

                // Hiển thị danh sách ngang
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _savedUsers.length,
                    itemBuilder: (context, index) {
                      final acc = _savedUsers[index];
                      return GestureDetector(
                        onTap: () => _fillAccount(acc),
                        child: Container(
                          width: 70,
                          margin: const EdgeInsets.only(right: 15),
                          child: Column(
                            children: [
                              Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 25,
                                    backgroundImage: (acc['avatar'] != null && acc['avatar'] != "")
                                        ? NetworkImage(acc['avatar'])
                                        : null,
                                    child: (acc['avatar'] == null || acc['avatar'] == "")
                                        ? const Icon(Icons.person) : null,
                                  ),
                                  Positioned(
                                    right: 0, top: 0,
                                    child: GestureDetector(
                                      onTap: () => _removeAccount(acc['phone']),
                                      child: const CircleAvatar(
                                        radius: 8,
                                        backgroundColor: Colors.white,
                                        child: Icon(Icons.close, size: 12, color: Colors.red),
                                      ),
                                    ),
                                  )
                                ],
                              ),
                              const SizedBox(height: 5),
                              Text(
                                acc['name'],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 10),
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                )
              ],
              // -----------------------------

              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Chưa có tài khoản? "),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen()));
                    },
                    child: const Text("Đăng ký ngay", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
