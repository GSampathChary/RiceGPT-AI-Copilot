class ChatMessage {
  ChatMessage({
    required this.role,
    required this.content,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String role;
  final String content;
  final DateTime createdAt;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      role: json['role'] as String? ?? 'assistant',
      content: json['content'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'role': role,
        'content': content,
        'created_at': createdAt.toIso8601String(),
      };
}

class ChatThread {
  ChatThread({
    required this.id,
    required this.query,
    required this.answer,
    required this.provider,
    required this.createdAt,
    required this.context,
  });

  final String id;
  final String query;
  final String answer;
  final String provider;
  final DateTime createdAt;
  final String context;

  factory ChatThread.fromJson(Map<String, dynamic> json) {
    return ChatThread(
      id: json['id'] as String? ?? '',
      query: json['query'] as String? ?? '',
      answer: json['answer'] as String? ?? '',
      provider: json['provider'] as String? ?? 'gemini',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      context: json['disease_context'] as String? ?? '',
    );
  }
}

