import 'package:test/test.dart';
import 'package:inzynierka_client/classes/space.dart';

void main() {
  group('Space', () {
    test('Space.fromJson correctly parses JSON', () {
      final json = {
        'name': 'Living Room',
        'description': 'Main living area',
        'id': 5,
      };
      final space = Space.fromJson(json);

      expect(space.name, 'Living Room');
      expect(space.description, 'Main living area');
      expect(space.id, 5);
    });

    test('Space.fromJson handles missing optional fields', () {
      final json = {
        'name': 'Kitchen',
        'id': 6,
      };
      final space = Space.fromJson(json);

      expect(space.name, 'Kitchen');
      expect(space.description, isNull);
      expect(space.id, 6);
    });
  });
}
