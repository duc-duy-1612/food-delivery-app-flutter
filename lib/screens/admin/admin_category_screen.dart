import 'package:flutter/material.dart';
import '../../models/category_model.dart';
import '../../services/api_service.dart';

class AdminCategoryScreen extends StatefulWidget {
  const AdminCategoryScreen({super.key});@override
  State<AdminCategoryScreen> createState() => _AdminCategoryScreenState();
}

class _AdminCategoryScreenState extends State<AdminCategoryScreen> {
  final ApiService _apiService = ApiService();
  List<CategoryModel> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    final data = await _apiService.getCategories();
    setState(() {
      _categories = data;
      _isLoading = false;
    });
  }

  // Hiển thị dialog thêm/sửa
  void _showEditDialog([CategoryModel? category]) {
    final nameController = TextEditingController(text: category?.name ?? "");
    final imageController = TextEditingController(text: category?.image ?? "");

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(category == null ? "Thêm Danh Mục" : "Sửa Danh Mục"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Tên danh mục")),
            TextField(controller: imageController, decoration: const InputDecoration(labelText: "Link ảnh (URL)")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) return;
              Navigator.pop(ctx);

              CategoryModel newCat = CategoryModel(
                id: category?.id ?? "",
                name: nameController.text,
                image: imageController.text,
              );

              if (category == null) {
                await _apiService.addCategory(newCat);
              } else {
                await _apiService.updateCategory(newCat);
              }
              _loadCategories();
            },
            child: const Text("Lưu"),
          )
        ],
      ),
    );
  }

  void _deleteCategory(String id) async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Cảnh báo"),
        content: const Text("Xóa danh mục này có thể ảnh hưởng đến các món ăn đang thuộc danh mục đó."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Hủy")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Vẫn Xóa", style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;

    if (confirm) {
      await _apiService.deleteCategory(id);
      _loadCategories();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Quản Lý Danh Mục")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _categories.length,
        itemBuilder: (ctx, index) {
          final cat = _categories[index];
          return ListTile(
            leading: Image.network(cat.image ?? "", width: 40, height: 40, errorBuilder: (_,__,___)=>const Icon(Icons.category)),
            title: Text(cat.name ?? ""),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showEditDialog(cat)),
                IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteCategory(cat.id!)),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditDialog(null),
        child: const Icon(Icons.add),
      ),
    );
  }
}
