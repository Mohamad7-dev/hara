import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/colors.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/product_provider.dart';
import '../../widgets/product_card.dart';
import '../products/product_detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final favs = context.watch<FavoritesProvider>().ids;
    final products = context
        .watch<ProductProvider>()
        .products
        .where((p) => favs.contains(p.id))
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('المفضلة'),
        backgroundColor: AppColors.card,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: products.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.favorite_border,
                      size: 64, color: AppColors.textMuted),
                  const SizedBox(height: 14),
                  const Text(
                    'لا توجد منتجات مفضلة بعد',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'اضغط على ♥ في أي منتج لإضافته إلى المفضلة',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.65,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: products.length,
              itemBuilder: (context, i) => ProductCard(
                product: products[i],
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ProductDetailScreen(product: products[i]),
                )),
              ),
            ),
    );
  }
}
