class ChatMessage {
  final String id;
  final String from; // 'me' | 'them'
  final String text;
  final String? img;
  final String? audio;
  final bool read;
  final DateTime time;

  ChatMessage({
    this.id = '',
    required this.from,
    this.text = '',
    this.img,
    this.audio,
    this.read = false,
    DateTime? time,
  }) : time = time ?? DateTime.now();

  bool get isMine => from == 'me';
  bool get isAudio => audio != null && audio!.isNotEmpty;

  Map<String, dynamic> toMap() => {
        'id': id,
        'from': from,
        'text': text,
        'img': img,
        'audio': audio,
        'read': read,
        'time': time.toIso8601String(),
      };

  factory ChatMessage.fromMap(Map<String, dynamic> map) => ChatMessage(
        id: map['id'] ?? '',
        from: map['from'] ?? 'them',
        text: map['text'] ?? '',
        img: map['img'],
        audio: map['audio'],
        read: map['read'] ?? false,
        time: map['time'] != null
            ? DateTime.parse(map['time'].toString())
            : DateTime.now(),
      );
}

class ChatConversation {
  final String id;
  final String name;
  final String? photo;
  final String role;
  final String iconKey;
  int unread;
  final List<ChatMessage> messages;

  ChatConversation({
    required this.id,
    required this.name,
    this.photo,
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
        'photo': photo,
        'role': role,
        'iconKey': iconKey,
        'unread': unread,
        'messages': messages.map((m) => m.toMap()).toList(),
      };

  factory ChatConversation.fromMap(Map<String, dynamic> map) => ChatConversation(
        id: map['id'] ?? '',
        name: map['name'] ?? '',
        photo: map['photo'],
        role: map['role'] ?? '',
        iconKey: map['iconKey'] ?? 'person',
        unread: (map['unread'] as num?)?.toInt() ?? 0,
        messages: (map['messages'] as List?)
                ?.map((e) => ChatMessage.fromMap(Map<String, dynamic>.from(e)))
                .toList() ??
            [],
      );
}
