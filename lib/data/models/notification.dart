import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Types of notifications in the system
enum NotificationType {
  statusChange('Status Change', 'Project status was updated'),
  comment('New Comment', 'Someone commented on a project'),
  mention('Mentioned', 'You were mentioned in a comment'),
  approvalRequest('Approval Request', 'A project needs your approval'),
  approvalReminder('Approval Reminder', 'Pending approval reminder'),
  projectAssigned('Project Assigned', 'You were assigned to a project'),
  documentUploaded('Document Uploaded', 'A document was added to a project');

  final String title;
  final String description;

  const NotificationType(this.title, this.description);
}

/// Represents a notification for a user
class AppNotification extends Equatable {
  final String id;
  final String userId;
  final NotificationType type;
  final String? projectId;
  final String? projectName;
  final String message;
  final String? triggeredByUserId;
  final String? triggeredByUserName;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    this.projectId,
    this.projectName,
    required this.message,
    this.triggeredByUserId,
    this.triggeredByUserName,
    this.isRead = false,
    required this.createdAt,
    this.metadata,
  });

  /// Create from Firestore document
  factory AppNotification.fromMap(Map<String, dynamic> map, String id) {
    return AppNotification(
      id: id,
      userId: map['userId'] as String? ?? '',
      type: _parseNotificationType(map['type'] as String?),
      projectId: map['projectId'] as String?,
      projectName: map['projectName'] as String?,
      message: map['message'] as String? ?? '',
      triggeredByUserId: map['triggeredByUserId'] as String?,
      triggeredByUserName: map['triggeredByUserName'] as String?,
      isRead: map['isRead'] as bool? ?? false,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type.name,
      'projectId': projectId,
      'projectName': projectName,
      'message': message,
      'triggeredByUserId': triggeredByUserId,
      'triggeredByUserName': triggeredByUserName,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      'metadata': metadata,
    };
  }

  AppNotification copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? projectId,
    String? projectName,
    String? message,
    String? triggeredByUserId,
    String? triggeredByUserName,
    bool? isRead,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      projectId: projectId ?? this.projectId,
      projectName: projectName ?? this.projectName,
      message: message ?? this.message,
      triggeredByUserId: triggeredByUserId ?? this.triggeredByUserId,
      triggeredByUserName: triggeredByUserName ?? this.triggeredByUserName,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      metadata: metadata ?? this.metadata,
    );
  }

  static NotificationType _parseNotificationType(String? type) {
    if (type == null) return NotificationType.statusChange;
    try {
      return NotificationType.values.firstWhere(
        (e) => e.name.toLowerCase() == type.toLowerCase(),
      );
    } catch (_) {
      return NotificationType.statusChange;
    }
  }

  /// Get time ago string for display
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 7) {
      return '${createdAt.month}/${createdAt.day}/${createdAt.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        type,
        projectId,
        projectName,
        message,
        triggeredByUserId,
        triggeredByUserName,
        isRead,
        createdAt,
        metadata,
      ];
}
