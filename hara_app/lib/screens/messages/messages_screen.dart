import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../providers/chat_provider.dart';
import '../../utils/format.dart';
import 'chat_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) context.read<ChatProvider>().refresh();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    final convs = chat.chats;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                const Icon(Icons.forum_outlined, color: AppColors.primary, size: 26),
                const SizedBox(width: 10),
                const Text(
                  'الرسائل',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                if (chat.unreadTotal > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${chat.unreadTotal}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: convs.isEmpty
                ? _emptyState(context)
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    itemCount: convs.length,
                    separatorBuilder: (_, i) => const Divider(
                      height: 1,
                      indent: 78,
                    ),
                    itemBuilder: (context, i) => _convRow(context, convs[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.forum_outlined,
                size: 64, color: AppColors.textMuted),
            const SizedBox(height: 14),
            const Text(
              'لا توجد محادثات بعد',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'اضغط على «تواصل» في أي إعلان أو خدمة لبدء محادثة',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _convRow(BuildContext context, conv) {
    final lm = conv.lastMessage;
    final preview = lm == null
        ? 'لا توجد رسائل بعد'
        : lm.isMine
            ? 'أنت: ${lm.text.isEmpty ? '📷 صورة' : lm.text}'
            : lm.text.isEmpty
                ? '📷 صورة'
                : lm.text;
    return InkWell(
      onTap: () {
        context.read<ChatProvider>().markRead(conv.name);
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ChatScreen(name: conv.name)),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.bg2,
                shape: BoxShape.circle,
              ),
              child: Icon(chatIcon(conv.iconKey),
                  color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conv.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14.5,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    preview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: conv.unread > 0
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontWeight: conv.unread > 0 ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  chatTime(conv.lastTime),
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textMuted),
                ),
                if (conv.unread > 0) ...[
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${conv.unread > 9 ? '9+' : conv.unread}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
