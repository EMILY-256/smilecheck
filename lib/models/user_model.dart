class User {
  final String id;
  final String name;
  final String email;
  final String? profileImageUrl;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.profileImageUrl,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'profileImageUrl': profileImageUrl,
      };

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'],
        name: json['name'],
        email: json['email'],
        profileImageUrl: json['profileImageUrl'],
      );
}