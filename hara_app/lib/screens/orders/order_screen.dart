import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/colors.dart';
import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../widgets/page_header.dart';
import '../../widgets/hara_loader.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        context.read<OrderProvider>().loadBuyerOrders(user.uid);
      }
    });
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        context.read<OrderProvider>().loadBuyerOrders(user.uid);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _cancelOrder(OrderModel order) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('إلغاء الطلب'),
        content: const Text('هل أنت متأكد من إلغاء هذا الطلب؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('تراجع'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('إلغاء الطلب', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await context.read<OrderProvider>().updateOrderStatus(order.id, 'cancelled');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إلغاء الطلب'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const PageHeader(
            icon: Icons.receipt_long_outlined,
            title: 'طلباتي',
          ),
          Expanded(
            child: orderProvider.isLoading
                ? const Center(child: HaraLoader())
                : orderProvider.orders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long_outlined,
                                size: 64, color: AppColors.textMuted),
                            const SizedBox(height: 14),
                            const Text(
                              'لا توجد طلبات',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'اطلب منتجاتك وستظهر هنا',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: orderProvider.orders.length,
                        itemBuilder: (context, index) {
                          final order = orderProvider.orders[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.04),
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
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'طلب #${order.id.substring(0, 8)}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary),
                                      ),
                                      _statusBadge(order.status),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    '${order.items.length} منتجات',
                                    style: const TextStyle(
                                        color: AppColors.textSecondary),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'المجموع:',
                                        style: TextStyle(
                                            color: AppColors.textSecondary),
                                      ),
                                      Text(
                                        '${order.total.toStringAsFixed(0)} شيكل',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'تاريخ: ${order.createdAt.toString().substring(0, 16)}',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textLight),
                                  ),
                                  if (order.deliveryPersonName != null) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.motorcycle_outlined,
                                            size: 16,
                                            color: AppColors.accent),
                                        const SizedBox(width: 4),
                                        Text(
                                          'الموصل: ${order.deliveryPersonName}',
                                          style: const TextStyle(
                                              color: AppColors.accent,
                                              fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ],
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.currency_exchange,
                                          size: 16,
                                          color: AppColors.textSecondary),
                                      const SizedBox(width: 4),
                                      Text(
                                        'رسوم التوصيل: ${order.deliveryFee?.toStringAsFixed(0) ?? "5"} شيكل · الدفع: ${order.paymentMethod}',
                                        style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 12.5),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  _paymentChip(order),
                                  if (_canPayOnline(order)) ...[
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: () => _payNow(order),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: const Text('إتمام الدفع'),
                                      ),
                                    ),
                                  ],
                                  if (order.status == 'pending') ...[
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton(
                                        onPressed: () => _cancelOrder(order),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.error,
                                          side: const BorderSide(
                                              color: AppColors.error),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: const Text('إلغاء الطلب'),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  bool _canPayOnline(OrderModel order) {
    if (order.paymentStatus == 'paid') return false;
    if (order.status == 'cancelled') return false;
    return order.paymentMethod == 'بطاقة' || order.paymentMethod == 'محفظة';
  }

  Future<void> _payNow(OrderModel order) async {
    final orderProvider = context.read<OrderProvider>();
    final method = order.paymentMethod == 'محفظة' ? 'wallet' : 'card';
    final intent =
        await orderProvider.createPaymentIntent(order.id, method: method);
    if (!mounted) return;
    if (intent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر بدء الدفع، حاول مجدداً')),
      );
      return;
    }
    if (intent['paid'] == true) {
      await orderProvider.fetchOrder(order.id);
      return;
    }
    if (intent['simulated'] == true) {
      await orderProvider.simulatePayment(order.id);
      await orderProvider.fetchOrder(order.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تأكيد الدفع (تجريبي)')),
        );
      }
      return;
    }
    final url = intent['paymentUrl'] as String?;
    if (url == null || url.isEmpty) return;
    final launched =
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (launched) {
      for (var i = 0; i < 40; i++) {
        await Future.delayed(const Duration(seconds: 3));
        final o = await orderProvider.fetchOrder(order.id);
        if (o != null && o.paymentStatus == 'paid') break;
      }
    }
  }

  Widget _paymentChip(OrderModel order) {
    final paid = order.paymentStatus == 'paid';
    final color = paid ? AppColors.success : AppColors.warning;
    final icon = paid ? Icons.paid_outlined : Icons.payments_outlined;
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          paid ? 'تم الدفع' : 'غير مدفوع بعد',
          style: TextStyle(
            color: color,
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    String text;
    switch (status) {
      case 'pending':
        color = AppColors.warning;
        text = 'قيد الانتظار';
        break;
      case 'accepted':
        color = AppColors.primary;
        text = 'تم القبول';
        break;
      case 'delivering':
        color = AppColors.accentLight;
        text = 'قيد التوصيل';
        break;
      case 'delivered':
        color = AppColors.accent;
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
