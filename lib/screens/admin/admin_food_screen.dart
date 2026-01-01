import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/food_model.dart';
import '../../models/category_model.dart'; // THÊM import này
import '../../services/api_service.dart';
import 'admin_food_edit_screen.dart';

class AdminFoodScreen extends StatefulWidget {
  const AdminFoodScreen({super.key});

  @override
  State<AdminFoodScreen> createState() => _AdminFoodScreenState();
}

class _AdminFoodScreenState extends State<AdminFoodScreen> {
  final ApiService _apiService = ApiService();

  List<FoodModel> _allFoods = []; // Danh sách tất cả món ăn
  List<CategoryModel> _categories = []; // Danh sách danh mục
  String _selectedCategoryId = "All"; // Mặc định chọn tất cả
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData(); // Đổi tên hàm để tải cả 2 loại dữ liệu
  }

  // Tải đồng thời món ăn và danh mục
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Gọi API song song để tăng tốc
      final foodsFuture = _apiService.getFoods();
      final categoriesFuture = _apiService.getCategories();

      final results = await Future.wait([foodsFuture, categoriesFuture]);

      setState(() {
        _allFoods = results[0] as List<FoodModel>;
        _categories = results[1] as List<CategoryModel>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // Xử lý lỗi nếu có
    }
  }

  // Getter để lọc danh sách món ăn dựa trên category đã chọn
  List<FoodModel> get _filteredFoods {
    if (_selectedCategoryId == "All") {
      return _allFoods;
    }
    return _allFoods.where((food) => food.categoryId == _selectedCategoryId).toList();
  }


  // Chuyển sang màn hình thêm/sửa
  void _navigateToEditScreen([FoodModel? food]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AdminFoodEditScreen(food: food)),
    );

    if (result == true) {
      _loadData();
    }
  }

  void _deleteFood(String id) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xác nhận"),
        content: const Text("Bạn có chắc muốn xóa món này?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Hủy")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Xóa")),
        ],
      ),
    );

    if (confirm) {
      await _apiService.deleteFood(id);
      _loadData();
      if(!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã xóa món ăn")));
    }
  }

  String formatCurrency(dynamic price) {
    if (price == null) return "0 đ";
    double realPrice = double.tryParse(price.toString()) ?? 0.0;
    final format = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    return format.format(realPrice);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Quản Lý Thực Đơn")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // THANH LỌC DANH MỤC
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(vertical: 10),
              itemCount: _categories.length + 1, // +1 cho nút "Tất cả"
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildCategoryItem(id: "All", name: "Tất cả");
                }
                final category = _categories[index - 1];
                return _buildCategoryItem(id: category.id!, name: category.name!);
              },
            ),
          ),
          const Divider(height: 1),

          // DANH SÁCH MÓN ĂN ĐÃ LỌC
          Expanded(
            child: _filteredFoods.isEmpty
                ? const Center(child: Text("Không có món ăn trong danh mục này."))
                : ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: _filteredFoods.length,
              itemBuilder: (context, index) {
                final food = _filteredFoods[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(10),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: Image.network(
                          food.image ?? "",
                          width: 60, height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (_,__,___)=> const Icon(Icons.fastfood, size: 40, color: Colors.grey)
                      ),
                    ),
                    title: Text(food.name ?? "", style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(formatCurrency(food.price), style: const TextStyle(color: Colors.red)),
                        Text("ID: ${food.id} - CatID: ${food.categoryId}", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _navigateToEditScreen(food),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteFood(food.id!),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToEditScreen(null),
        label: const Text("Thêm Món"),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
      ),
    );
  }

  // Widget để vẽ nút lọc
  Widget _buildCategoryItem({required String id, required String name}) {
    final isSelected = _selectedCategoryId == id;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedCategoryId = id);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueGrey : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Text(
          name,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
