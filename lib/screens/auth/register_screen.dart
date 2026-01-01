import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();
  final _addressController = TextEditingController();

  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  void _handleRegister() async {
    // 1. Validate dữ liệu
    if (_nameController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _passController.text.isEmpty ||
        _addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập đầy đủ thông tin")),
      );
      return;
    }

    if (_passController.text != _confirmPassController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Mật khẩu xác nhận không khớp!")),
      );
      return;
    }

    setState(() => _isLoading = true);

    // 2. Tạo object User mới (Avatar lấy ngẫu nhiên cho đẹp)
    UserModel newUser = UserModel(
      name: _nameController.text,
      phone: _phoneController.text.trim(),
      password: _passController.text,
      address: _addressController.text,
      email: "${_phoneController.text}@gmail.com", // Giả lập email theo sđt
      avatar: "https://i.pravatar.cc/150?u=${DateTime.now().millisecondsSinceEpoch}", // Avatar random
    );

    // 3. Gọi API
    bool success = await _apiService.registerUser(newUser);

    setState(() => _isLoading = false);

    if (success) {
      if (!mounted) return;
      // Thông báo và quay về Login
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Thành công"),
          content: const Text("Tài khoản đã được tạo. Vui lòng đăng nhập."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop(); // Đóng dialog
                Navigator.of(context).pop(); // Quay về màn hình Login
              },
              child: const Text("OK"),
            )
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đăng ký thất bại! SĐT có thể đã tồn tại.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Đăng Ký Tài Khoản")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.person_add, size: 80, color: Colors.orange),
            const SizedBox(height: 20),

            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Họ và tên", border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
            ),
            const SizedBox(height: 15),

            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: "Số điện thoại", border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone)),
            ),
            const SizedBox(height: 15),

            TextField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: "Địa chỉ nhận hàng", border: OutlineInputBorder(), prefixIcon: Icon(Icons.home)),
            ),
            const SizedBox(height: 15),

            TextField(
              controller: _passController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Mật khẩu", border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock)),
            ),
            const SizedBox(height: 15),

            TextField(
              controller: _confirmPassController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Nhập lại mật khẩu", border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock_outline)),
            ),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                onPressed: _isLoading ? null : _handleRegister,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("ĐĂNG KÝ NGAY", style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
