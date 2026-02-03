class User {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final UserRole role;
  final String? profilePicture;
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final bool isActive;
  final bool profileCompleted;
  final DateTime? lastLogin;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.role,
    this.profilePicture,
    this.isEmailVerified = false,
    this.isPhoneVerified = false,
    this.isActive = true,
    this.profileCompleted = false,
    this.lastLogin,
    required this.createdAt,
    required this.updatedAt,
  });

  String get fullName => '$firstName $lastName';
  String get initials => '${firstName[0]}${lastName[0]}'.toUpperCase();

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? json['_id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: UserRole.fromString(json['role'] ?? 'student'),
      profilePicture: json['profilePicture'],
      isEmailVerified: json['isEmailVerified'] ?? false,
      isPhoneVerified: json['isPhoneVerified'] ?? false,
      isActive: json['isActive'] ?? true,
      profileCompleted: json['profileCompleted'] ?? false,
      lastLogin: json['lastLogin'] != null ? DateTime.parse(json['lastLogin']) : null,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'role': role.value,
      'profilePicture': profilePicture,
      'isEmailVerified': isEmailVerified,
      'isPhoneVerified': isPhoneVerified,
      'isActive': isActive,
      'profileCompleted': profileCompleted,
      'lastLogin': lastLogin?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    UserRole? role,
    String? profilePicture,
    bool? isEmailVerified,
    bool? isPhoneVerified,
    bool? isActive,
    bool? profileCompleted,
    DateTime? lastLogin,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      profilePicture: profilePicture ?? this.profilePicture,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      isActive: isActive ?? this.isActive,
      profileCompleted: profileCompleted ?? this.profileCompleted,
      lastLogin: lastLogin ?? this.lastLogin,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'User(id: $id, name: $fullName, email: $email, role: ${role.value})';
  }
}

enum UserRole {
  student('student'),
  tutor('tutor'),
  admin('admin');

  const UserRole(this.value);
  final String value;

  static UserRole fromString(String value) {
    switch (value.toLowerCase()) {
      case 'student':
        return UserRole.student;
      case 'tutor':
        return UserRole.tutor;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.student;
    }
  }

  String get displayName {
    switch (this) {
      case UserRole.student:
        return 'Student';
      case UserRole.tutor:
        return 'Tutor';
      case UserRole.admin:
        return 'Admin';
    }
  }

  bool get isStudent => this == UserRole.student;
  bool get isTutor => this == UserRole.tutor;
  bool get isAdmin => this == UserRole.admin;
}

// Authentication state
class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final User? user;
  final String? token;
  final String? error;
  final bool requiresEmailVerification;
  final bool requiresProfileCompletion;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.user,
    this.token,
    this.error,
    this.requiresEmailVerification = false,
    this.requiresProfileCompletion = false,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    User? user,
    String? token,
    String? error,
    bool? requiresEmailVerification,
    bool? requiresProfileCompletion,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      token: token ?? this.token,
      error: error ?? this.error,
      requiresEmailVerification: requiresEmailVerification ?? this.requiresEmailVerification,
      requiresProfileCompletion: requiresProfileCompletion ?? this.requiresProfileCompletion,
    );
  }

  AuthState clearError() {
    return copyWith(error: null);
  }

  AuthState setLoading(bool loading) {
    return copyWith(isLoading: loading, error: null);
  }

  AuthState setError(String error) {
    return copyWith(error: error, isLoading: false);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthState &&
        other.isAuthenticated == isAuthenticated &&
        other.isLoading == isLoading &&
        other.user == user &&
        other.token == token &&
        other.error == error &&
        other.requiresEmailVerification == requiresEmailVerification &&
        other.requiresProfileCompletion == requiresProfileCompletion;
  }

  @override
  int get hashCode {
    return Object.hash(
      isAuthenticated,
      isLoading,
      user,
      token,
      error,
      requiresEmailVerification,
      requiresProfileCompletion,
    );
  }

  @override
  String toString() {
    return 'AuthState(isAuthenticated: $isAuthenticated, isLoading: $isLoading, user: $user, error: $error)';
  }
}