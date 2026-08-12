import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../models/comment_model.dart';
import '../../models/product_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/comment_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/product_provider.dart';
import '../../services/api_client.dart';
import '../../utils/format.dart';
import '../../widgets/comments_sheet.dart';
import '../../widgets/comment_replies.dart';
import '../messages/chat_screen.dart';

class ProductDetailScreen extends StatelessWidget {
  final ProductModel product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final fav = context.watch<FavoritesProvider>().isFavorite(product.id);
    final live = context.watch<ProductProvider>().productById(product.id) ?? product;
    final reviews =
        context.watch<CommentProvider>().commentsFor('product', product.id);
    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل المنتج'),
        actions: [
          IconButton(
            icon: Icon(
              fav ? Icons.favorite : Icons.favorite_border,
              color: fav ? AppColors.error : null,
            ),
            onPressed: () =>
                context.read<FavoritesProvider>().toggle(product.id),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 280,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.2),
              ),
              child: _headerImage,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(product.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(product.category, style: const TextStyle(color: AppColors.accent)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.store_outlined, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(product.sellerName, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                      const SizedBox(width: 16),
                      const Icon(Icons.star, size: 16, color: AppColors.gold),
                      const SizedBox(width: 4),
                      Text('${live.rating.toStringAsFixed(1)} (${live.ratingCount})', style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text('الوصف', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(product.description, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.6)),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('السعر:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Text('${product.price} ${product.currency}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ],
                  ),
                  if (product.stock > 0) ...[
                    const SizedBox(height: 4),
                    Text('المتبقي: ${product.stock} قطعة', style: const TextStyle(color: AppColors.accent)),
                  ] else ...[
                    const SizedBox(height: 4),
                    const Text('نفذ من المخزون', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                  ],
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('التقييمات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Text(
                        '${reviews.length} تقييم',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: reviews.isEmpty
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'لا توجد تقييمات بعد',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'كن أول من يقيّم هذا المنتج',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 12),
                              _addReviewButton(context),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  _stars(context, live.rating),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${live.rating.toStringAsFixed(1)}',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '(${live.ratingCount} تقييم)',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  for (final r in [1, 2, 3, 4, 5])
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.star,
                                            size: 12,
                                            color: _barColor(context, r, live.rating),
                                          ),
                                          const SizedBox(width: 2),
                                          Expanded(
                                            child: Container(
                                              height: 5,
                                              margin: const EdgeInsets.symmetric(horizontal: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.bg2,
                                                borderRadius: BorderRadius.circular(3),
                                              ),
                                              child: FractionallySizedBox(
                                                alignment: Alignment.centerLeft,
                                                widthFactor: _barFactor(r, live.rating),
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: _barColor(context, r, live.rating),
                                                    borderRadius: BorderRadius.circular(3),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Divider(height: 1),
                              const SizedBox(height: 6),
                              ...reviews.map((r) => _reviewRow(context, r)),
                              const SizedBox(height: 12),
                              _addReviewButton(context),
                            ],
                          ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context.read<ChatProvider>().ensure(product.sellerName);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                ChatScreen(name: product.sellerName),
                          ),
                        );
                      },
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text('تواصل مع البائع', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: (product.stock <= 0 || !product.isAvailable)
                          ? null
                          : () {
                              context.read<CartProvider>().addItem(product);
                              ScaffoldMessenger.of(context)
                                ..hideCurrentSnackBar()
                                ..showSnackBar(
                                  SnackBar(
                                    content: const Text('تمت الإضافة إلى السلة'),
                                    behavior: SnackBarBehavior.floating,
                                    duration: const Duration(milliseconds: 1500),
                                  ),
                                );
                            },
                      icon: const Icon(Icons.add_shopping_cart),
                      label: Text(
                        (product.stock <= 0 || !product.isAvailable)
                            ? 'نفذ من المخزون'
                            : 'أضف إلى السلة',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  ],
                ),
              ),
            ],
          ),
        ),
    );
  }

  Widget get _headerImage {
    if (product.images.isNotEmpty) {
      final src = product.images.first;
      if (src.startsWith('data:')) {
        return Image.memory(
          base64Decode(src.split(',').last),
          fit: BoxFit.cover,
        );
      }
      return Image.network(
        '${ApiClient.instance.baseUrl}$src',
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            _headerPlaceholder,
      );
    }
    return _headerPlaceholder;
  }

  Widget get _headerPlaceholder => Center(
        child: Icon(Icons.image_outlined,
            size: 80, color: AppColors.primary.withValues(alpha: 0.3)),
      );

  Widget _addReviewButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: OutlinedButton.icon(
        onPressed: () => showCommentsSheet(
          context,
          kind: 'product',
          targetId: product.id,
          title: 'تقييم المنتج',
          authorName: product.sellerName,
        ),
        icon: const Icon(Icons.star_outline, size: 18),
        label: const Text('أضف تقييمك'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.accent,
          side: const BorderSide(color: AppColors.accent),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _stars(BuildContext context, double rating) {
    final full = rating.round();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            i <= full ? Icons.star : Icons.star_border,
            size: 16,
            color: i <= full ? AppColors.gold : AppColors.textMuted,
          ),
      ],
    );
  }

  Color _barColor(BuildContext context, int star, double rating) {
    return star <= rating.round() ? AppColors.accent : AppColors.textMuted;
  }

  double _barFactor(int star, double rating) {
    final rounded = rating.round().toDouble();
    if (rounded <= 0) return 0;
    return (star / rounded).clamp(0.0, 1.0);
  }

  Widget _reviewRow(BuildContext context, CommentModel r) {
    final currentUser = context.read<AuthProvider>().currentUser;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.bg2,
              shape: BoxShape.circle,
            ),
            child: Icon(chatIcon(r.avatarKey),
                color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.author,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    for (var i = 1; i <= 5; i++)
                      Icon(
                        i <= r.rating ? Icons.star : Icons.star_border,
                        size: 13,
                        color: i <= r.rating
                            ? AppColors.accent
                            : AppColors.textMuted,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  r.text,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                CommentReplies(
                  comment: r,
                  kind: 'product',
                  targetId: product.id,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                chatTime(r.time),
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textMuted),
              ),
              if (currentUser != null && currentUser.name != r.author) ...[
                const SizedBox(height: 8),
                _reviewMessageButton(context, r),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _reviewMessageButton(BuildContext context, CommentModel r) {
    return InkWell(
      onTap: () {
        context
            .read<ChatProvider>()
            .ensure(r.author, role: r.role, iconKey: r.avatarKey);
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ChatScreen(name: r.author)),
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.mail_outline, size: 13, color: AppColors.accent),
            SizedBox(width: 4),
            Text(
              'مراسلة',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
