import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../config/constants.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  Future<void> _googleLogin() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.googleLogin();
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pushReplacementNamed(
        auth.needsProfile ? '/profile-setup' : '/home',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              _buildHero(),
              Transform.translate(
                offset: const Offset(0, -24),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius:
                        BorderRadius.circular(AppConstants.borderRadiusLarge),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.10),
                        blurRadius: 30,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'أهلاً بيك في حارتك 👋',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'سجّل بحساب جوجل وابدا التسوق والتواصل\nمع أهل حيّك',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.6,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildErrorBanner(),
                      Consumer<AuthProvider>(
                        builder: (context, auth, _) => SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: OutlinedButton.icon(
                            onPressed: auth.isLoading ? null : _googleLogin,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                  color: AppColors.border, width: 1.3),
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: auth.isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        color: AppColors.primary),
                                  )
                                : const _GoogleLogo(size: 22),
                            label: Text(
                              auth.isLoading
                                  ? 'جارٍ تسجيل الدخول…'
                                  : 'الدخول بحساب جوجل',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Row(
                        children: [
                          Expanded(child: Divider(color: AppColors.border)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'أول مرة؟',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: AppColors.border)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'حسابك بينعمل تلقائياً وتكمل بياناتك\nفي خطوة واحدة بعد الدخول',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.6,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _buildFeature(Icons.storefront_rounded, 'سوق حيك'),
                    const SizedBox(width: 10),
                    _buildFeature(Icons.chat_bubble_rounded, 'تواصل مع الجيران'),
                    const SizedBox(width: 10),
                    _buildFeature(Icons.delivery_dining_rounded, 'توصيل'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_rounded,
                      size: 13, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Text(
                    'بياناتك محمية ولن تُشارك مع أي جهة',
                    style: TextStyle(
                        fontSize: 11.5, color: AppColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final err = auth.error;
        if (err == null) return const SizedBox.shrink();
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.error.withOpacity(0.25)),
          ),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  err,
                  style: const TextStyle(
                      color: AppColors.error, fontSize: 13, height: 1.4),
                ),
              ),
              InkWell(
                onTap: () => context.read<AuthProvider>().clearError(),
                borderRadius: BorderRadius.circular(20),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close, size: 16, color: AppColors.error),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeature(IconData icon, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 26, color: AppColors.accent),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.text2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 40, bottom: 56),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(34)),
      ),
      child: Column(
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(Icons.storefront_rounded,
                color: AppColors.primary, size: 48),
          ),
          const SizedBox(height: 18),
          const Text(
            AppConstants.appName,
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppConstants.appTagline,
            style: const TextStyle(
              fontSize: 14.5,
              color: Color(0xFFE8DECC),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = const Color(0xFF4285F4);
    canvas.drawPath(
      Path()
        ..moveTo(22.56 * s, 12.25 * s)
        ..cubicTo(22.56 * s, 11.47 * s, 22.49 * s, 10.72 * s, 22.36 * s, 10 * s)
        ..lineTo(12 * s, 10 * s)
        ..lineTo(12 * s, 14.26 * s)
        ..lineTo(17.92 * s, 14.26 * s)
        ..cubicTo(17.66 * s, 15.63 * s, 16.88 * s, 16.79 * s, 15.71 * s, 15.57 * s)
        ..lineTo(15.71 * s, 18.34 * s)
        ..lineTo(19.28 * s, 18.34 * s)
        ..cubicTo(21.36 * s, 16.42 * s, 22.56 * s, 13.6 * s, 22.56 * s, 12.25 * s)
        ..close(),
      paint,
    );

    paint.color = const Color(0xFF34A853);
    canvas.drawPath(
      Path()
        ..moveTo(12 * s, 23 * s)
        ..cubicTo(14.97 * s, 23 * s, 17.46 * s, 22.02 * s, 19.28 * s, 20.34 * s)
        ..lineTo(15.71 * s, 17.57 * s)
        ..cubicTo(14.73 * s, 18.23 * s, 13.48 * s, 18.63 * s, 12 * s, 18.63 * s)
        ..cubicTo(9.14 * s, 18.63 * s, 6.71 * s, 16.7 * s, 5.84 * s, 14.1 * s)
        ..lineTo(2.18 * s, 14.1 * s)
        ..lineTo(2.18 * s, 16.94 * s)
        ..cubicTo(3.99 * s, 20.53 * s, 7.7 * s, 23 * s, 12 * s, 23 * s)
        ..close(),
      paint,
    );

    paint.color = const Color(0xFFFBBC05);
    canvas.drawPath(
      Path()
        ..moveTo(5.84 * s, 14.1 * s)
        ..cubicTo(5.62 * s, 13.44 * s, 5.49 * s, 12.74 * s, 5.49 * s, 12 * s)
        ..cubicTo(5.49 * s, 11.26 * s, 5.62 * s, 10.56 * s, 5.84 * s, 9.9 * s)
        ..lineTo(5.84 * s, 7.06 * s)
        ..lineTo(2.18 * s, 7.06 * s)
        ..cubicTo(1.43 * s, 8.55 * s, 1 * s, 10.22 * s, 1 * s, 12 * s)
        ..cubicTo(1 * s, 13.78 * s, 1.43 * s, 15.45 * s, 2.18 * s, 16.94 * s)
        ..lineTo(5.84 * s, 14.1 * s)
        ..close(),
      paint,
    );

    paint.color = const Color(0xFFEA4335);
    canvas.drawPath(
      Path()
        ..moveTo(12 * s, 5.38 * s)
        ..cubicTo(13.62 * s, 5.38 * s, 15.06 * s, 5.94 * s, 16.21 * s, 7.02 * s)
        ..lineTo(19.36 * s, 3.87 * s)
        ..cubicTo(17.45 * s, 2.09 * s, 14.97 * s, 1 * s, 12 * s, 1 * s)
        ..cubicTo(7.7 * s, 1 * s, 3.99 * s, 3.47 * s, 2.18 * s, 7.06 * s)
        ..lineTo(5.84 * s, 9.9 * s)
        ..cubicTo(6.71 * s, 7.3 * s, 9.14 * s, 5.38 * s, 12 * s, 5.38 * s)
        ..close(),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
