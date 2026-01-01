import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controller
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _passwordController;
  late TextEditingController _emailController;
  late TextEditingController _avatarController; // Thêm controller cho Avatar

  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Lấy user hiện tại từ Provider để điền sẵn vào ô
    final user = Provider.of<UserProvider>(context, listen: false).user;

    _nameController = TextEditingController(text: user?.name ?? "");
    _phoneController = TextEditingController(text: user?.phone ?? "");
    _addressController = TextEditingController(text: user?.address ?? "");
    _passwordController = TextEditingController(text: user?.password ?? "");
    _emailController = TextEditingController(text: user?.email ?? "");
    _avatarController = TextEditingController(text: user?.avatar ?? "");
  }

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final currentUser = Provider.of<UserProvider>(context, listen: false).user;

    // Tạo user mới với thông tin đã sửa
    UserModel updatedUser = UserModel(
      id: currentUser!.id,
      name: _nameController.text,
      phone: _phoneController.text,
      address: _addressController.text,
      password: _passwordController.text,
      email: _emailController.text,
      avatar: _avatarController.text, // Cập nhật avatar mới
    );

    // 1. Gọi API cập nhật lên Server
    bool success = await _apiService.updateUser(updatedUser);

    setState(() => _isLoading = false);

    if (success) {
      // 2. Cập nhật lại Provider để App hiển thị thông tin mới ngay lập tức
      if (!mounted) return;
      Provider.of<UserProvider>(context, listen: false).setUser(updatedUser);

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cập nhật thành công!")));
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lỗi cập nhật!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lấy link avatar hiện tại để hiển thị preview
    // Nếu link trống hoặc lỗi thì dùng ảnh mặc định
    String currentAvatar = _avatarController.text;
    if (currentAvatar.isEmpty) {
      currentAvatar = "https://i.pravatar.cc/150?img=default";
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Thông Tin Cá Nhân")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Hiển thị Avatar
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: NetworkImage(currentAvatar),
                      onBackgroundImageError: (_, __) {
                        // Xử lý khi load ảnh lỗi (không làm gì hoặc log ra)
                      },
                      child: currentAvatar.isEmpty
                          ? const Icon(Icons.person, size: 60, color: Colors.grey)
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Nhập link Avatar
              TextFormField(
                controller: _avatarController,
                decoration: const InputDecoration(
                    labelText: "Link Avatar (URL)",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.image)
                ),
                onChanged: (value) {
                  // Cập nhật lại UI khi nhập link ảnh để xem preview
                  setState(() {});
                },
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Họ và tên", border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
                validator: (val) => val!.isEmpty ? "Không để trống" : null,
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: "Số điện thoại", border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone)),
                enabled: false, // Thường không cho sửa SĐT vì là ID đăng nhập
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "Email", border: OutlineInputBorder(), prefixIcon: Icon(Icons.email)),
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: "Địa chỉ giao hàng", border: OutlineInputBorder(), prefixIcon: Icon(Icons.home)),
                validator: (val) => val!.isEmpty ? "Không để trống" : null,
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Mật khẩu", border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock)),
                validator: (val) => val!.length < 3 ? "Mật khẩu quá ngắn" : null,
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                  onPressed: _isLoading ? null : _saveProfile,
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("LƯU THAY ĐỔI"),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
