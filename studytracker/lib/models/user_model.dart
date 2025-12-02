class UserModel {
  final String userId;
  final String name;
  final String email;

  UserModel({
    required this.userId,
    required this.name,
    required this.email,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'name': name,
        'email': email,
      };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        userId: json['userId'],
        name: json['name'],
        email: json['email'],
      );
}
