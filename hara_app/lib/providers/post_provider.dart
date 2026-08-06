import 'package:flutter/foundation.dart';
import '../models/post_model.dart';
import '../services/api_client.dart';
import '../services/local_store.dart';

class PostProvider extends ChangeNotifier {
  static const String _key = 'posts';

  List<PostModel> _posts = [];

  List<PostModel> get posts {
    final sorted = [..._posts];
    sorted.sort((a, b) => b.time.compareTo(a.time));
    return sorted;
  }

  Future<void> load() async {
    try {
      final res = await ApiClient.instance.get('api/posts');
      _posts = (res as List)
          .map((m) => PostModel.fromMap(m as Map<String, dynamic>))
          .toList();
      await _save();
      notifyListeners();
      return;
    } on ApiException {
      // offline fallback
    }
    _posts = LocalStore.instance
        .getList(_key)
        .map((m) => PostModel.fromMap(m))
        .toList();
    if (_posts.isEmpty) {
      _seedDemo();
      await _save();
    }
    notifyListeners();
  }

  void _seedDemo() {
    final now = DateTime.now();
    _posts = [
      PostModel(
        id: 'post1',
        author: 'محمد أبو أحمد',
        role: 'بائع',
        avatarKey: 'store',
        category: 'عرض',
        time: now.subtract(const Duration(minutes: 25)),
        text: 'وصلت دفعة جديدة من زيت الزيتون البلدي 🍃 طلبك اليوم توصيل مجاني داخل الخليل.',
        hasImage: true,
        likes: 34,
        comments: 7,
      ),
      PostModel(
        id: 'post2',
        author: 'رنا عودة',
        role: 'مستخدمة',
        avatarKey: 'person',
        category: 'سؤال',
        time: now.subtract(const Duration(hours: 1, minutes: 10)),
        text: 'مين جرب التوصيل بالليل؟ سريع ولّا بطيء؟ وبكم التكلفة تقريباً من البيرة لرام الله؟',
        likes: 12,
        comments: 19,
      ),
      PostModel(
        id: 'post3',
        author: 'خالد حسن',
        role: 'موصل',
        avatarKey: 'motor',
        category: 'تحديث',
        time: now.subtract(const Duration(hours: 3)),
        text: 'جاهز اليوم للتوصيل السريع من الساعة 4 لمدة 10. المسافة الأقصى 15 كيلومتر. يسعدني خدمتكم.',
        hasImage: true,
        likes: 48,
        comments: 11,
      ),
      PostModel(
        id: 'post4',
        author: 'سامي عوض',
        role: 'بائع',
        avatarKey: 'store',
        category: 'عرض',
        time: now.subtract(const Duration(hours: 5)),
        text: 'شنط يدوية مطرزة يدوياً بألوان مميزة 🎨 متوفرة بثلاث مقاسات. أول 5 طلبات بخصم 15%.',
        hasImage: true,
        likes: 27,
        comments: 5,
      ),
      PostModel(
        id: 'post5',
        author: 'محمود جبارين',
        role: 'مستخدم',
        avatarKey: 'person',
        category: 'مشكلة',
        time: now.subtract(const Duration(hours: 8)),
        text: 'أحد المحلات ما أرسل طلبي من يومين 😟 مين عنده تجربة بيكيف بتتعاملوا مع الحالة هيك؟',
        likes: 9,
        comments: 23,
      ),
    ];
  }

  Future<void> toggleLike(String id) async {
    try {
      final res = await ApiClient.instance.post('api/posts/$id/like', {});
      _replace(res as Map<String, dynamic>);
      await _save();
      notifyListeners();
      return;
    } on ApiException {
      // offline fallback
    }
    final idx = _posts.indexWhere((p) => p.id == id);
    if (idx < 0) return;
    final p = _posts[idx];
    _posts[idx] = PostModel(
      id: p.id,
      author: p.author,
      role: p.role,
      avatarKey: p.avatarKey,
      category: p.category,
      time: p.time,
      text: p.text,
      hasImage: p.hasImage,
      likes: p.likes + (p.liked ? -1 : 1),
      comments: p.comments,
      liked: !p.liked,
    );
    await _save();
    notifyListeners();
  }

  Future<void> addPost({
    required String author,
    required String role,
    required String avatarKey,
    required String category,
    required String text,
    bool hasImage = false,
  }) async {
    try {
      final res = await ApiClient.instance.post('api/posts', {
        'category': category,
        'text': text,
        'hasImage': hasImage,
      });
      final post = PostModel.fromMap(res as Map<String, dynamic>);
      _posts.insert(0, post);
      await _save();
      notifyListeners();
      return;
    } on ApiException {
      // offline fallback
    }
    final post = PostModel(
      id: 'post${DateTime.now().millisecondsSinceEpoch}',
      author: author,
      role: role,
      avatarKey: avatarKey,
      category: category,
      time: DateTime.now(),
      text: text,
      hasImage: hasImage,
    );
    _posts.insert(0, post);
    await _save();
    notifyListeners();
  }

  void _replace(Map<String, dynamic> map) {
    final p = PostModel.fromMap(map);
    final idx = _posts.indexWhere((x) => x.id == p.id);
    if (idx >= 0) {
      _posts[idx] = p;
    } else {
      _posts.insert(0, p);
    }
  }

  Future<void> _save() {
    return LocalStore.instance
        .saveCollection(_key, _posts.map((p) => p.toMap()).toList());
  }
}
