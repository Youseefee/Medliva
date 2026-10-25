class UserModel {
  const UserModel({
    required this.id,
    required this.role,
    this.email,
    this.phone,
    this.name,
    this.language = 'ar',
    this.timezone = 'Africa/Cairo',
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      role: json['role'] as String? ?? 'patient',
      name: json['name'] as String?,
      language: json['language'] as String? ?? 'ar',
      timezone: json['timezone'] as String? ?? 'Africa/Cairo',
    );
  }

  final String id;
  final String? email;
  final String? phone;
  final String? name;
  final String role;
  final String language;
  final String timezone;

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'phone': phone,
    'name': name,
    'role': role,
    'language': language,
    'timezone': timezone,
  };

  bool get isPatient => role == 'patient';
  bool get isCaregiver => role == 'caregiver';
}
