import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/area_select_field.dart';
import '../../widgets/page_header.dart';

class DeliveryRegistrationScreen extends StatefulWidget {
  const DeliveryRegistrationScreen({super.key});

  @override
  State<DeliveryRegistrationScreen> createState() => _DeliveryRegistrationScreenState();
}

class _DeliveryRegistrationScreenState extends State<DeliveryRegistrationScreen> {
  final _form = GlobalKey<FormState>();
  final _areasKey = GlobalKey<FormFieldState<List<String>>>();
  final _feeCtrl = TextEditingController();
  String _vehicleType = 'دراجة';

  @override
  void dispose() {
    _feeCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_form.currentState!.validate()) return;
    final areas = _areasKey.currentState?.value ?? const <String>[];
    await context.read<AuthProvider>().updateDeliveryProfile(
          areas: areas,
          fee: double.parse(_feeCtrl.text),
          vehicleType: _vehicleType,
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تسجيلك كموصل بنجاح'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const PageHeader(
            icon: Icons.delivery_dining_outlined,
            title: 'التسجيل كموصل',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.bg2,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.motorcycle,
                                color: AppColors.accent, size: 26),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'انضم لفريق التوصيل',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                const Text(
                                  'وفر خدمات التوصيل في منطقتك واربح',
                                  style: TextStyle(
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
                    const SizedBox(height: 24),
                    const Text(
                      'نوع المركبة',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _vehicleOption('دراجة', Icons.directions_bike),
                        const SizedBox(width: 8),
                        _vehicleOption('سيارة', Icons.directions_car),
                        const SizedBox(width: 8),
                        _vehicleOption('شاحنة', Icons.local_shipping),
                      ],
                    ),
                    const SizedBox(height: 24),
                    AreaSelectField(
                      key: _areasKey,
                      label: 'مناطق التوصيل',
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _feeCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'أجرة التوصيل (شيكل)',
                        hintText: '10',
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
                      validator: (v) => v == null || v.isEmpty ? 'required' : null,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _register,
                        child: const Text('تسجيل كموصل',
                            style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _vehicleOption(String type, IconData icon) {
    final selected = _vehicleType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _vehicleType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color:
                      selected ? Colors.white : AppColors.textSecondary,
                  size: 28),
              const SizedBox(height: 4),
              Text(
                type,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
