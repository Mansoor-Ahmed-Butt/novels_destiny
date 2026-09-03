import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.displayName,
    required super.email,
    super.photoUrl,
    required super.role,
    super.approvalStatus = ApprovalStatus.approved,
    super.isActive = true,
    required super.createdAt,
    required super.updatedAt,
    super.lastSeenAt,
    super.bio,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      photoUrl: json['photoUrl'] as String?,
      role: UserRole.values.firstWhere(
        (r) => r.name == (json['role'] as String?),
        orElse: () => UserRole.reader,
      ),
      approvalStatus: ApprovalStatus.values.firstWhere(
        (s) => s.name == (json['approvalStatus'] as String?),
        orElse: () => ApprovalStatus.approved,
      ),
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      lastSeenAt: json['lastSeenAt'] != null
          ? DateTime.tryParse(json['lastSeenAt'].toString())
          : null,
      bio: json['bio'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'role': role.name,
      'approvalStatus': approvalStatus.name,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastSeenAt': lastSeenAt?.toIso8601String(),
      'bio': bio,
    };
  }

  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      displayName: entity.displayName,
      email: entity.email,
      photoUrl: entity.photoUrl,
      role: entity.role,
      approvalStatus: entity.approvalStatus,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      lastSeenAt: entity.lastSeenAt,
      bio: entity.bio,
    );
  }
}
