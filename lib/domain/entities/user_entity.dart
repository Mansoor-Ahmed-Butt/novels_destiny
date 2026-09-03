enum UserRole {
  reader,
  writer,
  admin;

  String get displayName {
    switch (this) {
      case UserRole.reader:
        return 'Reader';
      case UserRole.writer:
        return 'Writer';
      case UserRole.admin:
        return 'Admin';
    }
  }
}

enum ApprovalStatus {
  pending,
  approved,
  rejected;

  String get displayName {
    switch (this) {
      case ApprovalStatus.pending:
        return 'Pending Review';
      case ApprovalStatus.approved:
        return 'Approved';
      case ApprovalStatus.rejected:
        return 'Rejected';
    }
  }
}

class UserEntity {
  final String id;
  final String displayName;
  final String email;
  final String? photoUrl;
  final UserRole role;
  final ApprovalStatus approvalStatus;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastSeenAt;
  final String? bio;

  const UserEntity({
    required this.id,
    required this.displayName,
    required this.email,
    this.photoUrl,
    required this.role,
    this.approvalStatus = ApprovalStatus.approved,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.lastSeenAt,
    this.bio,
  });

  bool get isReader => role == UserRole.reader;
  bool get isWriter => role == UserRole.writer;
  bool get isAdmin => role == UserRole.admin;
  bool get isWriterApproved => role != UserRole.writer || approvalStatus == ApprovalStatus.approved;
  bool get isWriterPending => role == UserRole.writer && approvalStatus == ApprovalStatus.pending;

  UserEntity copyWith({
    String? id,
    String? displayName,
    String? email,
    String? photoUrl,
    UserRole? role,
    ApprovalStatus? approvalStatus,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastSeenAt,
    String? bio,
  }) {
    return UserEntity(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      bio: bio ?? this.bio,
    );
  }
}
