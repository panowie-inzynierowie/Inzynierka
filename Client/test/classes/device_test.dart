import 'package:test/test.dart';
import 'package:inzynierka_client/classes/device.dart';

void main() {
  group('Device', () {
    test('Device.fromJson parses valid JSON', () {
      final json = {
        'id': 10,
        'name': 'Device 1',
        'description': 'Test description',
        'data': {'key': 'value'},
        'space': {'name': 'Office', 'description': 'Main office', 'id': 1},
      };
      final device = Device.fromJson(json);

      expect(device.id, 10);
      expect(device.name, 'Device 1');
      expect(device.description, 'Test description');
      expect(device.data, {'key': 'value'});
      expect(device.space?.name, 'Office');
      expect(device.space?.id, 1);
    });

    test('Device.fromJson handles null space', () {
      final json = {
        'id': 20,
        'name': 'Device 2',
      };
      final device = Device.fromJson(json);

      expect(device.id, 20);
      expect(device.name, 'Device 2');
      expect(device.description, isNull);
      expect(device.space, isNull);
    });
  });
}
