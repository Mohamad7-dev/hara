import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import '../../config/colors.dart';
import '../../config/constants.dart';
import '../../config/locations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../providers/order_provider.dart';
import '../../widgets/hara_loader.dart';
import '../../providers/product_provider.dart';
import '../../models/order_model.dart';
import '../../widgets/page_header.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _notes = TextEditingController();
  String _paymentMethod = 'كاش';
  bool _placing = false;
  List<DeliveryOffer> _offers = [];
  String? _selectedDeliveryUid;
  String _selectedArea = '';
  double _deliveryFee = AppConstants.deliveryFee;
  bool _loadingOffers = false;

  List<String> get _cities =>
      palestineLocations.map((c) => c.city).toList(growable: false);

  @override
  void initState() {
    super.initState();
    _initArea();
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  void _initArea() {
    final area = context.read<AuthProvider>().currentUser?.area?.trim() ?? '';
    if (area.isEmpty) return;
    String city = area;
    for (final loc in palestineLocations) {
      if (loc.city == area || loc.neighborhoods.contains(area)) {
        city = loc.city;
        break;
      }
    }
    _selectedArea = city;
    _loadDeliveryOffers();
  }

  Future<void> _loadDeliveryOffers() async {
    final area = _selectedArea.trim();
    if (area.isEmpty) return;
    setState(() => _loadingOffers = true);
    final offers =
        await context.read<OrderProvider>().loadDeliveryOptions(area);
    if (!mounted) return;
    setState(() {
      _offers = offers;
      _loadingOffers = false;
      if (offers.isNotEmpty) {
        final best = offers.reduce((a, b) => a.fee <= b.fee ? a : b);
        _selectedDeliveryUid = best.uid;
        _deliveryFee = best.fee;
      } else {
        _selectedDeliveryUid = null;
        _deliveryFee = AppConstants.deliveryFee;
      }
    });
  }

  bool get _isOnline => _paymentMethod != 'كاش';

  Future<void> _placeOrder() async {
    if (_placing) return;
    final auth = context.read<AuthProvider>();
    final cart = context.read<CartProvider>();
    final orderProvider = context.read<OrderProvider>();
    final user = auth.currentUser!;

    if (cart.items.isEmpty) return;

    setState(() => _placing = true);

    final fee = _deliveryFee;
    DeliveryOffer? selected;
    for (final o in _offers) {
      if (o.uid == _selectedDeliveryUid) selected = o;
    }
    final order = OrderModel(
      id: const Uuid().v4(),
      buyerId: user.uid,
      buyerName: user.name,
      buyerPhone: user.phone,
      buyerAddress: user.address,
      buyerArea: user.area,
      deliveryPersonId: selected?.uid,
      deliveryPersonName: selected?.name,
      status: 'pending',
      items: cart.items.map((item) => OrderItem(
        productId: item.product.id,
        productTitle: item.product.title,
        price: item.product.price,
        quantity: item.quantity,
      )).toList(),
      subtotal: cart.subtotal,
      deliveryFee: fee,
      total: cart.subtotal + fee,
      paymentMethod: _paymentMethod,
      notes: _notes.text.isNotEmpty ? _notes.text : null,
    );

    await orderProvider.createOrder(order);
    final products = context.read<ProductProvider>();
    for (final item in cart.items) {
      await products.decrementStock(item.product.id, item.quantity);
    }
    context.read<NotificationsProvider>().add(
      iconKey: 'order',
      title: 'تم تأكيد طلبك',
      body: 'طلبك #${order.id.substring(0, 8)} في انتظار موصل، تابع حالته من «طلباتي».',
    );
    cart.clear();

    if (!mounted) return;
    if (_isOnline) {
      await _handleOnlinePayment(order, orderProvider);
    } else {
      _showConfirmation('تم تأكيد الطلب',
          'طلبك قيد التوصيل، الدفع كاش عند الاستلام');
    }
    if (mounted) setState(() => _placing = false);
  }

  Future<void> _handleOnlinePayment(
      OrderModel order, OrderProvider orderProvider) async {
    final method = _paymentMethod == 'محفظة' ? 'wallet' : 'card';
    final intent =
        await orderProvider.createPaymentIntent(order.id, method: method);
    if (!mounted) return;
    if (intent == null) {
      _showConfirmation('تم تسجيل الطلب',
          'تعذر بدء الدفع الإلكتروني الآن، سيظهر خيار الدفع في «طلباتي»');
      return;
    }
    if (intent['paid'] == true) {
      _showConfirmation('تم الدفع بنجاح', 'شكراً لثقتك بحارة');
      return;
    }
    if (intent['simulated'] == true) {
      final confirmed = await _showSimulatedPaymentDialog();
      if (confirmed == true) await orderProvider.simulatePayment(order.id);
      if (mounted) {
        _showConfirmation(confirmed == true ? 'تم الدفع' : 'بانتظار الدفع',
            confirmed == true
                ? 'تم تأكيد الدفع تجريبياً'
                : 'يمكنك تأكيد الدفع من «طلباتي» لاحقاً');
      }
      return;
    }
    final url = intent['paymentUrl'] as String?;
    if (url == null || url.isEmpty) {
      _showConfirmation('بانتظار تأكيد الدفع',
          'سيتم تحديث حالة الدفع تلقائياً عند إتمام الدفع');
      return;
    }
    final launched =
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (launched) {
      await _pollUntilPaid(order.id, orderProvider);
    } else {
      _showConfirmation('تم تسجيل الطلب',
          'تعذر فتح بوابة الدفع، أكمل الدفع من «طلباتي»');
    }
  }

  Future<void> _pollUntilPaid(String orderId, OrderProvider orderProvider) async {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Dialog(
        backgroundColor: Colors.transparent,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const HaraLoader(size: 44),
              SizedBox(height: 16),
              Text('بانتظار تأكيد الدفع...',
                  style: TextStyle(color: Colors.white, fontSize: 15)),
            ],
          ),
        ),
      ),
    );
    for (var i = 0; i < 40; i++) {
      await Future.delayed(const Duration(seconds: 3));
      final o = await orderProvider.fetchOrder(orderId);
      if (o != null && o.paymentStatus == 'paid') break;
    }
    if (mounted) Navigator.of(context).pop();
    final finalOrder = await orderProvider.fetchOrder(orderId);
    if (!mounted) return;
    final paid = finalOrder?.paymentStatus == 'paid';
    _showConfirmation(
      paid ? 'تم تأكيد الدفع' : 'لم يكتمل الدفع بعد',
      paid ? 'شكراً لك، سيصلك طلبك قريباً' : 'تحقق من حالة الطلب في «طلباتي»',
    );
  }

  Future<bool?> _showSimulatedPaymentDialog() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('الدفع الإلكتروني غير مفعّل',
            style: TextStyle(fontSize: 17, color: AppColors.textPrimary)),
        content: const Text(
          'هذا الخادم في وضع تجريبي بدون بوابة دفع. لتجربة التدفق كاملاً اضغط «تأكيد الدفع التجريبي»، أو اختر كاش عند الاستلام.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('تأكيد الدفع التجريبي'),
          ),
        ],
      ),
    );
  }

  void _showConfirmation(String title, String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.successLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle,
                  size: 44, color: AppColors.success),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst),
              child: const Text('العودة للرئيسية'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const PageHeader(
            icon: Icons.receipt_long_outlined,
            title: 'تأكيد الطلب',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('معلومات التوصيل'),
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) => Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.person_outline,
                                  size: 16, color: AppColors.accent),
                              const SizedBox(width: 6),
                              Text(
                                'الاسم: ${auth.currentUser?.name ?? ""}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textPrimary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.phone_outlined,
                                  size: 16, color: AppColors.accent),
                              const SizedBox(width: 6),
                              Text(
                                'الهاتف: ${auth.currentUser?.phone ?? ""}',
                                style: const TextStyle(
                                    color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined,
                                  size: 16, color: AppColors.accent),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'العنوان: ${auth.currentUser?.address ?? ""}',
                                  style: const TextStyle(
                                      color: AppColors.textSecondary),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _sectionTitle('المنتجات'),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        ...cart.items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.product.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: AppColors.textPrimary),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${item.quantity} × ${item.product.price} ${item.product.currency}',
                              style: const TextStyle(
                                  color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      )),
                      const Divider(height: 20, color: AppColors.border),
                      _PriceRow('المجموع', '${cart.subtotal.toStringAsFixed(0)} شيكل'),
                      const SizedBox(height: 4),
                      _PriceRow('رسوم التوصيل', '${_deliveryFee.toStringAsFixed(0)} شيكل'),
                      const Divider(height: 20, color: AppColors.border),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'الإجمالي:',
                            style: TextStyle(
                                fontSize: 17, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${(cart.subtotal + _deliveryFee).toStringAsFixed(0)} شيكل',
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary),
                          ),
                        ],
                      ),
                    ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _sectionTitle('اختر الموصّل'),
                  _deliverySection(),
                  const SizedBox(height: 20),
                  _sectionTitle('طريقة الدفع'),
                  _paymentOption('كاش', 'الدفع عند الاستلام', Icons.money),
                  _paymentOption('بطاقة', 'بطاقة فيزا / ماستركارد', Icons.credit_card),
                  _paymentOption('محفظة', 'محفظة إلكترونية', Icons.account_balance_wallet),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _notes,
                    maxLines: 3,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'ملاحظات للبائع (اختياري)',
                      hintText: 'أي ملاحظات إضافية...',
                      filled: true,
                      fillColor: AppColors.card,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _placing ? null : _placeOrder,
                      child: _placing
                          ? const HaraLoader(size: 22)
                          : const Text('تأكيد الطلب',
                              style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _deliverySection() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _selectedArea.isEmpty ? null : _selectedArea,
              hint: const Row(
                children: [
                  Icon(Icons.location_on_outlined,
                      size: 18, color: AppColors.textLight),
                  SizedBox(width: 8),
                  Text('اختر مدينتك / منطقتك',
                      style: TextStyle(
                          fontSize: 14, color: AppColors.textSecondary)),
                ],
              ),
              items: _cities.map((c) {
                return DropdownMenuItem<String>(
                  value: c,
                  child: Text(c,
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.textPrimary)),
                );
              }).toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _selectedArea = v;
                  _selectedDeliveryUid = null;
                  _deliveryFee = AppConstants.deliveryFee;
                });
                _loadDeliveryOffers();
              },
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (_loadingOffers)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: HaraLoader(size: 22)),
          )
        else if (_selectedArea.isEmpty)
          _deliveryHint('اختر مدينتك من القائمة ليظهر لك الموصلون المتاحون فيها')
        else if (_offers.isEmpty)
          _deliveryHint(
              'لا يوجد موصلون متاحون في $_selectedArea حالياً، استخدم «أي موصل متاح» أو اختر مدينة أخرى')
        else ...[
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _selectedDeliveryUid == null
                    ? AppColors.primary
                    : AppColors.border,
                width: _selectedDeliveryUid == null ? 1.5 : 1,
              ),
            ),
            child: ListTile(
              dense: true,
              leading: const Icon(Icons.shuffle,
                  color: AppColors.textLight, size: 20),
              title: const Text('أي موصل متاح (تلقائي)',
                  style: TextStyle(fontSize: 14, color: AppColors.textPrimary)),
              subtitle: Text('رسوم التوصيل ${AppConstants.deliveryFee.toStringAsFixed(0)} شيكل',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
              onTap: () => setState(() {
                _selectedDeliveryUid = null;
                _deliveryFee = AppConstants.deliveryFee;
              }),
            ),
          ),
          ..._offers.map((o) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _selectedDeliveryUid == o.uid
                    ? AppColors.primary
                    : AppColors.border,
                width: _selectedDeliveryUid == o.uid ? 1.5 : 1,
              ),
            ),
            child: ListTile(
              dense: true,
              leading: const Icon(Icons.person,
                  color: AppColors.primary, size: 20),
              title: Row(
                children: [
                  Expanded(
                    child: Text(o.name,
                        style: const TextStyle(
                            fontSize: 14, color: AppColors.textPrimary)),
                  ),
                  Text(
                    '${o.fee.toStringAsFixed(0)} شيكل',
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary),
                  ),
                ],
              ),
              subtitle: Text(
                [
                  if (o.vehicle != null && o.vehicle!.isNotEmpty) o.vehicle!,
                  'تقييم ${o.rating.toStringAsFixed(1)}',
                  'هاتف ${o.phone}',
                ].join(' • '),
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
              trailing: Icon(
                _selectedDeliveryUid == o.uid
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                color: _selectedDeliveryUid == o.uid
                    ? AppColors.primary
                    : AppColors.textLight,
                size: 20,
              ),
              onTap: () => setState(() {
                _selectedDeliveryUid = o.uid;
                _deliveryFee = o.fee;
              }),
            ),
          )),
        ],
      ],
    );
  }

  Widget _deliveryHint(String text) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.delivery_dining,
              size: 20, color: AppColors.textLight),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentOption(String value, String label, IconData icon) {
    final selected = _paymentMethod == value;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.border,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: ListTile(
        leading: Icon(icon,
            color: selected ? AppColors.primary : AppColors.textLight),
        title: Text(label,
            style: TextStyle(
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              color: AppColors.textPrimary,
            )),
        trailing: Radio(
          value: value,
          groupValue: _paymentMethod,
          onChanged: (v) => setState(() => _paymentMethod = v!),
          activeColor: AppColors.primary,
        ),
        onTap: () => setState(() => _paymentMethod = value),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  const _PriceRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(color: AppColors.textSecondary)),
        Text(value,
            style: const TextStyle(
                color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
