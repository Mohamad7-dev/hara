class ChatMessage {
  final String from; // 'me' | 'them'
  final String text;
  final String? img;
  final DateTime time;

  ChatMessage({
    required this.from,
    this.text = '',
    this.img,
    DateTime? time,
  }) : time = time ?? DateTime.now();

  bool get isMine => from == 'me';

  Map<String, dynamic> toMap() => {
        'from': from,
        'text': text,
        'img': img,
        'time': time.toIso8601String(),
      };

  factory ChatMessage.fromMap(Map<String, dynamic> map) => ChatMessage(
        from: map['from'] ?? 'them',
        text: map['text'] ?? '',
        img: map['img'],
        time: map['time'] != null
            ? DateTime.parse(map['time'].toString())
            : DateTime.now(),
      );
}

class ChatConversation {
  final String id;
  final String name;
  final String role;
  final String iconKey;
  int unread;
  final List<ChatMessage> messages;

  ChatConversation({
    required this.id,
    required this.name,
    this.role = '',
    this.iconKey = 'person',
    this.unread = 0,
    List<ChatMessage>? messages,
  }) : messages = messages ?? [];

  DateTime get lastTime =>
      messages.isEmpty ? DateTime.fromMillisecondsSinceEpoch(0) : messages.last.time;

  ChatMessage? get lastMessage =>
      messages.isEmpty ? null : messages.last;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'role': role,
        'iconKey': iconKey,
        'unread': unread,
        'messages': messages.map((m) => m.toMap()).toList(),
      };

  factory ChatConversation.fromMap(Map<String, dynamic> map) => ChatConversation(
        id: map['id'] ?? '',
        name: map['name'] ?? '',
        role: map['role'] ?? '',
        iconKey: map['iconKey'] ?? 'person',
        unread: (map['unread'] as num?)?.toInt() ?? 0,
        messages: (map['messages'] as List?)
                ?.map((e) => ChatMessage.fromMap(Map<String, dynamic>.from(e)))
                .toList() ??
            [],
      );
}
