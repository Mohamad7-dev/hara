import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../config/constants.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/area_select_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _password = TextEditingController();
  final _areasKey = GlobalKey<FormFieldState<List<String>>>();
  final _fee = TextEditingController();
  String _userType = 'regular';
  String _vehicleType = 'دراجة';
  bool _obscure = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _address.dispose();
    _password.dispose();
    _fee.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_form.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.register(
      name: _name.text.trim(),
      email: _email.text.trim(),
      phone: _phone.text.trim(),
      address: _address.text.trim(),
      password: _password.text,
      userType: _userType,
      deliveryAreas: _userType == 'delivery'
          ? _areasKey.currentState?.value ?? const <String>[]
          : null,
      deliveryFee: _userType == 'delivery'
          ? double.tryParse(_fee.text) ?? 0
          : null,
      vehicleType: _userType == 'delivery' ? _vehicleType : null,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إنشاء حساب جديد')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'أنشئ حسابك الجديد',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'أخبرنا من أنت حتى نجهّز لك شاشتك',
                  style: TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _typeOption(
                        value: 'regular',
                        icon: Icons.storefront_outlined,
                        label: 'مستخدم عادي',
                        sub: 'بيع وشراء',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _typeOption(
                        value: 'delivery',
                        icon: Icons.delivery_dining_outlined,
                        label: 'موصل',
                        sub: 'توصيل الطلبات',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                TextFormField(
                  controller: _name,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'الاسم الكامل',
                    hintText: 'محمد أبو أحمد',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'أدخل اسمك الكامل' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'البريد الإلكتروني',
                    hintText: 'example@email.com',
                    prefixIcon: Icon(Icons.alternate_email),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'أدخل بريدك الإلكتروني'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'رقم الهاتف',
                    hintText: '05X XXX XXXX',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'أدخل رقم هاتفك'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _address,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'المدينة / الحي',
                    hintText: 'رام الله - البيرة',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'أدخل مدينتك أو حيك'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _password,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _register(),
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور',
                    hintText: '3 أحرف على الأقل',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) => v == null || v.length < 3
                      ? '3 أحرف على الأقل'
                      : null,
                ),
                if (_userType == 'delivery') ...[
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      borderRadius:
                          BorderRadius.circular(AppConstants.borderRadius),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.delivery_dining,
                                color: AppColors.success, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'بيانات التوصيل',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.success2,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  AreaSelectField(key: _areasKey, label: 'مناطق التوصيل'),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _fee,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'أجرة التوصيل (شيكل)',
                      hintText: '7',
                      prefixIcon: Icon(Icons.currency_exchange),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'أدخل أجرة التوصيل'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'المركبة',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.text2),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _vehicleOption('دراجة', Icons.directions_bike),
                      const SizedBox(width: 8),
                      _vehicleOption('سيارة', Icons.directions_car),
                      const SizedBox(width: 8),
                      _vehicleOption('شاحنة', Icons.local_shipping),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    if (auth.error == null) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: AppColors.error, size: 17),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              auth.error!,
                              style: const TextStyle(
                                  color: AppColors.error, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                Consumer<AuthProvider>(
                  builder: (context, auth, _) => SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: auth.isLoading ? null : _register,
                      child: auth.isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text(
                              'إنشاء حساب',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'عندك حساب؟',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'تسجيل الدخول',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _typeOption({
    required String value,
    required IconData icon,
    required String label,
    required String sub,
  }) {
    final selected = _userType == value;
    return GestureDetector(
      onTap: () => setState(() => _userType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.card,
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon,
                color: selected ? Colors.white : AppColors.textSecondary,
                size: 26),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 13.5,
              ),
            ),
            Text(
              sub,
              style: TextStyle(
                color: selected
                    ? Colors.white.withOpacity(0.75)
                    : AppColors.textMuted,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _vehicleOption(String type, IconData icon) {
    final selected = _vehicleType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _vehicleType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.card,
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            border:
                Border.all(color: selected ? AppColors.primary : AppColors.border),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: selected ? Colors.white : AppColors.textSecondary,
                  size: 24),
              const SizedBox(height: 4),
              Text(
                type,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
