import 'dart:convert';

class DiaryEntry {
  final String id;
  final String date;
  final String content;
  final String mood;
  final List<String> keywords;
  final String source; // 'chat' or 'manual'
  final List<ChatMessage> conversations;
  final int createdAt;
  final int updatedAt;

  DiaryEntry({
    required this.id,
    required this.date,
    required this.content,
    required this.mood,
    required this.keywords,
    required this.source,
    required this.conversations,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'content': content,
      'mood': mood,
      'keywords': keywords.join(','),
      'source': source,
      'conversations': jsonEncode(conversations.map((c) => c.toMap()).toList()),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory DiaryEntry.fromMap(Map<String, dynamic> map) {
    List<ChatMessage> convos = [];
    final convStr = map['conversations'] as String?;
    if (convStr != null && convStr.isNotEmpty) {
      try {
        final List<dynamic> parsed = jsonDecode(convStr);
        convos = parsed.map((e) => ChatMessage.fromMap(e as Map<String, dynamic>)).toList();
      } catch (_) {}
    }

    return DiaryEntry(
      id: map['id'] as String,
      date: map['date'] as String,
      content: map['content'] as String,
      mood: map['mood'] as String,
      keywords: (map['keywords'] as String).split(',').where((s) => s.isNotEmpty).toList(),
      source: map['source'] as String,
      conversations: convos,
      createdAt: map['createdAt'] as int,
      updatedAt: map['updatedAt'] as int,
    );
  }

  DiaryEntry copyWith({
    String? content,
    String? mood,
    List<String>? keywords,
    List<ChatMessage>? conversations,
    int? updatedAt,
  }) {
    return DiaryEntry(
      id: id,
      date: date,
      content: content ?? this.content,
      mood: mood ?? this.mood,
      keywords: keywords ?? this.keywords,
      source: source,
      conversations: conversations ?? this.conversations,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ChatMessage {
  final String role;
  final String content;
  final int timestamp;

  ChatMessage({
    required this.role,
    required this.content,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {'role': role, 'content': content, 'timestamp': timestamp};
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      role: map['role'] as String,
      content: map['content'] as String,
      timestamp: map['timestamp'] as int,
    );
  }
}

const Map<String, String> moodEmojis = {
  '开心': '😊',
  '平静': '😌',
  '感动': '🥺',
  '低落': '😢',
  '焦虑': '😰',
  '疲惫': '😴',
  '生气': '😤',
};
