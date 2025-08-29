import 'user_status.dart';

/// Ilova foydalanuvchisi modeli
class AppUser {
  final String uid;
  final String email;
  final String? displayName;
  final UserStatus status;
  final DateTime? lastPaymentDate;
  final DateTime? accountDisabledDate;
  final bool isEmailVerified;
  final DateTime createdAt;
  final DateTime lastLoginAt;

  const AppUser({
    required this.uid,
    required this.email,
    this.displayName,
    required this.status,
    this.lastPaymentDate,
    this.accountDisabledDate,
    required this.isEmailVerified,
    required this.createdAt,
    required this.lastLoginAt,
  });

  /// Supabase User dan AppUser yaratish
  factory AppUser.fromSupabaseUser(Map<String, dynamic> user, {UserStatus? status}) {
    return AppUser(
      uid: user['id'] ?? '',
      email: user['email'] ?? '',
      displayName: user['user_metadata']?['display_name'],
      status: status ?? UserStatus.checking,
      isEmailVerified: user['email_confirmed_at'] != null,
      createdAt: user['created_at'] != null ? DateTime.parse(user['created_at']) : DateTime.now(),
      lastLoginAt: user['last_sign_in_at'] != null ? DateTime.parse(user['last_sign_in_at']) : DateTime.now(),
    );
  }

  /// Map dan AppUser yaratish (Firestore dan)
  factory AppUser.fromMap(Map<String, dynamic> map, String uid) {
    return AppUser(
      uid: uid,
      email: map['email'] ?? '',
      displayName: map['displayName'],
      status: _parseUserStatus(map['status']),
      lastPaymentDate: map['lastPaymentDate'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['lastPaymentDate'])
          : null,
      accountDisabledDate: map['accountDisabledDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['accountDisabledDate'])
          : null,
      isEmailVerified: map['isEmailVerified'] ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : DateTime.now(),
      lastLoginAt: map['lastLoginAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastLoginAt'])
          : DateTime.now(),
    );
  }

  /// AppUser ni Map ga aylantirish (Firestore uchun)
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'status': status.name,
      'lastPaymentDate': lastPaymentDate?.millisecondsSinceEpoch,
      'accountDisabledDate': accountDisabledDate?.millisecondsSinceEpoch,
      'isEmailVerified': isEmailVerified,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastLoginAt': lastLoginAt.millisecondsSinceEpoch,
    };
  }

  /// AppUser nusxasini yangilash
  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    UserStatus? status,
    DateTime? lastPaymentDate,
    DateTime? accountDisabledDate,
    bool? isEmailVerified,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      status: status ?? this.status,
      lastPaymentDate: lastPaymentDate ?? this.lastPaymentDate,
      accountDisabledDate: accountDisabledDate ?? this.accountDisabledDate,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  /// String dan UserStatus ni parse qilish
  static UserStatus _parseUserStatus(String? statusString) {
    switch (statusString) {
      case 'active':
        return UserStatus.active;
      case 'disabled':
        return UserStatus.disabled;
      case 'unregistered':
        return UserStatus.unregistered;
      case 'checking':
        return UserStatus.checking;
      case 'error':
        return UserStatus.error;
      default:
        return UserStatus.checking;
    }
  }

  @override
  String toString() {
    return 'AppUser(uid: $uid, email: $email, status: ${status.name})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppUser && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;
}
