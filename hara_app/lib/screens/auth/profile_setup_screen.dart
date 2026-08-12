import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../config/constants.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/hara_loader.dart';
import '../../services/api_client.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  final _code = TextEditingController();
  String? _photo;
  bool _uploadingPhoto = false;
  bool _isEdit = false;
  bool _codeSent = false;
  bool _codeSending = false;

  @override
  void initState() {
    super.initState();
    final u = context.read<AuthProvider>().currentUser;
    _name = TextEditingController(text: u?.name ?? '');
    _phone = TextEditingController(text: u?.phone ?? '');
    _photo = u?.photo;
    _isEdit = (u?.name.isNotEmpty ?? false) && (u?.phone.isNotEmpty ?? false);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final files = await ImagePicker().pickMultiImage();
    if (files.isEmpty || files.length > 1) return;
    final file = files.first;
    setState(() => _uploadingPhoto = true);
    try {
      final dataUrl = await _compressImage(file);
      if (dataUrl == null) return;
      final up = await ApiClient.instance.post('api/media', {'base64': dataUrl});
      if (mounted) {
        setState(() {
          _photo = up['url'] as String;
          _uploadingPhoto = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _uploadingPhoto = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل رفع الصورة: ${e.message}')),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _uploadingPhoto = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر تحميل الصورة')),
        );
      }
    }
  }

  Future<String?> _compressImage(XFile file) async {
    final bytes = await file.readAsBytes();
    if (bytes.length < 500 * 1024) {
      return 'data:${file.mimeType ?? 'image/jpeg'};base64,${base64Encode(bytes)}';
    }
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final img = frame.image;
    const maxDim = 600.0;
    var w = img.width.toDouble();
    var h = img.height.toDouble();
    if (w > maxDim || h > maxDim) {
      final sc = maxDim / (w > h ? w : h);
      w = (w * sc).roundToDouble();
      h = (h * sc).roundToDouble();
    }
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawImageRect(
      img,
      ui.Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
      ui.Rect.fromLTWH(0, 0, w, h),
      ui.Paint(),
    );
    final picture = recorder.endRecording();
    final resized = await picture.toImage(w.round(), h.round());
    final data = await resized.toByteData(format: ui.ImageByteFormat.png);
    img.dispose();
    resized.dispose();
    if (data == null) return null;
    return 'data:image/png;base64,${base64Encode(data.buffer.asUint8List())}';
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.updateProfile(
      name: _name.text.trim(),
      phone: _phone.text.trim(),
      photo: _photo,
    );
    if (!mounted) return;
    if (ok) {
      if (_isEdit) {
        Navigator.of(context).pop();
      } else {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    }
  }

  Future<void> _sendCode() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _codeSending = true);
    final auth = context.read<AuthProvider>();
    final debugCode = await auth.sendCode(_phone.text.trim());
    if (!mounted) return;
    setState(() {
      _codeSending = false;
      _codeSent = true;
    });
    if (debugCode != null && debugCode.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('رمز التحقق التجريبي: $debugCode')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال رمز التحقق عبر SMS')),
      );
    }
  }

  Future<void> _verifyCode() async {
    final t = _code.text.trim();
    if (t.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل الرمز المرسل')),
      );
      return;
    }
    final auth = context.read<AuthProvider>();
    final ok = await auth.verifyCode(_phone.text.trim(), t);
    if (!mounted) return;
    if (ok) {
      setState(() => _codeSent = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم التحقق من رقم الجوال بنجاح')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'تعديل الملف الشخصي' : 'أكمل ملفك الشخصي'),
        automaticallyImplyLeading: _isEdit,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _uploadingPhoto ? null : _pickPhoto,
                  child: Stack(
                    children: [
                      Container(
                        width: 116,
                        height: 116,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.card,
                          border: Border.all(
                              color: AppColors.primary, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: _buildAvatar(),
                        ),
                      ),
                      Positioned(
                        bottom: 2,
                        left: 2,
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white, width: 2.5),
                          ),
                          child: const Icon(Icons.camera_alt,
                              size: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'اضغط على الصورة لتغييرها',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 28),
                TextFormField(
                  controller: _name,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'الاسم الكامل',
                    hintText: 'مثال: محمد أحمد',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'أدخل اسمك'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _save(),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'رقم الجوال',
                    hintText: '0599XXXXXX',
                    prefixIcon: Icon(Icons.phone_android),
                  ),
                  validator: (v) {
                    final t = (v ?? '').replaceAll(RegExp(r'\D'), '');
                    if (t.length < 9) return 'أدخل رقم جوال صحيح';
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    final verified = auth.currentUser?.phoneVerified == true &&
                        auth.currentUser?.phone == _phone.text.trim();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (verified)
                          Row(
                            children: [
                              const Icon(Icons.verified_user,
                                  size: 17, color: AppColors.success),
                              const SizedBox(width: 6),
                              const Expanded(
                                child: Text(
                                  'تم التحقق من رقم الجوال',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.success,
                                  ),
                                ),
                              ),
                            ],
                          )
                        else ...[
                          Row(
                            children: [
                              const Icon(Icons.info_outline,
                                  size: 15, color: AppColors.textSecondary),
                              const SizedBox(width: 6),
                              const Expanded(
                                child: Text(
                                  'يُستخدم الرقم لإيصال مشترياتك وتأكيد هويتك. سنرسل لك رمزاً عبر SMS للتحقق.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: (_codeSending || auth.isLoading)
                                ? null
                                : _sendCode,
                            icon: _codeSending
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.sms_outlined, size: 18),
                            label: Text(_codeSent
                                ? 'إعادة إرسال الرمز'
                                : 'إرسال رمز التحقق'),
                          ),
                          if (_codeSent) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _code,
                                    keyboardType: TextInputType.number,
                                    maxLength: 6,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    decoration: const InputDecoration(
                                      labelText: 'رمز التحقق',
                                      hintText: '6 أرقام',
                                      prefixIcon:
                                          Icon(Icons.password_outlined),
                                      counterText: '',
                                    ),
                                    onFieldSubmitted: (_) => _verifyCode(),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                ElevatedButton(
                                  onPressed: auth.isLoading ? null : _verifyCode,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 18, vertical: 16),
                                  ),
                                  child: auth.isLoading
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white),
                                        )
                                      : const Text('تأكيد'),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: 28),
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    if (auth.error != null) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
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
                    }
                    return const SizedBox.shrink();
                  },
                ),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: Consumer<AuthProvider>(
                    builder: (context, auth, _) => ElevatedButton(
                      onPressed: (auth.isLoading || _uploadingPhoto)
                          ? null
                          : _save,
                      child: auth.isLoading
                          ? const HaraLoader(size: 22)
                          : Text(
                              _isEdit ? 'حفظ التغييرات' : 'حفظ والمتابعة',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    if (_uploadingPhoto) {
      return const Center(
        child: HaraLoader(size: 40),
      );
    }
    final p = _photo;
    if (p != null && p.isNotEmpty) {
      if (p.startsWith('http')) {
        return Image.network(p, fit: BoxFit.cover, errorBuilder: (_, __, ___) {
          return const _AvatarFallback();
        });
      }
      return Image.memory(base64Decode(p.split(',')[1]), fit: BoxFit.cover);
    }
    return const _AvatarFallback();
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.08),
      child: const Icon(Icons.person, size: 52, color: AppColors.primary),
    );
  }
}
