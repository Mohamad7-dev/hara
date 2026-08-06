import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/post_provider.dart';
import '../../widgets/page_header.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  static const _categories = ['عرض', 'سؤال', 'تحديث', 'مشكلة', 'منشور'];

  final _form = GlobalKey<FormState>();
  final _text = TextEditingController();
  String _category = 'عرض';
  bool _hasImage = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  String _roleLabel(String userType) {
    switch (userType) {
      case 'delivery':
        return 'موصل';
      case 'admin':
        return 'أدمن';
      default:
        return 'مستخدم';
    }
  }

  String _avatarKey(String userType) {
    switch (userType) {
      case 'delivery':
        return 'motor';
      default:
        return 'person';
    }
  }

  Future<void> _publish() async {
    if (!_form.currentState!.validate()) return;
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;
    await context.read<PostProvider>().addPost(
          author: user.name,
          role: _roleLabel(user.userType),
          avatarKey: _avatarKey(user.userType),
          category: _category,
          text: _text.text.trim(),
          hasImage: _hasImage,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم نشر المنشور'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const PageHeader(
            icon: Icons.campaign_outlined,
            title: 'نشر منشور',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'نوع المنشور',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final c in _categories)
                          _categoryChip(c),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _text,
                      maxLines: 6,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'ماذا تريد أن تنشر؟',
                        hintText: 'اكتب منشورك هنا...',
                        alignLabelWithHint: true,
                        filled: true,
                        fillColor: AppColors.card,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.border),
                        ),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'اكتب نص المنشور'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: SwitchListTile(
                        value: _hasImage,
                        onChanged: (v) => setState(() => _hasImage = v),
                        activeThumbColor: AppColors.accent,
                        title: const Text(
                          'إرفاق صورة',
                          style: TextStyle(
                              color: AppColors.textPrimary, fontSize: 14),
                        ),
                        subtitle: const Text(
                          'صورة تعبيرية تظهر مع المنشور',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _publish,
                        child: const Text('نشر',
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

  Widget _categoryChip(String category) {
    final selected = _category == category;
    return GestureDetector(
      onTap: () => setState(() => _category = category),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          category,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
