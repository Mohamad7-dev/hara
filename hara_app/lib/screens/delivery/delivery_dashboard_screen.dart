import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../widgets/page_header.dart';
import '../../widgets/hara_loader.dart';

class DeliveryDashboardScreen extends StatefulWidget {
  const DeliveryDashboardScreen({super.key});

  @override
  State<DeliveryDashboardScreen> createState() => _DeliveryDashboardScreenState();
}

class _DeliveryDashboardScreenState extends State<DeliveryDashboardScreen> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      if (user == null) return;
      final areas = (user.deliveryAreas?.isNotEmpty ?? false)
          ? user.deliveryAreas!
          : (user.area != null ? [user.area!] : <String>[]);
      context
          .read<OrderProvider>()
          .loadDeliveryOrders(uid: user.uid, areas: areas);
    });
  }

  void _reload() {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;
    final areas = (user.deliveryAreas?.isNotEmpty ?? false)
        ? user.deliveryAreas!
        : (user.area != null ? [user.area!] : <String>[]);
    context.read<OrderProvider>().loadDeliveryOrders(uid: user.uid, areas: areas);
  }

  Future<void> _accept(OrderModel order) async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;
    await context.read<OrderProvider>().updateOrderStatus(
          order.id,
          'accepted',
          deliveryPersonId: user.uid,
          deliveryPersonName: user.name,
        );
    _reload();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم قبول الطلب'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _startDelivering(OrderModel order) async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;
    await context.read<OrderProvider>().updateOrderStatus(order.id, 'delivering');
    _reload();
  }

  Future<void> _complete(OrderModel order) async {
    await context.read<OrderProvider>().updateOrderStatus(order.id, 'delivered');
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final orderProvider = context.watch<OrderProvider>();

    final available = orderProvider.availableOrders;
    final mine = orderProvider.myDeliveryOrders;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const PageHeader(
            icon: Icons.motorcycle_outlined,
            title: 'لوحة التوصيل',
          ),
          Expanded(
            child: orderProvider.isLoading
                ? const Center(child: HaraLoader())
                : Column(
                    children: [
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.all(16),
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
                              child: const Icon(Icons.motorcycle,
                                  color: AppColors.accent, size: 28),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'مرحباً ${user?.name ?? ""}',
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'مناطقك: ${(user?.deliveryAreas?.isNotEmpty ?? false) ? user!.deliveryAreas!.join('، ') : (user?.area ?? "غير محددة")}',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12.5),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.bg2,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            _tabButton(0, 'طلبات متاحة (${available.length})'),
                            _tabButton(1, 'طلباتي (${mine.length})'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: _tab == 0
                            ? _orderList(available, empty: 'لا توجد طلبات متاحة قريب منك حالياً')
                            : _orderList(mine, empty: 'لم تقبل أي طلب بعد'),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _tabButton(int index, String label) {
    final selected = _tab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.card : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: selected ? AppColors.border : Colors.transparent,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _orderList(List<OrderModel> orders, {required String empty}) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pedal_bike, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(
              empty,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      itemCount: orders.length,
      itemBuilder: (context, index) => _orderCard(orders[index]),
    );
  }

  Widget _orderCard(OrderModel order) {
    final me = context.read<AuthProvider>().currentUser?.uid;
    final chosenMe = order.deliveryPersonId != null && order.deliveryPersonId == me;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: chosenMe ? AppColors.primary : AppColors.border,
          width: chosenMe ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    order.buyerName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (chosenMe) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'اختارك',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                _statusChip(order.status),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    order.buyerAddress,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${order.items.length} منتجات · ${order.total.toStringAsFixed(0)} شيكل',
              style: const TextStyle(
                  color: AppColors.textLight, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.phone_outlined,
                        size: 14, color: AppColors.accent),
                    const SizedBox(width: 4),
                    Text(
                      order.buyerPhone,
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                _actionFor(order),
              ],
            ),
            _paymentBar(order),
          ],
        ),
      ),
    );
  }

  Widget _paymentBar(OrderModel order) {
    final isCash =
        order.paymentMethod == 'كاش' || order.paymentMethod == 'cash';
    final paid = order.paymentStatus == 'paid';
    final canCollect = isCash &&
        !paid &&
        (order.status == 'delivering' || order.status == 'delivered');
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.payments_outlined,
              size: 16,
              color: paid ? AppColors.success : AppColors.warning),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              paid
                  ? 'مدفوع · ${_paymentMethodLabel(order.paymentMethod)}'
                  : 'الدفع: ${_paymentMethodLabel(order.paymentMethod)}',
              style: TextStyle(
                fontSize: 12.5,
                color: paid ? AppColors.success : AppColors.textSecondary,
                fontWeight: paid ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          if (canCollect)
            TextButton(
              onPressed: () => _collectCash(order),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.success,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: const Text('تحصيل المبلغ',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  String _paymentMethodLabel(String m) {
    switch (m) {
      case 'كاش':
      case 'cash':
        return 'كاش عند الاستلام';
      case 'بطاقة':
        return 'بطاقة (إلكتروني)';
      case 'محفظة':
        return 'محفظة (إلكتروني)';
      default:
        return m;
    }
  }

  Future<void> _collectCash(OrderModel order) async {
    await context.read<OrderProvider>().markPaid(order);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تسجيل استلام المبلغ')),
      );
    }
  }

  Widget _actionFor(OrderModel order) {
    switch (order.status) {
      case 'pending':
        return ElevatedButton(
          onPressed: () => _accept(order),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('قبول الطلب'),
        );
      case 'accepted':
        return OutlinedButton(
          onPressed: () => _startDelivering(order),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('بدء التوصيل'),
        );
      case 'delivering':
        return ElevatedButton(
          onPressed: () => _complete(order),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('تم التسليم'),
        );
      case 'delivered':
        return const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: AppColors.success, size: 16),
            SizedBox(width: 4),
            Text(
              'تم التسليم',
              style: TextStyle(
                color: AppColors.success,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _statusChip(String status) {
    Color color;
    String text;
    switch (status) {
      case 'pending':
        color = AppColors.warning;
        text = 'قيد الانتظار';
        break;
      case 'accepted':
        color = AppColors.primary;
        text = 'مقبول';
        break;
      case 'delivering':
        color = AppColors.accent;
        text = 'قيد التوصيل';
        break;
      case 'delivered':
        color = AppColors.success;
        text = 'تم التوصيل';
        break;
      case 'cancelled':
        color = AppColors.error;
        text = 'ملغي';
        break;
      default:
        color = AppColors.textSecondary;
        text = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
            color: color, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }
}
