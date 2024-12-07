enum Author { llm, user }

class ChatMessage {
  final Author author;
  final String content;

  ChatMessage({required this.author, required this.content});

  Map<String, dynamic> toJson() {
    return {
      'author': author.toString(),
      'content': content,
    };
  }
}
