import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Types of attachments
enum AttachmentType {
  document('Document', 'doc'),
  spreadsheet('Spreadsheet', 'xls'),
  pdf('PDF', 'pdf'),
  image('Image', 'img'),
  presentation('Presentation', 'ppt'),
  other('Other', 'file');

  final String displayName;
  final String shortName;

  const AttachmentType(this.displayName, this.shortName);

  /// Get type from file extension
  static AttachmentType fromExtension(String extension) {
    final ext = extension.toLowerCase().replaceAll('.', '');
    switch (ext) {
      case 'doc':
      case 'docx':
      case 'txt':
      case 'rtf':
        return AttachmentType.document;
      case 'xls':
      case 'xlsx':
      case 'csv':
        return AttachmentType.spreadsheet;
      case 'pdf':
        return AttachmentType.pdf;
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
      case 'bmp':
      case 'webp':
        return AttachmentType.image;
      case 'ppt':
      case 'pptx':
        return AttachmentType.presentation;
      default:
        return AttachmentType.other;
    }
  }
}

/// Represents a file attachment on a project
class Attachment extends Equatable {
  final String id;
  final String projectId;
  final String fileName;
  final String fileUrl;
  final String storagePath;
  final AttachmentType type;
  final int fileSize; // in bytes
  final String uploadedByUserId;
  final String uploadedByUserName;
  final DateTime uploadedAt;
  final String? description;

  const Attachment({
    required this.id,
    required this.projectId,
    required this.fileName,
    required this.fileUrl,
    required this.storagePath,
    required this.type,
    required this.fileSize,
    required this.uploadedByUserId,
    required this.uploadedByUserName,
    required this.uploadedAt,
    this.description,
  });

  /// Create from Firestore document
  factory Attachment.fromMap(Map<String, dynamic> map, String id) {
    return Attachment(
      id: id,
      projectId: map['projectId'] as String? ?? '',
      fileName: map['fileName'] as String? ?? 'Unknown',
      fileUrl: map['fileUrl'] as String? ?? '',
      storagePath: map['storagePath'] as String? ?? '',
      type: _parseAttachmentType(map['type'] as String?),
      fileSize: map['fileSize'] as int? ?? 0,
      uploadedByUserId: map['uploadedByUserId'] as String? ?? '',
      uploadedByUserName: map['uploadedByUserName'] as String? ?? 'Unknown',
      uploadedAt: map['uploadedAt'] != null
          ? (map['uploadedAt'] as Timestamp).toDate()
          : DateTime.now(),
      description: map['description'] as String?,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'projectId': projectId,
      'fileName': fileName,
      'fileUrl': fileUrl,
      'storagePath': storagePath,
      'type': type.name,
      'fileSize': fileSize,
      'uploadedByUserId': uploadedByUserId,
      'uploadedByUserName': uploadedByUserName,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
      'description': description,
    };
  }

  Attachment copyWith({
    String? id,
    String? projectId,
    String? fileName,
    String? fileUrl,
    String? storagePath,
    AttachmentType? type,
    int? fileSize,
    String? uploadedByUserId,
    String? uploadedByUserName,
    DateTime? uploadedAt,
    String? description,
  }) {
    return Attachment(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      fileName: fileName ?? this.fileName,
      fileUrl: fileUrl ?? this.fileUrl,
      storagePath: storagePath ?? this.storagePath,
      type: type ?? this.type,
      fileSize: fileSize ?? this.fileSize,
      uploadedByUserId: uploadedByUserId ?? this.uploadedByUserId,
      uploadedByUserName: uploadedByUserName ?? this.uploadedByUserName,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      description: description ?? this.description,
    );
  }

  static AttachmentType _parseAttachmentType(String? type) {
    if (type == null) return AttachmentType.other;
    try {
      return AttachmentType.values.firstWhere(
        (e) => e.name.toLowerCase() == type.toLowerCase(),
      );
    } catch (_) {
      return AttachmentType.other;
    }
  }

  /// Get human-readable file size
  String get fileSizeFormatted {
    if (fileSize < 1024) {
      return '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else if (fileSize < 1024 * 1024 * 1024) {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  /// Get file extension
  String get extension {
    final parts = fileName.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }

  @override
  List<Object?> get props => [
        id,
        projectId,
        fileName,
        fileUrl,
        storagePath,
        type,
        fileSize,
        uploadedByUserId,
        uploadedByUserName,
        uploadedAt,
        description,
      ];
}
