class UserModel {
  // Dùng String? (có thể null) cho an toàn
  final String? id;
  final String? email;
  final String? password;
  final String? name;
  final String? phone;
  final String? address;
  final String? avatar;

  UserModel({
    this.id,
    this.email,
    this.password,
    this.name,
    this.phone,
    this.address,
    this.avatar,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      // Dùng cú pháp ?? "" để nếu null thì gán bằng chuỗi rỗng -> Không bị lỗi
      id: json['id']?.toString(),
      email: json['email']?.toString(),
      password: json['password']?.toString(),
      name: json['name']?.toString(),
      phone: json['phone']?.toString(),
      address: json['address']?.toString(),
      avatar: json['avatar']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'name': name,
      'phone': phone,
      'address': address,
      'avatar': avatar,
    };
  }
}
