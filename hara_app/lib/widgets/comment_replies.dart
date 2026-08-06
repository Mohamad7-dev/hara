import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/colors.dart';
import '../models/comment_model.dart';
import '../providers/auth_provider.dart';
import '../providers/comment_provider.dart';
import '../utils/format.dart';

class CommentReplies extends StatefulWidget {
  final CommentModel comment;
  final String kind; // 'post' | 'product'
  final String targetId;

  const CommentReplies({
    super.key,
    required this.comment,
    required this.kind,
    required this.targetId,
  });

  @override
  State<CommentReplies> createState() => _CommentRepliesState();
}

class _CommentRepliesState extends State<CommentReplies> {
  final _ctrl = TextEditingController();
  bool _open = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _roleLabel(String userType) {
    switch (userType) {
      case 'delivery':
        return 'موصل';
      case 'admin':
        return 'أدمن';
      default:
        return 'مستخدم';
    }
  }

  String _avatarKey(String userType) {
    switch (userType) {
      case 'delivery':
        return 'motor';
      case 'admin':
        return 'person';
      default:
        return 'person';
    }
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;
    await context.read<CommentProvider>().addReply(
          kind: widget.kind,
          targetId: widget.targetId,
          commentId: widget.comment.id,
          author: user.name,
          role: _roleLabel(user.userType),
          avatarKey: _avatarKey(user.userType),
          text: text,
        );
    _ctrl.clear();
    setState(() => _open = false);
  }

  @override
  Widget build(BuildContext context) {
    final replies = widget.comment.replies;
    final hasReplies = replies.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasReplies) ...[
          for (final r in replies) _replyRow(r),
        ],
        if (_open) _composer(),
        InkWell(
          onTap: () {
            final user = context.read<AuthProvider>().currentUser;
            if (user == null) return;
            setState(() => _open = !_open);
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.reply_outlined,
                    size: 13, color: AppColors.accent),
                const SizedBox(width: 4),
                Text(
                  hasReplies ? 'رد (${replies.length})' : 'رد',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _composer() {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.bg2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _ctrl,
                autofocus: true,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                minLines: 1,
                maxLines: 3,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'اكتب ردك...',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  isDense: true,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _send,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.send_rounded,
                  color: Colors.white, size: 17),
            ),
          ),
        ],
      ),
    );
  }

  Widget _replyRow(CommentModel r) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, right: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.accentLight,
              shape: BoxShape.circle,
            ),
            child: Icon(chatIcon(r.avatarKey),
                color: AppColors.accent, size: 14),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.bg2,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          r.author,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        chatTime(r.time),
                        style: const TextStyle(
                            fontSize: 10, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    r.text,
                    style: const TextStyle(
                      fontSize: 12.5,
                      height: 1.4,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
