import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/comment.dart';
import '../data/models/notification.dart';
import '../data/models/attachment.dart';
import '../data/models/app_user.dart';
import 'auth_providers.dart';
import 'user_management_providers.dart';

// ============================================================================
// COMMENTS
// ============================================================================

/// Repository for comment operations
class CommentRepository {
  final FirebaseFirestore _firestore;

  CommentRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('comments');

  /// Watch all comments for a project
  Stream<List<Comment>> watchProjectComments(String projectId) {
    return _collection
        .where('projectId', isEqualTo: projectId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Comment.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Get comments count for a project
  Future<int> getCommentsCount(String projectId) async {
    final snapshot = await _collection
        .where('projectId', isEqualTo: projectId)
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  /// Add a new comment
  Future<Comment> addComment({
    required String projectId,
    required String userId,
    required String userDisplayName,
    String? userEmail,
    required String content,
    String? parentId,
    List<String> mentions = const [],
  }) async {
    final docRef = _collection.doc();
    final comment = Comment(
      id: docRef.id,
      projectId: projectId,
      userId: userId,
      userDisplayName: userDisplayName,
      userEmail: userEmail,
      content: content,
      parentId: parentId,
      mentions: mentions,
      createdAt: DateTime.now(),
    );

    await docRef.set(comment.toMap());
    return comment;
  }

  /// Update a comment
  Future<void> updateComment(String commentId, String newContent) async {
    await _collection.doc(commentId).update({
      'content': newContent,
      'updatedAt': FieldValue.serverTimestamp(),
      'isEdited': true,
    });
  }

  /// Delete a comment
  Future<void> deleteComment(String commentId) async {
    // Also delete all replies
    final replies = await _collection
        .where('parentId', isEqualTo: commentId)
        .get();

    final batch = _firestore.batch();
    batch.delete(_collection.doc(commentId));
    for (final reply in replies.docs) {
      batch.delete(reply.reference);
    }
    await batch.commit();
  }
}

/// Provider for comment repository
final commentRepositoryProvider = Provider<CommentRepository>((ref) {
  return CommentRepository(FirebaseFirestore.instance);
});

/// Stream provider for project comments
final projectCommentsProvider =
    StreamProvider.family<List<Comment>, String>((ref, projectId) {
  final repository = ref.watch(commentRepositoryProvider);
  return repository.watchProjectComments(projectId);
});

/// Provider for comments count
final commentsCountProvider =
    FutureProvider.family<int, String>((ref, projectId) {
  final repository = ref.watch(commentRepositoryProvider);
  return repository.getCommentsCount(projectId);
});

// ============================================================================
// NOTIFICATIONS
// ============================================================================

/// Repository for notification operations
class NotificationRepository {
  final FirebaseFirestore _firestore;

  NotificationRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('notifications');

  /// Watch notifications for a user
  Stream<List<AppNotification>> watchUserNotifications(String userId) {
    return _collection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppNotification.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Get unread notifications count
  Stream<int> watchUnreadCount(String userId) {
    return _collection
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Create a notification
  Future<void> createNotification({
    required String userId,
    required NotificationType type,
    String? projectId,
    String? projectName,
    required String message,
    String? triggeredByUserId,
    String? triggeredByUserName,
    Map<String, dynamic>? metadata,
  }) async {
    final notification = AppNotification(
      id: '',
      userId: userId,
      type: type,
      projectId: projectId,
      projectName: projectName,
      message: message,
      triggeredByUserId: triggeredByUserId,
      triggeredByUserName: triggeredByUserName,
      createdAt: DateTime.now(),
      metadata: metadata,
    );

    await _collection.add(notification.toMap());
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    await _collection.doc(notificationId).update({'isRead': true});
  }

  /// Mark all notifications as read for a user
  Future<void> markAllAsRead(String userId) async {
    final unread = await _collection
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    await _collection.doc(notificationId).delete();
  }

  /// Delete all notifications for a user
  Future<void> deleteAllNotifications(String userId) async {
    final notifications = await _collection
        .where('userId', isEqualTo: userId)
        .get();

    final batch = _firestore.batch();
    for (final doc in notifications.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  /// Notify users about a status change
  Future<void> notifyStatusChange({
    required String projectId,
    required String projectName,
    required String newStatus,
    required String changedByUserId,
    required String changedByUserName,
    required List<String> notifyUserIds,
  }) async {
    for (final userId in notifyUserIds) {
      if (userId != changedByUserId) {
        await createNotification(
          userId: userId,
          type: NotificationType.statusChange,
          projectId: projectId,
          projectName: projectName,
          message: 'Project "$projectName" status changed to $newStatus',
          triggeredByUserId: changedByUserId,
          triggeredByUserName: changedByUserName,
        );
      }
    }
  }

  /// Notify users about a mention
  Future<void> notifyMention({
    required String projectId,
    required String projectName,
    required String mentionedByUserId,
    required String mentionedByUserName,
    required List<String> mentionedUserIds,
  }) async {
    for (final userId in mentionedUserIds) {
      await createNotification(
        userId: userId,
        type: NotificationType.mention,
        projectId: projectId,
        projectName: projectName,
        message: '$mentionedByUserName mentioned you in a comment on "$projectName"',
        triggeredByUserId: mentionedByUserId,
        triggeredByUserName: mentionedByUserName,
      );
    }
  }

  /// Notify approvers about pending approval
  Future<void> notifyApprovalRequest({
    required String projectId,
    required String projectName,
    required String requestedByUserId,
    required String requestedByUserName,
    required List<String> approverUserIds,
  }) async {
    for (final userId in approverUserIds) {
      await createNotification(
        userId: userId,
        type: NotificationType.approvalRequest,
        projectId: projectId,
        projectName: projectName,
        message: 'Project "$projectName" is waiting for your approval',
        triggeredByUserId: requestedByUserId,
        triggeredByUserName: requestedByUserName,
      );
    }
  }
}

/// Provider for notification repository
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(FirebaseFirestore.instance);
});

/// Stream provider for user notifications
final userNotificationsProvider =
    StreamProvider<List<AppNotification>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);

  final repository = ref.watch(notificationRepositoryProvider);
  return repository.watchUserNotifications(user.uid);
});

/// Stream provider for unread notifications count
final unreadNotificationsCountProvider = StreamProvider<int>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(0);

  final repository = ref.watch(notificationRepositoryProvider);
  return repository.watchUnreadCount(user.uid);
});

// ============================================================================
// ATTACHMENTS
// ============================================================================

/// Repository for attachment operations
class AttachmentRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  AttachmentRepository(this._firestore, this._storage);

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('attachments');

  Reference get _storageRef => _storage.ref().child('attachments');

  /// Watch attachments for a project
  Stream<List<Attachment>> watchProjectAttachments(String projectId) {
    return _collection
        .where('projectId', isEqualTo: projectId)
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Attachment.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Get attachments count for a project
  Future<int> getAttachmentsCount(String projectId) async {
    final snapshot = await _collection
        .where('projectId', isEqualTo: projectId)
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  /// Upload a file and create attachment record
  Future<Attachment> uploadAttachment({
    required String projectId,
    required File file,
    required String fileName,
    required String uploadedByUserId,
    required String uploadedByUserName,
    String? description,
  }) async {
    // Create unique storage path
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final storagePath = '$projectId/$timestamp-$fileName';
    final fileRef = _storageRef.child(storagePath);

    // Upload file
    final uploadTask = await fileRef.putFile(file);
    final fileUrl = await uploadTask.ref.getDownloadURL();
    final fileSize = await file.length();

    // Get file type from extension
    final extension = fileName.split('.').last;
    final type = AttachmentType.fromExtension(extension);

    // Create Firestore record
    final docRef = _collection.doc();
    final attachment = Attachment(
      id: docRef.id,
      projectId: projectId,
      fileName: fileName,
      fileUrl: fileUrl,
      storagePath: storagePath,
      type: type,
      fileSize: fileSize,
      uploadedByUserId: uploadedByUserId,
      uploadedByUserName: uploadedByUserName,
      uploadedAt: DateTime.now(),
      description: description,
    );

    await docRef.set(attachment.toMap());
    return attachment;
  }

  /// Upload from bytes (for web)
  Future<Attachment> uploadAttachmentFromBytes({
    required String projectId,
    required List<int> bytes,
    required String fileName,
    required String uploadedByUserId,
    required String uploadedByUserName,
    String? description,
  }) async {
    // Create unique storage path
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final storagePath = '$projectId/$timestamp-$fileName';
    final fileRef = _storageRef.child(storagePath);

    // Upload bytes
    final uploadTask = await fileRef.putData(
      Uint8List.fromList(bytes),
      SettableMetadata(contentType: _getContentType(fileName)),
    );
    final fileUrl = await uploadTask.ref.getDownloadURL();

    // Get file type from extension
    final extension = fileName.split('.').last;
    final type = AttachmentType.fromExtension(extension);

    // Create Firestore record
    final docRef = _collection.doc();
    final attachment = Attachment(
      id: docRef.id,
      projectId: projectId,
      fileName: fileName,
      fileUrl: fileUrl,
      storagePath: storagePath,
      type: type,
      fileSize: bytes.length,
      uploadedByUserId: uploadedByUserId,
      uploadedByUserName: uploadedByUserName,
      uploadedAt: DateTime.now(),
      description: description,
    );

    await docRef.set(attachment.toMap());
    return attachment;
  }

  /// Delete an attachment
  Future<void> deleteAttachment(Attachment attachment) async {
    // Delete from storage
    try {
      await _storageRef.child(attachment.storagePath).delete();
    } catch (_) {
      // File might already be deleted
    }

    // Delete Firestore record
    await _collection.doc(attachment.id).delete();
  }

  /// Update attachment description
  Future<void> updateDescription(String attachmentId, String description) async {
    await _collection.doc(attachmentId).update({'description': description});
  }

  String _getContentType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
      case 'docx':
        return 'application/msword';
      case 'xls':
      case 'xlsx':
        return 'application/vnd.ms-excel';
      case 'ppt':
      case 'pptx':
        return 'application/vnd.ms-powerpoint';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'gif':
        return 'image/gif';
      default:
        return 'application/octet-stream';
    }
  }
}

/// Provider for attachment repository
final attachmentRepositoryProvider = Provider<AttachmentRepository>((ref) {
  return AttachmentRepository(
    FirebaseFirestore.instance,
    FirebaseStorage.instance,
  );
});

/// Stream provider for project attachments
final projectAttachmentsProvider =
    StreamProvider.family<List<Attachment>, String>((ref, projectId) {
  final repository = ref.watch(attachmentRepositoryProvider);
  return repository.watchProjectAttachments(projectId);
});

/// Provider for attachments count
final attachmentsCountProvider =
    FutureProvider.family<int, String>((ref, projectId) {
  final repository = ref.watch(attachmentRepositoryProvider);
  return repository.getAttachmentsCount(projectId);
});

// ============================================================================
// USER SEARCH (for @mentions)
// ============================================================================

/// Provider for searching users by name or email
final userSearchProvider =
    FutureProvider.family<List<AppUser>, String>((ref, query) async {
  if (query.isEmpty || query.length < 2) return [];

  final usersAsync = ref.watch(allUsersStreamProvider);

  return usersAsync.whenOrNull(
    data: (users) {
      final lowerQuery = query.toLowerCase();
      return users
          .where((user) =>
              user.isActive &&
              ((user.displayName?.toLowerCase().contains(lowerQuery) ?? false) ||
                  user.email.toLowerCase().contains(lowerQuery)))
          .take(10)
          .toList();
    },
  ) ?? [];
});
