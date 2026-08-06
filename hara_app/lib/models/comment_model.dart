class CommentModel {
  final String id;
  final String kind; // 'post' | 'product'
  final String targetId;
  final String author;
  final String role;
  final String avatarKey;
  final String text;
  final int rating; // 0 للتعليقات، 1-5 للتقييمات
  final DateTime time;
  final List<CommentModel> replies;

  const CommentModel({
    required this.id,
    required this.kind,
    required this.targetId,
    required this.author,
    required this.role,
    required this.avatarKey,
    required this.text,
    this.rating = 0,
    required this.time,
    this.replies = const [],
  });

  CommentModel copyWith({List<CommentModel>? replies}) => CommentModel(
        id: id,
        kind: kind,
        targetId: targetId,
        author: author,
        role: role,
        avatarKey: avatarKey,
        text: text,
        rating: rating,
        time: time,
        replies: replies ?? this.replies,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'kind': kind,
        'targetId': targetId,
        'author': author,
        'role': role,
        'avatarKey': avatarKey,
        'text': text,
        'rating': rating,
        'time': time.toIso8601String(),
        'replies': replies.map((r) => r.toMap()).toList(),
      };

  factory CommentModel.fromMap(Map<String, dynamic> map) => CommentModel(
        id: map['id'] ?? '',
        kind: map['kind'] ?? 'post',
        targetId: map['targetId'] ?? '',
        author: map['author'] ?? '',
        role: map['role'] ?? '',
        avatarKey: map['avatarKey'] ?? 'person',
        text: map['text'] ?? '',
        rating: (map['rating'] as num?)?.toInt() ?? 0,
        time: map['time'] != null
            ? DateTime.parse(map['time'].toString())
            : DateTime.now(),
        replies: map['replies'] != null
            ? (map['replies'] as List)
                .map((r) => CommentModel.fromMap(Map<String, dynamic>.from(r)))
                .toList()
            : const [],
      );
}
