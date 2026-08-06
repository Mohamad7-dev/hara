import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/colors.dart';
import '../../providers/notifications_provider.dart';
import '../../utils/format.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationsProvider>().markAllRead();
    });
  }

  IconData _icon(String key) {
    switch (key) {
      case 'order':
        return Icons.receipt_long_outlined;
      case 'message':
        return Icons.chat_bubble_outline;
      case 'promo':
        return Icons.campaign_outlined;
      case 'delivery':
        return Icons.moped;
      case 'post':
        return Icons.article_outlined;
      case 'like':
        return Icons.favorite;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = context.watch<NotificationsProvider>().items;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('الإشعارات'),
        backgroundColor: AppColors.card,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.notifications_none,
                      size: 64, color: AppColors.textMuted),
                  const SizedBox(height: 14),
                  const Text(
                    'لا توجد إشعارات',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'ستصلك الإشعارات هنا عند وجود جديد',
                    style:
                        TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: items.length,
              separatorBuilder: (_, i) => const Divider(
                height: 1,
                indent: 72,
              ),
              itemBuilder: (context, i) {
                final n = items[i];
                final t = DateTime.parse(n['time'].toString());
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: AppColors.bg2,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(_icon(n['iconKey'] ?? ''),
                            color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              n['title'] ?? '',
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              n['body'] ?? '',
                              style: const TextStyle(
                                  fontSize: 13, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        chatTime(t),
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
