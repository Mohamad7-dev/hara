import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/page_header.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().currentUser;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const PageHeader(
            icon: Icons.admin_panel_settings_outlined,
            title: 'لوحة الإدارة',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
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
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.bg2,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.dashboard_outlined,
                              color: AppColors.accent, size: 26),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'لوحة التحكم',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'مرحباً، ${user?.name ?? ""}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'إحصائيات سريعة',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _statCard('المستخدمين', '0', Icons.people,
                          AppColors.primary),
                      const SizedBox(width: 12),
                      _statCard('المنتجات', '0', Icons.inventory_2,
                          AppColors.accent),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _statCard('الطلبات', '0', Icons.receipt_long,
                          AppColors.warning),
                      const SizedBox(width: 12),
                      _statCard('الموصلين', '0', Icons.motorcycle,
                          AppColors.secondary),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'إدارة',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _adminCard(context, Icons.people_outlined, 'إدارة المستخدمين',
                      'عرض وإدارة جميع المستخدمين'),
                  _adminCard(context, Icons.inventory_outlined, 'إدارة المنتجات',
                      'مراجعة وتعديل المنتجات'),
                  _adminCard(context, Icons.receipt_outlined, 'إدارة الطلبات',
                      'متابعة جميع الطلبات'),
                  _adminCard(context, Icons.monetization_on_outlined, 'الأرباح',
                      'إحصائيات الأرباح والعمولات'),
                  _adminCard(context, Icons.settings_outlined,
                      'إعدادات التطبيق', 'تعديل الإعدادات العامة'),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: color),
            ),
            Text(title,
                style:
                    const TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _adminCard(BuildContext context, IconData icon, String title,
      String subtitle) {
    return InkWell(
      onTap: () {},
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
