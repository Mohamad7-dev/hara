import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/post_provider.dart';
import '../../models/user_model.dart';
import '../../widgets/post_card.dart';
import '../delivery/delivery_registration_screen.dart';
import '../orders/order_screen.dart';
import '../home/home_screen.dart' show AddProductScreen;
import '../favorites/favorites_screen.dart';
import '../notifications/notifications_screen.dart';
import '../../widgets/page_header.dart';

class ProfileScreen extends StatelessWidget {
  final Function(String)? onNavigate;

  const ProfileScreen({super.key, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    if (user == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('الرجاء تسجيل الدخول', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pushReplacementNamed('/login'),
              child: const Text('تسجيل الدخول'),
            ),
          ],
        ),
      );
    }

    final posts = context.watch<PostProvider>().posts;
    final myPosts = posts.where((p) => p.author == user.name).toList();
    final otherPosts = posts.where((p) => p.author != user.name).toList();
    final sortedOthers = [...otherPosts]..sort((a, b) => b.time.compareTo(a.time));

    return Column(
      children: [
        PageHeader(
          showBack: false,
          icon: Icons.person_outline,
          title: 'حسابي',
        ),
        if (context.read<AuthProvider>().needsProfile) ...[
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.person_add_alt_1,
                    color: AppColors.accent, size: 22),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'أكمل بياناتك (الصورة، الاسم، رقم الجوال)',
                    style: TextStyle(
                        color: AppColors.textPrimary, fontSize: 13),
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      Navigator.of(context).pushNamed('/profile-setup'),
                  child: const Text('أكمل',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: AppColors.bg2,
                        backgroundImage: (user.photo != null &&
                                user.photo!.isNotEmpty &&
                                user.photo!.startsWith('http'))
                            ? NetworkImage(user.photo!)
                            : null,
                        child: (user.photo == null ||
                                user.photo!.isEmpty ||
                                !user.photo!.startsWith('http'))
                            ? Text(
                                user.name.isNotEmpty
                                    ? user.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 28,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              user.phone,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                            if (user.area != null) ...[
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined,
                                      size: 14, color: AppColors.accent),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      user.area!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _roleLabel(user),
                                style: const TextStyle(
                                  color: AppColors.accent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _menuCard(
                  context,
                  Icons.receipt_long_outlined,
                  'طلباتي',
                  'تتبّع طلباتي وحالتها',
                  () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const OrderScreen()),
                  ),
                ),
                _menuCard(
                  context,
                  Icons.campaign_outlined,
                  'نشر إعلان',
                  'أضف منتجاً أو خدمة للبيع',
                  () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AddProductScreen()),
                  ),
                ),
                _menuCard(
                  context,
                  Icons.favorite_border,
                  'المفضلة',
                  'منتجاتي المحفوظة',
                  () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const FavoritesScreen()),
                  ),
                ),
                _menuCard(
                  context,
                  Icons.notifications_none_outlined,
                  'الإشعارات',
                  'آخر التحديثات والتنبيهات',
                  () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                  ),
                ),
                if (user.userType == 'delivery') ...[
                  _menuCard(
                    context,
                    Icons.motorcycle_outlined,
                    'لوحة التوصيل',
                    'الطلبات القريبة منك',
                    () => onNavigate?.call('delivery'),
                  ),
                  if (user.deliveryAreas == null || user.deliveryAreas!.isEmpty)
                    _menuCard(
                      context,
                      Icons.add_location_outlined,
                      'تسجيل مناطق التوصيل',
                      'حدّد منطقتك وأجرة التوصيل',
                      () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const DeliveryRegistrationScreen()),
                      ),
                    ),
                ] else
                  _menuCard(
                    context,
                    Icons.delivery_dining_outlined,
                    'انضم للتوصيل',
                    'سجّل نفسك كموصل واستقبل الطلبات',
                    () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const DeliveryRegistrationScreen()),
                    ),
                  ),
                if (user.userType == 'admin')
                  _menuCard(
                    context,
                    Icons.admin_panel_settings_outlined,
                    'لوحة الإدارة',
                    'إدارة المستخدمين والمنتجات',
                    () => onNavigate?.call('admin'),
                  ),
                const SizedBox(height: 22),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'المنشورات',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (myPosts.isNotEmpty) ...[
                  _groupHeader('منشوراتي (${myPosts.length})'),
                  for (final p in myPosts) PostCard(post: p),
                ],
                _groupHeader('منشورات الآخرين (${sortedOthers.length})'),
                if (sortedOthers.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'لا توجد منشورات بعد',
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textMuted),
                    ),
                  )
                else
                  for (final p in sortedOthers) PostCard(post: p),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      auth.logout();
                      Navigator.of(context).pushReplacementNamed('/login');
                    },
                    icon: const Icon(Icons.logout, color: AppColors.error),
                    label: const Text('تسجيل الخروج',
                        style: TextStyle(color: AppColors.error)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _roleLabel(UserModel user) {
    switch (user.userType) {
      case 'delivery':
        return 'موصل';
      case 'admin':
        return 'أدمن';
      default:
        return 'مستخدم · بيع وشراء';
    }
  }

  Widget _groupHeader(String title) {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.accent,
          ),
        ),
      ),
    );
  }

  Widget _menuCard(BuildContext context, IconData icon, String title,
      String subtitle, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.bg2,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_left, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }
}
