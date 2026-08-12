import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../config/constants.dart';
import '../../config/locations.dart';
import '../../services/api_client.dart';
import '../../services/payment_service.dart';
import '../../widgets/hara_loader.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/post_provider.dart';
import '../../providers/comment_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../widgets/product_card.dart';
import '../../widgets/post_card.dart';
import '../favorites/favorites_screen.dart';
import '../notifications/notifications_screen.dart';
import '../products/product_detail_screen.dart';
import '../../models/product_model.dart';
import '../cart/cart_screen.dart';
import '../profile/profile_screen.dart';
import '../delivery/delivery_dashboard_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import '../messages/messages_screen.dart';
import '../delivery/delivery_registration_screen.dart';
import '../orders/order_screen.dart';
import '../posts/add_post_screen.dart';
import '../../widgets/location_picker.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String _city = 'غزة';
  String _neighborhood = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      _initLocation(user?.area);
      context.read<ProductProvider>().loadProducts();
      context.read<ChatProvider>().load();
      context.read<PostProvider>().load();
      context.read<CommentProvider>().load();
      context.read<FavoritesProvider>().load();
      context.read<NotificationsProvider>().load();
    });
  }

  void _initLocation(String? area) {
    if (area == null || area.isEmpty) return;
    for (final c in palestineLocations) {
      if (area == c.city) {
        _city = c.city;
        _neighborhood = '';
        return;
      }
      if (c.neighborhoods.contains(area)) {
        _city = c.city;
        _neighborhood = area;
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => Navigator.of(context).pushReplacementNamed('/login'));
      return const SizedBox.shrink();
    }

    final screens = [
      _buildHome(context),
      const CartScreen(),
      const MessagesScreen(),
      _buildProfile(context, user.userType),
    ];

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: KeyedSubtree(
          key: ValueKey(_currentIndex),
          child: screens[_currentIndex],
        ),
      ),
      bottomNavigationBar: _bottomBar(context),
    );
  }

  Widget _bottomBar(BuildContext context) {
    final cartQty = context.watch<CartProvider>().totalQuantity;
    final unread = context.watch<ChatProvider>().unreadTotal;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 58,
          child: Row(
            children: [
              _navItem(context, 0, Icons.home_outlined, Icons.home, 'الرئيسية'),
              _navItem(context, 1, Icons.shopping_cart_outlined, Icons.shopping_cart, 'السلة',
                  badge: cartQty > 0 ? '$cartQty' : null),
              _centerAddButton(context),
              _navItem(context, 2, Icons.chat_bubble_outline, Icons.chat_bubble, 'الرسائل',
                  badge: unread > 0 ? '$unread' : null),
              _navItem(context, 3, Icons.person_outlined, Icons.person, 'حسابي'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _centerAddButton(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: () => _showQuickActions(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 26),
            ),
            const SizedBox(height: 3),
            const Text(
              'أضف',
              style: TextStyle(
                  fontSize: 10.5, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickActions(BuildContext context) {
    final user = context.read<AuthProvider>().currentUser;
    final isDelivery = user?.userType == 'delivery';
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Text(
                  'ماذا تريد أن تفعل؟',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
              _actionItem(
                sheetContext,
                Icons.edit_outlined,
                'نشر منشور',
                'شارك رأيك أو سؤالك مع الجميع',
                () => Navigator.of(sheetContext).push(
                  MaterialPageRoute(builder: (_) => const AddPostScreen()),
                ),
              ),
              _actionItem(
                sheetContext,
                Icons.campaign_outlined,
                'نشر إعلان',
                'أضف منتجاً أو خدمة للبيع',
                () => Navigator.of(sheetContext).push(
                  MaterialPageRoute(builder: (_) => const AddProductScreen()),
                ),
              ),
              _actionItem(
                sheetContext,
                Icons.receipt_long_outlined,
                'طلباتي',
                'تتبّع طلباتي وحالتها',
                () => Navigator.of(sheetContext).push(
                  MaterialPageRoute(builder: (_) => const OrderScreen()),
                ),
              ),
              if (!isDelivery)
                _actionItem(
                  sheetContext,
                  Icons.delivery_dining_outlined,
                  'انضم للتوصيل',
                  'سجّل نفسك كموصل واستقبل الطلبات',
                  () => Navigator.of(sheetContext).push(
                    MaterialPageRoute(
                        builder: (_) => const DeliveryRegistrationScreen()),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionItem(BuildContext context, IconData icon, String title,
      String subtitle, VoidCallback onTap) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.bg2,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem(BuildContext context, int index, IconData icon, IconData activeIcon,
      String label, {String? badge}) {
    final selected = _currentIndex == index;
    final color = selected ? AppColors.primary : AppColors.textMuted;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(selected ? activeIcon : icon, color: color, size: 24),
                if (badge != null)
                  Positioned(
                    top: -6,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        badge.length > 2 ? '9+' : badge,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                color: color,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHome(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _homeHeader()),
        _searchField(productProvider),
        _categoriesBar(),
        const SliverToBoxAdapter(child: _HeroBanner()),
        SliverToBoxAdapter(
          child: _featuredCarousel(context, productProvider.products),
        ),
        SliverToBoxAdapter(child: _postsSection(context)),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
          productProvider.isLoading
              ? const SliverFillRemaining(
                  child: Center(child: HaraLoader(size: 72)))
              : productProvider.products.isEmpty
                  ? SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.search_off,
                                size: 56, color: AppColors.textMuted),
                            const SizedBox(height: 12),
                            const Text(
                              'لا توجد نتائج مطابقة',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _searchHint(productProvider),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 13, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.65,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final products = productProvider.products;
                        if (index >= products.length) return null;
                        return ProductCard(
                          product: products[index],
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => ProductDetailScreen(product: products[index]),
                          )),
                        );
                      },
                      childCount: productProvider.products.length,
                    ),
                  ),
                ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
    );
  }

  Widget _searchField(ProductProvider productProvider) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: _searchCtrl,
          onChanged: (q) => productProvider.setSearchQuery(q),
          decoration: InputDecoration(
            hintText: 'ابحث عن منتج...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: productProvider.searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchCtrl.clear();
                      productProvider.setSearchQuery('');
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }

  Widget _categoriesBar() {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 50,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            _categoryChip('الكل'),
            ...AppConstants.categories.map(_categoryChip),
          ],
        ),
      ),
    );
  }

  Widget _homeHeader() {
    return Container(
      color: AppColors.bg2,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 2, 14, 2),
          child: Row(
            children: [
              _locationSelector(),
              Expanded(
                child: Center(
                  child: Image.asset(
                    'assets/logo_nav.png',
                    height: 54,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FavoritesScreen()),
                ),
                icon: const Icon(Icons.favorite_border,
                    color: AppColors.textPrimary),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                ),
                icon: Badge(
                  isLabelVisible: context
                          .watch<NotificationsProvider>()
                          .unreadCount >
                      0,
                  label: const SizedBox(
                    width: 8,
                    height: 8,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  child: const Icon(Icons.notifications_none_outlined,
                      color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _locationSelector() {
    final label = _neighborhood.isEmpty ? _city : '$_city · $_neighborhood';
    return InkWell(
      onTap: _pickLocation,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_on_outlined,
                color: AppColors.primary, size: 16),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 3),
            const Icon(Icons.keyboard_arrow_down,
                color: AppColors.textSecondary, size: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _pickLocation() async {
    final result = await showLocationPicker(
      context,
      initialCity: _city,
      initialNeighborhood: _neighborhood.isEmpty ? null : _neighborhood,
    );
    if (result == null || !mounted) return;
    setState(() {
      _city = result.city;
      _neighborhood = result.neighborhood ?? '';
    });
    await context.read<AuthProvider>().setArea(result.area);
  }

  String _searchHint(ProductProvider p) {
    final q = p.searchQuery.trim();
    if (q.isNotEmpty && p.selectedCategory != 'الكل') {
      return 'لم نجد «$q» في قسم ${p.selectedCategory}';
    }
    if (q.isNotEmpty) return 'لم نجد نتائج لـ «$q» — جرّب كلمات أخرى';
    return 'لا توجد منتجات في هذا القسم حالياً';
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _featuredCarousel(BuildContext context, List<ProductModel> products) {
    final featured = products.where((p) => p.featured).take(3).toList();
    final items = featured.isEmpty ? products.take(3).toList() : featured;
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('مميز لك', Icons.star_rounded),
          SizedBox(
            height: 158,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: items.length,
              separatorBuilder: (_, i) => const SizedBox(width: 12),
              itemBuilder: (context, i) => _featuredCard(context, items[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _featuredCard(BuildContext context, ProductModel product) {
    return InkWell(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ProductDetailScreen(product: product),
      )),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 240,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    product.category,
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                if (product.featured) ...[
                  const Icon(Icons.star_rounded,
                      color: AppColors.accent, size: 14),
                  const SizedBox(width: 3),
                  const Text(
                    'مميز',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ] else ...[
                  const Icon(Icons.star,
                      color: AppColors.gold, size: 13),
                  const SizedBox(width: 3),
                  Text(
                    product.rating.toStringAsFixed(1),
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ],
            ),
            Text(
              product.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${product.price} ${product.currency}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'شاهد',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _postsSection(BuildContext context) {
    final posts = context.watch<PostProvider>().posts;
    if (posts.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('آخر المنشورات', Icons.forum_outlined),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: posts.map((p) => PostCard(post: p)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryChip(String label) {
    final selected = context.watch<ProductProvider>().selectedCategory == label;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => context.read<ProductProvider>().setCategory(label),
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(color: selected ? Colors.white : AppColors.textPrimary),
        backgroundColor: Colors.white,
        side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
      ),
    );
  }

  Widget _buildProfile(BuildContext context, String userType) {
    return ProfileScreen(
      onNavigate: (page) {
        switch (page) {
          case 'delivery':
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DeliveryDashboardScreen()));
            break;
          case 'admin':
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminDashboardScreen()));
            break;
        }
      },
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primaryDeep, AppColors.primary, AppColors.accent2],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.28),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              left: -18,
              top: -22,
              child: Icon(
                Icons.local_shipping_outlined,
                size: 130,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            Positioned(
              right: 14,
              bottom: -24,
              child: Icon(
                Icons.storefront_outlined,
                size: 110,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.bolt, size: 18, color: AppColors.accent3),
                      SizedBox(width: 6),
                      Text(
                        'من جيرانك في الحارة',
                        style: TextStyle(
                          color: AppColors.accent3,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'اطلب من الحارة · يوصل لبيتك خلال دقائق',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                    ),
                    child: const Text(
                      'توصيل للحي كله',
                      style: TextStyle(color: AppColors.white, fontSize: 11.5),
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
}

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  final _stock = TextEditingController();
  String _category = 'طعام';
  bool _featured = false;
  bool _paying = false;
  bool _uploading = false;
  final List<String> _pickedImages = [];

  Future<void> _pickImages() async {
    final files = await ImagePicker().pickMultiImage();
    if (files.isEmpty) return;
    for (final f in files.take(5 - _pickedImages.length)) {
      final dataUrl = await _compressImage(f);
      if (dataUrl != null && mounted) {
        setState(() => _pickedImages.add(dataUrl));
      }
    }
  }

  Future<String?> _compressImage(XFile file) async {
    final bytes = await file.readAsBytes();
    if (bytes.length < 900 * 1024) {
      return 'data:${file.mimeType ?? 'image/jpeg'};base64,${base64Encode(bytes)}';
    }
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final img = frame.image;
    const maxDim = 900.0;
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

  Future<List<String>> _uploadImages() async {
    final urls = <String>[];
    for (final dataUrl in _pickedImages) {
      try {
        final up = await ApiClient.instance.post('api/media', {'base64': dataUrl});
        urls.add(up['url'] as String);
      } on ApiException {
        // تجاهل الصور التي تفشل في الرفع
      }
    }
    return urls;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _price.dispose();
    _stock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إضافة منتج جديد')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _form,
            child: Column(
              children: [
                TextFormField(controller: _title, decoration: const InputDecoration(labelText: 'اسم المنتج'), validator: (v) => v == null || v.isEmpty ? 'required' : null),
                const SizedBox(height: 16),
                TextFormField(controller: _description, maxLines: 3, decoration: const InputDecoration(labelText: 'الوصف'), validator: (v) => v == null || v.isEmpty ? 'required' : null),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.bg2,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'صور المنتج (اختياري)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (_pickedImages.isNotEmpty) ...[
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (var i = 0; i < _pickedImages.length; i++)
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.memory(
                                      base64Decode(
                                          _pickedImages[i].split(',').last),
                                      width: 76,
                                      height: 76,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: -6,
                                    right: -6,
                                    child: GestureDetector(
                                      onTap: () => setState(() =>
                                          _pickedImages.removeAt(i)),
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          color: AppColors.error,
                                          shape: BoxShape.circle,
                                        ),
                                        padding: const EdgeInsets.all(2),
                                        child: const Icon(Icons.close,
                                            size: 14, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                      ],
                      if (_pickedImages.length < 5)
                        OutlinedButton.icon(
                          onPressed: _pickImages,
                          icon: const Icon(Icons.add_photo_alternate_outlined),
                          label: Text(
                              _pickedImages.isEmpty ? 'إضافة صور' : 'إضافة المزيد'),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(controller: _price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'السعر (شيكل)'), validator: (v) => v == null || v.isEmpty ? 'required' : null),
                const SizedBox(height: 16),
                TextFormField(controller: _stock, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'الكمية'), validator: (v) => v == null || v.isEmpty ? 'required' : null),
                const SizedBox(height: 16),
                DropdownButtonFormField(
                  value: _category,
                  items: AppConstants.categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setState(() => _category = v!),
                  decoration: const InputDecoration(labelText: 'التصنيف'),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.bg2,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star_rounded, color: AppColors.accent),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'أظهر في قسم المميزة',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'احجز مكاناً في المقدمة بـ \$1 فقط',
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _featured,
                        onChanged: _paying
                            ? null
                            : (v) => setState(() => _featured = v),
                        activeColor: AppColors.accent,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity, height: 50,
                  child: ElevatedButton(
                    onPressed: _paying || _uploading
                        ? null
                        : () async {
                            if (_form.currentState!.validate()) {
                              if (_featured) {
                                setState(() => _paying = true);
                                final ok = await PaymentService()
                                    .processWalletPayment('', 1.0);
                                if (!mounted) return;
                                if (!ok) {
                                  setState(() => _paying = false);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('فشل الدفع، حاول مجدداً'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                  return;
                                }
                              }
                              setState(() => _uploading = true);
                              final images = await _uploadImages();
                              if (!mounted) return;
                              setState(() => _uploading = false);
                              final product = ProductModel(
                                id: '',
                                sellerId: context.read<AuthProvider>().currentUser!.uid,
                                sellerName: context.read<AuthProvider>().currentUser!.storeName ?? context.read<AuthProvider>().currentUser!.name,
                                title: _title.text,
                                description: _description.text,
                                price: double.parse(_price.text),
                                category: _category,
                                images: images,
                                stock: int.parse(_stock.text),
                                featured: _featured,
                              );
                              context.read<ProductProvider>().addProduct(product);
                              if (_featured) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('تم النشر — منتجك الآن في قسم المميزة'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                              Navigator.of(context).pop();
                            }
                          },
                    child: _paying || _uploading
                        ? const HaraLoader(size: 22)
                        : const Text('إضافة المنتج', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
