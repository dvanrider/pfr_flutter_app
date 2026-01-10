import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/comment.dart';
import '../../data/models/app_user.dart';
import '../../providers/collaboration_providers.dart';
import '../../providers/auth_providers.dart';
import '../../providers/user_management_providers.dart';

/// Widget for displaying and managing comments on a project
class CommentsSection extends ConsumerStatefulWidget {
  final String projectId;
  final String projectName;

  const CommentsSection({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  @override
  ConsumerState<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends ConsumerState<CommentsSection> {
  final _commentController = TextEditingController();
  final _focusNode = FocusNode();
  String? _replyingToId;
  String? _replyingToUser;
  bool _showMentionSuggestions = false;
  String _mentionQuery = '';
  List<AppUser> _mentionSuggestions = [];

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(projectCommentsProvider(widget.projectId));
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.chat_bubble_outline, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Comments & Discussion',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                commentsAsync.when(
                  data: (comments) => Text(
                    '${comments.length} comment${comments.length != 1 ? 's' : ''}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
            const Divider(height: 24),

            // Comment input
            _buildCommentInput(),

            const SizedBox(height: 16),

            // Comments list
            commentsAsync.when(
              data: (comments) {
                if (comments.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(Icons.forum_outlined, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text(
                            'No comments yet',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Be the first to start the discussion',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Organize comments into threads
                final rootComments = comments.where((c) => c.parentId == null).toList();
                final replies = <String, List<Comment>>{};
                for (final comment in comments.where((c) => c.parentId != null)) {
                  replies.putIfAbsent(comment.parentId!, () => []).add(comment);
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: rootComments.length,
                  itemBuilder: (context, index) {
                    final comment = rootComments[index];
                    final commentReplies = replies[comment.id] ?? [];
                    return _buildCommentThread(comment, commentReplies);
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
                  child: Text('Error loading comments: $e'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentInput() {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return const Text('Please log in to comment');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_replyingToId != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              children: [
                Icon(Icons.reply, size: 16, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  'Replying to $_replyingToUser',
                  style: TextStyle(color: Colors.blue.shade700, fontSize: 13),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: () => setState(() {
                    _replyingToId = null;
                    _replyingToUser = null;
                  }),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        TextField(
          controller: _commentController,
          focusNode: _focusNode,
          maxLines: 3,
          minLines: 1,
          decoration: InputDecoration(
            hintText: _replyingToId != null
                ? 'Write a reply...'
                : 'Write a comment... Use @ to mention someone',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.vertical(
                top: _replyingToId != null ? Radius.zero : const Radius.circular(8),
                bottom: const Radius.circular(8),
              ),
            ),
            suffixIcon: IconButton(
              icon: const Icon(Icons.send),
              onPressed: _submitComment,
            ),
          ),
          onChanged: _handleTextChange,
        ),
        if (_showMentionSuggestions && _mentionSuggestions.isNotEmpty)
          _buildMentionSuggestions(),
      ],
    );
  }

  Widget _buildMentionSuggestions() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _mentionSuggestions.length,
        itemBuilder: (context, index) {
          final user = _mentionSuggestions[index];
          return ListTile(
            dense: true,
            leading: CircleAvatar(
              radius: 16,
              child: Text(
                user.displayName?.isNotEmpty == true
                    ? user.displayName![0].toUpperCase()
                    : user.email[0].toUpperCase(),
                style: const TextStyle(fontSize: 12),
              ),
            ),
            title: Text(user.displayName ?? user.email),
            subtitle: user.displayName != null ? Text(user.email, style: const TextStyle(fontSize: 11)) : null,
            onTap: () => _insertMention(user),
          );
        },
      ),
    );
  }

  void _handleTextChange(String text) {
    // Check for @ mentions
    final cursorPos = _commentController.selection.baseOffset;
    if (cursorPos > 0) {
      final textBeforeCursor = text.substring(0, cursorPos);
      final lastAtIndex = textBeforeCursor.lastIndexOf('@');

      if (lastAtIndex != -1) {
        final query = textBeforeCursor.substring(lastAtIndex + 1);
        if (!query.contains(' ') && query.isNotEmpty) {
          _searchUsers(query);
          return;
        }
      }
    }

    setState(() {
      _showMentionSuggestions = false;
      _mentionQuery = '';
    });
  }

  Future<void> _searchUsers(String query) async {
    setState(() {
      _mentionQuery = query;
      _showMentionSuggestions = true;
    });

    final users = await ref.read(userSearchProvider(query).future);
    if (mounted && _mentionQuery == query) {
      setState(() {
        _mentionSuggestions = users;
      });
    }
  }

  void _insertMention(AppUser user) {
    final text = _commentController.text;
    final cursorPos = _commentController.selection.baseOffset;
    final textBeforeCursor = text.substring(0, cursorPos);
    final lastAtIndex = textBeforeCursor.lastIndexOf('@');

    final newText = '${text.substring(0, lastAtIndex)}@${user.displayName ?? user.email} ${text.substring(cursorPos)}';

    _commentController.text = newText;
    _commentController.selection = TextSelection.collapsed(
      offset: lastAtIndex + (user.displayName ?? user.email).length + 2,
    );

    setState(() {
      _showMentionSuggestions = false;
      _mentionQuery = '';
    });
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    final user = ref.read(currentUserProvider);
    final userProfile = ref.read(userProfileProvider).valueOrNull;
    if (user == null) return;

    try {
      final repository = ref.read(commentRepositoryProvider);
      final mentions = MentionParser.extractMentions(content);

      await repository.addComment(
        projectId: widget.projectId,
        userId: user.uid,
        userDisplayName: userProfile?.displayName ?? user.displayName ?? user.email ?? 'Unknown',
        userEmail: user.email,
        content: content,
        parentId: _replyingToId,
        mentions: mentions,
      );

      // Notify mentioned users
      if (mentions.isNotEmpty) {
        final allUsersValue = ref.read(allUsersStreamProvider).valueOrNull;
        if (allUsersValue != null && allUsersValue.isNotEmpty) {
          final mentionedUserIds = allUsersValue
              .where((u) => mentions.any((m) =>
                  u.displayName?.toLowerCase() == m.toLowerCase() ||
                  u.email.toLowerCase() == m.toLowerCase()))
              .map((u) => u.uid)
              .toList();

          await ref.read(notificationRepositoryProvider).notifyMention(
            projectId: widget.projectId,
            projectName: widget.projectName,
            mentionedByUserId: user.uid,
            mentionedByUserName: userProfile?.displayName ?? user.email ?? 'Someone',
            mentionedUserIds: mentionedUserIds,
          );
        }
      }

      _commentController.clear();
      setState(() {
        _replyingToId = null;
        _replyingToUser = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error posting comment: $e')),
        );
      }
    }
  }

  Widget _buildCommentThread(Comment comment, List<Comment> replies) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCommentTile(comment, isReply: false),
        if (replies.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 40),
            child: Column(
              children: replies.map((reply) => _buildCommentTile(reply, isReply: true)).toList(),
            ),
          ),
        const Divider(height: 24),
      ],
    );
  }

  Widget _buildCommentTile(Comment comment, {required bool isReply}) {
    final currentUser = ref.watch(currentUserProvider);
    final isOwner = currentUser?.uid == comment.userId;
    final dateFormat = DateFormat('MMM d, yyyy h:mm a');

    return Padding(
      padding: EdgeInsets.only(top: isReply ? 8 : 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: isReply ? 14 : 18,
            backgroundColor: Colors.blue.shade100,
            child: Text(
              comment.initials,
              style: TextStyle(
                fontSize: isReply ? 10 : 12,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.userDisplayName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      dateFormat.format(comment.createdAt),
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                    ),
                    if (comment.isEdited) ...[
                      const SizedBox(width: 4),
                      Text(
                        '(edited)',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                _buildCommentContent(comment.content),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (!isReply)
                      TextButton.icon(
                        onPressed: () => setState(() {
                          _replyingToId = comment.id;
                          _replyingToUser = comment.userDisplayName;
                          _focusNode.requestFocus();
                        }),
                        icon: const Icon(Icons.reply, size: 16),
                        label: const Text('Reply'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    if (isOwner) ...[
                      TextButton.icon(
                        onPressed: () => _editComment(comment),
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Edit'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _deleteComment(comment),
                        icon: const Icon(Icons.delete, size: 16),
                        label: const Text('Delete'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentContent(String content) {
    // Simple @mention highlighting
    final mentionRegex = RegExp(r'@(\w+(?:\s+\w+)?)');
    final spans = <TextSpan>[];
    int lastEnd = 0;

    for (final match in mentionRegex.allMatches(content)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: content.substring(lastEnd, match.start)));
      }
      spans.add(TextSpan(
        text: match.group(0),
        style: TextStyle(
          color: Colors.blue.shade700,
          fontWeight: FontWeight.w500,
        ),
      ));
      lastEnd = match.end;
    }

    if (lastEnd < content.length) {
      spans.add(TextSpan(text: content.substring(lastEnd)));
    }

    return RichText(
      text: TextSpan(
        style: const TextStyle(color: Colors.black87, fontSize: 14),
        children: spans.isEmpty ? [TextSpan(text: content)] : spans,
      ),
    );
  }

  Future<void> _editComment(Comment comment) async {
    final controller = TextEditingController(text: comment.content);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Comment'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Edit your comment...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result.trim().isNotEmpty && result != comment.content) {
      try {
        await ref.read(commentRepositoryProvider).updateComment(comment.id, result.trim());
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating comment: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteComment(Comment comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment? This action cannot be undone.'),
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
        await ref.read(commentRepositoryProvider).deleteComment(comment.id);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting comment: $e')),
          );
        }
      }
    }
  }
}
