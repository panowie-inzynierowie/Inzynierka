import 'package:flutter_test/flutter_test.dart';
import 'package:inzynierka_client/classes/chat.dart';
void main() {
  group('ChatMessage tests', () {
    test('Constructor assigns values correctly', () {
      final message = ChatMessage(author: Author.user, content: 'Hello');
      expect(message.author, Author.user);
      expect(message.content, 'Hello');
    });

    test('toJson returns correct Map', () {
      final message = ChatMessage(author: Author.llm, content: 'Reply');
      final json = message.toJson();
      expect(json, isA<Map<String, dynamic>>());
      expect(json['author'], equals(Author.llm.toString()));
      expect(json['content'], equals('Reply'));
    });
  });
}
