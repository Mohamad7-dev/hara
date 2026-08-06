import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/colors.dart';
import '../models/post_model.dart';
import '../providers/post_provider.dart';
import '../providers/chat_provider.dart';
import '../screens/messages/chat_screen.dart';
import '../utils/format.dart';
import 'comments_sheet.dart';

class PostCard extends StatelessWidget {
  final PostModel post;

  const PostCard({super.key, required this.post});

  IconData get _avatarIcon {
    switch (post.avatarKey) {
      case 'store':
        return Icons.storefront;
      case 'motor':
        return Icons.moped;
      case 'tool':
        return Icons.build;
      default:
        return Icons.person;
    }
  }

  Color get _categoryColor {
    switch (post.category) {
      case 'عرض':
        return AppColors.accent;
      case 'سؤال':
        return AppColors.primary;
      case 'مشكلة':
        return AppColors.error;
      case 'تحديث':
        return AppColors.success;
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.6),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.bg2,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_avatarIcon,
                      color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${post.role} • ${chatTime(post.time)}',
                        style: const TextStyle(
                            fontSize: 11.5, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _categoryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    post.category,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _categoryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Text(
              post.text,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.6,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (post.hasImage)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Container(
                height: 130,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.85),
                      AppColors.accent.withValues(alpha: 0.75),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Icon(
                    _categoryIcon,
                    color: Colors.white.withValues(alpha: 0.9),
                    size: 44,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                const Icon(Icons.favorite, size: 14, color: AppColors.error),
                const SizedBox(width: 4),
                Text(
                  '${post.likes}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(width: 12),
                Text(
                  '${post.comments} تعليق',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Expanded(
                  child: _action(
                    context,
                    post.liked ? Icons.favorite : Icons.favorite_border,
                    post.liked ? AppColors.error : AppColors.textMuted,
                    post.liked ? 'معجب' : 'إعجاب',
                    () {
                      final provider = context.read<PostProvider>();
                      provider.toggleLike(post.id);
                    },
                  ),
                ),
                Expanded(
                  child: _action(
                    context,
                    Icons.mode_comment_outlined,
                    AppColors.textMuted,
                    'تعليق',
                    () => showCommentsSheet(
                      context,
                      kind: 'post',
                      targetId: post.id,
                      title: 'التعليقات',
                      authorName: post.author,
                    ),
                  ),
                ),
                Expanded(
                  child: _action(
                    context,
                    Icons.mail_outline,
                    AppColors.textMuted,
                    'مراسلة',
                    () {
                      context.read<ChatProvider>().ensure(
                            post.author,
                            role: post.role,
                            iconKey: post.avatarKey,
                          );
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => ChatScreen(name: post.author)),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData get _categoryIcon {
    switch (post.category) {
      case 'عرض':
        return Icons.local_offer_outlined;
      case 'سؤال':
        return Icons.help_outline;
      case 'مشكلة':
        return Icons.report_problem_outlined;
      case 'تحديث':
        return Icons.campaign_outlined;
      default:
        return Icons.article_outlined;
    }
  }

  Widget _action(BuildContext context, IconData icon, Color color, String label,
      VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(fontSize: 12.5, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
