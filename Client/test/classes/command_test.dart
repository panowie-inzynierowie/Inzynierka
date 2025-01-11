import 'package:test/test.dart';
import 'package:inzynierka_client/classes/command.dart';

void main() {
  group('Command', () {
    test('Command.fromJson correctly parses valid JSON', () {
      final json = {
        'id': 1,
        'description': 'Test command',
        'scheduled_at': '2025-01-01T12:00:00Z',
        'devices': [
          {'id': 101},
          {'id': 102}
        ],
      };
      final command = Command.fromJson(json);

      expect(command.id, 1);
      expect(command.description, 'Test command');
      expect(command.scheduledAt, DateTime.parse('2025-01-01T12:00:00Z'));
      expect(command.deviceIds, [101, 102]);
    });

    test('Command.fromJson handles missing fields', () {
      final json = {
        'description': 'Partial command',
        'devices': [],
      };
      final command = Command.fromJson(json);

      expect(command.id, 0);
      expect(command.description, 'Partial command');
      expect(command.scheduledAt, isNull);
      expect(command.deviceIds, isEmpty);
    });
  });
}
