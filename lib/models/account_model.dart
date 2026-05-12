class Account {
  final int id;
  final String name;
  final String email;
  final String password;

  Account({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      password: json['password'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'email': email, 'password': password};
  }
}
