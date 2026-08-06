class AppConstants {
  static const String appName = 'حارة';
  static const String appTagline = 'كل ما تحتاجه في منطقتك';
  static const String appDescription = 'منصة محلية: سوق، خدمات، وظائف وطلبات';

  static const String defaultImage = 'assets/images/placeholder.png';

  static const List<String> tabs = ['الرئيسية', 'السوق', 'الخدمات', 'الوظائف', 'الطلبات'];

  static const List<String> userTypes = ['regular', 'delivery', 'admin'];

  static const List<String> categories = [
    'طعام',
    'ملابس',
    'إلكترونيات',
    'هواتف',
    'لابتوبات',
    'منزل ومطبخ',
    'أثاث',
    'موبايلات',
    'أدوات وأجهزة',
    'سيارات',
    'هدايا',
    'حرف يدوية',
    'أخرى',
  ];

  static const List<Map<String, String>> categoryIcons = [
    {'name': 'طعام', 'icon': '🍽️'},
    {'name': 'ملابس', 'icon': '👕'},
    {'name': 'إلكترونيات', 'icon': '🎧'},
    {'name': 'هواتف', 'icon': '📱'},
    {'name': 'لابتوبات', 'icon': '💻'},
    {'name': 'منزل ومطبخ', 'icon': '🏠'},
    {'name': 'أثاث', 'icon': '🛋️'},
    {'name': 'موبايلات', 'icon': '📟'},
    {'name': 'أدوات وأجهزة', 'icon': '🛠️'},
    {'name': 'سيارات', 'icon': '🚗'},
    {'name': 'هدايا', 'icon': '🎁'},
    {'name': 'حرف يدوية', 'icon': '🧶'},
    {'name': 'أخرى', 'icon': '📦'},
  ];

  static const List<String> serviceCategories = [
    'مصمم',
    'مصور',
    'مدرس',
    'كهربائي',
    'سباك',
    'نجار',
    'ميكانيكي',
    'مبرمج',
    'مترجم',
    'كاتب محتوى',
    'مسوق إلكتروني',
    'مونتير',
  ];

  static const List<String> jobCategories = [
    'مبيعات',
    'توصيل',
    'تعليم',
    'بناء',
    'خدمات منزلية',
    'أخرى',
  ];

  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double borderRadius = 16.0;
  static const double borderRadiusLarge = 22.0;

  static const double deliveryFee = 5.0;
}
