class PostModel {
  final String id;
  final String author;
  final String role;
  final String avatarKey;
  final String category; // منشور | سؤال | مشكلة | عرض | تحديث
  final DateTime time;
  final String text;
  final bool hasImage;
  final int likes;
  final int comments;
  final bool liked;

  const PostModel({
    required this.id,
    required this.author,
    required this.role,
    required this.avatarKey,
    required this.category,
    required this.time,
    required this.text,
    this.hasImage = false,
    this.likes = 0,
    this.comments = 0,
    this.liked = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'author': author,
        'role': role,
        'avatarKey': avatarKey,
        'category': category,
        'time': time.toIso8601String(),
        'text': text,
        'hasImage': hasImage,
        'likes': likes,
        'comments': comments,
        'liked': liked,
      };

  factory PostModel.fromMap(Map<String, dynamic> map) => PostModel(
        id: map['id'] ?? '',
        author: map['author'] ?? '',
        role: map['role'] ?? '',
        avatarKey: map['avatarKey'] ?? 'person',
        category: map['category'] ?? 'منشور',
        time: map['time'] != null
            ? DateTime.parse(map['time'].toString())
            : DateTime.now(),
        text: map['text'] ?? '',
        hasImage: map['hasImage'] ?? false,
        likes: (map['likes'] as num?)?.toInt() ?? 0,
        comments: (map['comments'] as num?)?.toInt() ?? 0,
        liked: map['liked'] ?? false,
      );
}
