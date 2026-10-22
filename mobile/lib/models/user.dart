class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String role;
  final int pointsBalance;
  final bool isDemoAccount;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.pointsBalance,
    required this.isDemoAccount,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      fullName: json['fullName'] ?? 'Passenger',
      email: json['email'] ?? '',
      role: json['role'] ?? 'PASSENGER',
      pointsBalance: json['pointsBalance'] ?? 0,
      isDemoAccount: json['isDemoAccount'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'fullName': fullName,
    'email': email,
    'role': role,
    'pointsBalance': pointsBalance,
    'isDemoAccount': isDemoAccount,
  };
}
