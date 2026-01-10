import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/attachment.dart';
import '../../providers/collaboration_providers.dart';
import '../../providers/auth_providers.dart';

/// Widget for displaying and managing attachments on a project
class AttachmentsSection extends ConsumerStatefulWidget {
  final String projectId;
  final String projectName;
  final bool canUpload;

  const AttachmentsSection({
    super.key,
    required this.projectId,
    required this.projectName,
    this.canUpload = true,
  });

  @override
  ConsumerState<AttachmentsSection> createState() => _AttachmentsSectionState();
}

class _AttachmentsSectionState extends ConsumerState<AttachmentsSection> {
  bool _isUploading = false;
  double _uploadProgress = 0;

  @override
  Widget build(BuildContext context) {
    final attachmentsAsync = ref.watch(projectAttachmentsProvider(widget.projectId));
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.attach_file, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Documents & Attachments',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                attachmentsAsync.when(
                  data: (attachments) => Text(
                    '${attachments.length} file${attachments.length != 1 ? 's' : ''}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                if (widget.canUpload) ...[
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _isUploading ? null : _uploadFile,
                    icon: _isUploading
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              value: _uploadProgress > 0 ? _uploadProgress : null,
                            ),
                          )
                        : const Icon(Icons.upload_file, size: 18),
                    label: Text(_isUploading ? 'Uploading...' : 'Upload'),
                  ),
                ],
              ],
            ),
            const Divider(height: 24),

            // Attachments list
            attachmentsAsync.when(
              data: (attachments) {
                if (attachments.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(Icons.folder_open, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text(
                            'No attachments yet',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Upload quotes, specs, or supporting documents',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: attachments.length,
                  itemBuilder: (context, index) {
                    final attachment = attachments[index];
                    return _AttachmentTile(
                      attachment: attachment,
                      onDelete: () => _deleteAttachment(attachment),
                      onDownload: () => _downloadAttachment(attachment),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Error loading attachments: $e'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadFile() async {
    final user = ref.read(currentUserProvider);
    final userProfile = ref.read(userProfileProvider).valueOrNull;
    if (user == null) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx',
          'txt', 'csv', 'png', 'jpg', 'jpeg', 'gif',
        ],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.bytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not read file')),
          );
        }
        return;
      }

      // Check file size (max 10MB)
      if (file.size > 10 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File size must be less than 10MB')),
          );
        }
        return;
      }

      setState(() {
        _isUploading = true;
        _uploadProgress = 0;
      });

      final repository = ref.read(attachmentRepositoryProvider);
      await repository.uploadAttachmentFromBytes(
        projectId: widget.projectId,
        bytes: file.bytes!,
        fileName: file.name,
        uploadedByUserId: user.uid,
        uploadedByUserName: userProfile?.displayName ?? user.email ?? 'Unknown',
      );

      // TODO: Could notify project stakeholders about document upload
      // await ref.read(notificationRepositoryProvider).createNotification(...);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Uploaded ${file.name}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading file: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0;
        });
      }
    }
  }

  Future<void> _deleteAttachment(Attachment attachment) async {
    final currentUser = ref.read(currentUserProvider);
    final isOwner = currentUser?.uid == attachment.uploadedByUserId;

    if (!isOwner) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can only delete files you uploaded')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Attachment'),
        content: Text('Are you sure you want to delete "${attachment.fileName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(attachmentRepositoryProvider).deleteAttachment(attachment);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Deleted ${attachment.fileName}')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting file: $e')),
          );
        }
      }
    }
  }

  Future<void> _downloadAttachment(Attachment attachment) async {
    try {
      final uri = Uri.parse(attachment.fileUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open file')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening file: $e')),
        );
      }
    }
  }
}

class _AttachmentTile extends StatelessWidget {
  final Attachment attachment;
  final VoidCallback onDelete;
  final VoidCallback onDownload;

  const _AttachmentTile({
    required this.attachment,
    required this.onDelete,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _getTypeColor(attachment.type).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          _getTypeIcon(attachment.type),
          color: _getTypeColor(attachment.type),
        ),
      ),
      title: Text(
        attachment.fileName,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        '${attachment.fileSizeFormatted} - Uploaded by ${attachment.uploadedByUserName} on ${dateFormat.format(attachment.uploadedAt)}',
        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: onDownload,
            tooltip: 'Download',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: onDelete,
            tooltip: 'Delete',
            color: Colors.red.shade400,
          ),
        ],
      ),
    );
  }

  IconData _getTypeIcon(AttachmentType type) {
    switch (type) {
      case AttachmentType.document:
        return Icons.description;
      case AttachmentType.spreadsheet:
        return Icons.table_chart;
      case AttachmentType.pdf:
        return Icons.picture_as_pdf;
      case AttachmentType.image:
        return Icons.image;
      case AttachmentType.presentation:
        return Icons.slideshow;
      case AttachmentType.other:
        return Icons.insert_drive_file;
    }
  }

  Color _getTypeColor(AttachmentType type) {
    switch (type) {
      case AttachmentType.document:
        return Colors.blue;
      case AttachmentType.spreadsheet:
        return Colors.green;
      case AttachmentType.pdf:
        return Colors.red;
      case AttachmentType.image:
        return Colors.purple;
      case AttachmentType.presentation:
        return Colors.orange;
      case AttachmentType.other:
        return Colors.grey;
    }
  }
}
