import 'package:inzynierka_client/classes/space.dart';

class Device {
  final int id;
  final String name;
  final String? description;
  final Map<String, dynamic>? data;
  final Space? space;

  Device({
    required this.id,
    required this.name,
    this.description,
    this.data,
    this.space,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      data: json['data'],
      space: json['space'] != null ? Space.fromJson(json['space']) : null,
    );
  }

  @override
  String toString() {
    return name;
  }
}
