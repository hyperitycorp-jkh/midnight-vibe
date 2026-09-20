import 'package:equatable/equatable.dart';

enum UserStatus {
  active,
  inactive,
  banned,
}

class User extends Equatable {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String? phoneNumber;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final UserStatus status;
  final Map<String, dynamic>? metadata;

  const User({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.phoneNumber,
    required this.createdAt,
    this.lastLoginAt,
    this.status = UserStatus.active,
    this.metadata,
  });

  // fromJson 생성자
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      uid: json['uid'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.parse(json['lastLoginAt'] as String)
          : null,
      status: UserStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => UserStatus.active,
      ),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  // toJson 메서드
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'phoneNumber': phoneNumber,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'status': status.name,
      'metadata': metadata,
    };
  }

  // copyWith 메서드
  User copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    String? phoneNumber,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    UserStatus? status,
    Map<String, dynamic>? metadata,
  }) {
    return User(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        uid,
        email,
        displayName,
        photoUrl,
        phoneNumber,
        createdAt,
        lastLoginAt,
        status,
        metadata,
      ];
}