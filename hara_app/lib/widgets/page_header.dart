import 'package:flutter/material.dart';
import '../config/colors.dart';

class PageHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final bool showBack;

  const PageHeader({
    super.key,
    required this.icon,
    required this.title,
    this.trailing,
    this.showBack = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.bg2,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 2, 4, 2),
          child: Row(
            children: [
              if (showBack)
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_forward,
                      color: AppColors.textPrimary),
                )
              else
                const SizedBox(width: 48),
              Expanded(
                child: Center(
                  child: Image.asset(
                    'assets/logo_nav.png',
                    height: 44,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              trailing ?? const SizedBox(width: 48),
            ],
          ),
        ),
      ),
    );
  }
}
