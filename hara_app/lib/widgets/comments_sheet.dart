import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/colors.dart';
import '../models/comment_model.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/comment_provider.dart';
import '../providers/product_provider.dart';
import '../screens/messages/chat_screen.dart';
import '../utils/format.dart';
import 'comment_replies.dart';

void showCommentsSheet(
  BuildContext context, {
  required String kind,
  required String targetId,
  required String title,
  String? authorName,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (_) => CommentsSheet(
      kind: kind,
      targetId: targetId,
      title: title,
      authorName: authorName,
    ),
  );
}

class CommentsSheet extends StatefulWidget {
  final String kind; // 'post' | 'product'
  final String targetId;
  final String title;
  final String? authorName;

  const CommentsSheet({
    super.key,
    required this.kind,
    required this.targetId,
    required this.title,
    this.authorName,
  });

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final _ctrl = TextEditingController();
  int _rating = 5;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool get _isProduct => widget.kind == 'product';

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
    final comment = context.read<CommentProvider>();
    await comment.addComment(
      kind: widget.kind,
      targetId: widget.targetId,
      author: user.name,
      role: _roleLabel(user.userType),
      avatarKey: _avatarKey(user.userType),
      text: text,
      rating: _isProduct ? _rating : 0,
    );
    if (_isProduct) {
      context.read<ProductProvider>().addReview(widget.targetId, _rating);
    }
    _ctrl.clear();
    setState(() => _rating = 5);
  }

  @override
  Widget build(BuildContext context) {
    final comments =
        context.watch<CommentProvider>().commentsFor(widget.kind, widget.targetId);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.72,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  const Icon(Icons.mode_comment_outlined,
                      color: AppColors.primary, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.bg2,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${comments.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Expanded(
              child: comments.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isProduct
                                ? Icons.star_border
                                : Icons.chat_bubble_outline,
                            size: 56,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _isProduct
                                ? 'لا توجد تقييمات بعد'
                                : 'لا توجد تعليقات بعد',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isProduct
                                ? 'كن أول من يقيّم هذا المنتج'
                                : 'كن أول من يعلّق',
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      itemCount: comments.length,
                      separatorBuilder: (_, i) => Divider(
                        height: 1,
                        indent: 76,
                        endIndent: 16,
                        color: AppColors.border,
                      ),
                      itemBuilder: (context, i) => _commentRow(comments[i]),
                    ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Column(
                children: [
                  if (_isProduct) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'تقييمك:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        for (var i = 1; i <= 5; i++)
                          IconButton(
                            onPressed: () => setState(() => _rating = i),
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            icon: Icon(
                              i <= _rating
                                  ? Icons.star
                                  : Icons.star_border,
                              size: 24,
                              color: i <= _rating
                                  ? AppColors.accent
                                  : AppColors.textMuted,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.bg2,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: TextField(
                            controller: _ctrl,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _send(),
                            minLines: 1,
                            maxLines: 3,
                            style: const TextStyle(
                                color: AppColors.textPrimary),
                            decoration: InputDecoration(
                              hintText: _isProduct
                                  ? 'اكتب تقييمك هنا...'
                                  : 'اكتب تعليقك هنا...',
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: _send,
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.send_rounded,
                              color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _commentRow(CommentModel c) {
    final currentUser = context.read<AuthProvider>().currentUser;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.bg2,
              shape: BoxShape.circle,
            ),
            child: Icon(chatIcon(c.avatarKey),
                color: AppColors.primary, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.author,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      c.role,
                      style: const TextStyle(
                          fontSize: 11.5, color: AppColors.accent),
                    ),
                    if (c.rating > 0) ...[
                      const SizedBox(width: 8),
                      _stars(c.rating),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  c.text,
                  style: const TextStyle(
                    fontSize: 13.5,
                    height: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                CommentReplies(
                  comment: c,
                  kind: widget.kind,
                  targetId: widget.targetId,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                chatTime(c.time),
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textMuted),
              ),
              if (currentUser != null && currentUser.name != c.author) ...[
                const SizedBox(height: 8),
                _messageButton(c),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _messageButton(CommentModel c) {
    return InkWell(
      onTap: () {
        context
            .read<ChatProvider>()
            .ensure(c.author, role: c.role, iconKey: c.avatarKey);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatScreen(name: c.author),
          ),
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.mail_outline, size: 13, color: AppColors.accent),
            SizedBox(width: 4),
            Text(
              'مراسلة',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stars(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            i <= rating ? Icons.star : Icons.star_border,
            size: 14,
            color: i <= rating ? AppColors.accent : AppColors.textMuted,
          ),
      ],
    );
  }
}
