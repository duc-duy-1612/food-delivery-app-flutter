import 'package:flutter/material.dart';
import '../../models/food_model.dart';
import '../../models/category_model.dart';
import '../../services/api_service.dart';import 'admin_food_edit_screen.dart';
import 'admin_category_screen.dart';
import '../../screens/auth/login_screen.dart';

class AdminFoodScreen extends StatefulWidget {
  const AdminFoodScreen({super.key});

  @override
  State<AdminFoodScreen> createState() => _AdminFoodScreenState();
}

class _AdminFoodScreenState extends State<AdminFoodScreen> {
  final ApiService _apiService = ApiService();
  List<FoodModel> _allFoods = [];
  List<CategoryModel> _categories = [];
  String _selectedCategoryId = "All";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final foodsFuture = _apiService.getFoods();
    final categoriesFuture = _apiService.getCategories();
    final results = await Future.wait([foodsFuture, categoriesFuture]);

    if (mounted) {
      setState(() {
        _allFoods = results[0] as List<FoodModel>;
        _categories = results[1] as List<CategoryModel>;
        _isLoading = false;
      });
    }
  }

  // Chức năng Ẩn/Hiện món ăn nhanh
  void _toggleAvailability(FoodModel food) async {
    // Đảo ngược trạng thái
    food.isAvailable = !food.isAvailable;

    // Gọi API cập nhật
    await _apiService.updateFood(food);

    // Cập nhật lại UI
    setState(() {});
  }

  List<FoodModel> get _filteredFoods {
    if (_selectedCategoryId == "All") return _allFoods;
    return _allFoods.where((food) => food.categoryId == _selectedCategoryId).toList();
  }

  void _navigateToEditScreen([FoodModel? food]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AdminFoodEditScreen(food: food)),
    );
    if (result == true) _loadData();
  }

  void _deleteFood(String id) async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xác nhận"),
        content: const Text("Xóa món ăn này?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Hủy")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Xóa", style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;

    if (confirm) {
      await _apiService.deleteFood(id);
      _loadData();
    }
  }

  String formatCurrency(dynamic price) {
    if (price == null) return "0";
    return "${price.toString()} đ"; // Format đơn giản cho nhanh
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quản Lý Thực Đơn"),

        actions: [
          // Nút để vào màn hình quản lý Danh Mục
          TextButton.icon(
            icon: const Icon(Icons.category, color: Colors.black),
            label: const Text("Danh Mục", style: TextStyle(color: Colors.black)),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminCategoryScreen()));
            },
          ),

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
          : Column(
        children: [
          // Thanh lọc danh mục
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) return _buildCategoryItem(id: "All", name: "Tất cả");
                final cat = _categories[index - 1];
                return _buildCategoryItem(id: cat.id!, name: cat.name!);
              },
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: _filteredFoods.length,
              itemBuilder: (context, index) {
                final food = _filteredFoods[index];
                return Card(
                  // Món nào bị ẩn thì màu nền xám đi chút
                  color: food.isAvailable ? Colors.white : Colors.grey[200],
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: Image.network(
                            food.image ?? "", width: 60, height: 60, fit: BoxFit.cover,
                            errorBuilder: (_,__,___) => const Icon(Icons.fastfood, size: 40, color: Colors.grey),
                          ),
                        ),
                        if (!food.isAvailable)
                          Container(
                            width: 60, height: 60,
                            color: Colors.black54,
                            child: const Center(child: Text("HẾT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                          )
                      ],
                    ),
                    title: Text(food.name ?? "", style: TextStyle(fontWeight: FontWeight.bold, color: food.isAvailable ? Colors.black : Colors.grey)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(formatCurrency(food.price), style: const TextStyle(color: Colors.red)),
                        // SWITCH ẨN HIỆN
                        Row(
                          children: [
                            const Text("Tình trạng: ", style: TextStyle(fontSize: 12)),
                            Switch(
                              value: food.isAvailable,
                              onChanged: (val) => _toggleAvailability(food),
                              activeColor: Colors.green,
                            ),
                          ],
                        )
                      ],
                    ),
                    trailing: PopupMenuButton(
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(value: 'edit', child: Text("Sửa món")),
                        const PopupMenuItem(value: 'delete', child: Text("Xóa món", style: TextStyle(color: Colors.red))),
                      ],
                      onSelected: (val) {
                        if (val == 'edit') _navigateToEditScreen(food);
                        if (val == 'delete') _deleteFood(food.id!);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToEditScreen(null),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoryItem({required String id, required String name}) {
    final isSelected = _selectedCategoryId == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategoryId = id),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueGrey : Colors.grey[300],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(name, style: TextStyle(color: isSelected ? Colors.white : Colors.black)),
      ),
    );
  }
}
