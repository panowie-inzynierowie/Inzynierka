import 'package:flutter_test/flutter_test.dart';
import 'package:inzynierka_client/classes/chat.dart';

void main() {
  group('ChatMessage', () {
    test('ChatMessage is correctly instantiated', () {
      final message = ChatMessage(author: Author.user, content: 'Hello');
      expect(message.author, Author.user);
      expect(message.content, 'Hello');
    });

    test('toJson returns correct map', () {
      final message = ChatMessage(author: Author.llm, content: 'Test content');
      final json = message.toJson();

      expect(json['author'], 'Author.llm');
      expect(json['content'], 'Test content');
    });
  });
}

