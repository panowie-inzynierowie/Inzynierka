enum Author { llm, user }

class ChatMessage {
  final Author author;
  final String content;

  ChatMessage({required this.content, this.author = Author.llm});
}
