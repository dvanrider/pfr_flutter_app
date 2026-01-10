import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Represents a comment on a project
class Comment extends Equatable {
  final String id;
  final String projectId;
  final String userId;
  final String userDisplayName;
  final String? userEmail;
  final String content;
  final String? parentId; // For threaded replies
  final List<String> mentions; // User IDs mentioned with @
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isEdited;

  const Comment({
    required this.id,
    required this.projectId,
    required this.userId,
    required this.userDisplayName,
    this.userEmail,
    required this.content,
    this.parentId,
    this.mentions = const [],
    required this.createdAt,
    this.updatedAt,
    this.isEdited = false,
  });

  /// Create from Firestore document
  factory Comment.fromMap(Map<String, dynamic> map, String id) {
    return Comment(
      id: id,
      projectId: map['projectId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      userDisplayName: map['userDisplayName'] as String? ?? 'Unknown User',
      userEmail: map['userEmail'] as String?,
      content: map['content'] as String? ?? '',
      parentId: map['parentId'] as String?,
      mentions: (map['mentions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
      isEdited: map['isEdited'] as bool? ?? false,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'projectId': projectId,
      'userId': userId,
      'userDisplayName': userDisplayName,
      'userEmail': userEmail,
      'content': content,
      'parentId': parentId,
      'mentions': mentions,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isEdited': isEdited,
    };
  }

  Comment copyWith({
    String? id,
    String? projectId,
    String? userId,
    String? userDisplayName,
    String? userEmail,
    String? content,
    String? parentId,
    List<String>? mentions,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isEdited,
  }) {
    return Comment(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      userId: userId ?? this.userId,
      userDisplayName: userDisplayName ?? this.userDisplayName,
      userEmail: userEmail ?? this.userEmail,
      content: content ?? this.content,
      parentId: parentId ?? this.parentId,
      mentions: mentions ?? this.mentions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isEdited: isEdited ?? this.isEdited,
    );
  }

  /// Check if this is a reply to another comment
  bool get isReply => parentId != null;

  /// Get initials for avatar
  String get initials {
    final parts = userDisplayName.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return userDisplayName.isNotEmpty ? userDisplayName[0].toUpperCase() : '?';
  }

  @override
  List<Object?> get props => [
        id,
        projectId,
        userId,
        userDisplayName,
        userEmail,
        content,
        parentId,
        mentions,
        createdAt,
        updatedAt,
        isEdited,
      ];
}

/// Helper to extract @mentions from text
class MentionParser {
  static final RegExp mentionRegex = RegExp(r'@(\w+(?:\s+\w+)?)');

  /// Extract mentioned names from content
  static List<String> extractMentions(String content) {
    return mentionRegex
        .allMatches(content)
        .map((m) => m.group(1)!)
        .toList();
  }

  /// Replace @mentions with styled spans (for display)
  static String highlightMentions(String content) {
    return content.replaceAllMapped(mentionRegex, (match) {
      return '**@${match.group(1)}**';
    });
  }
}
