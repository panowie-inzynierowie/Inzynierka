class Device {
  final int id;
  final String name;
  final String? description;
  final int spaceId;

  Device(
      {required this.id,
      required this.name,
      this.description,
      required this.spaceId});

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
        id: json['id'] ?? 0,
        name: json['name'] ?? '',
        description: json['description'],
        spaceId: json['space'] != null ? json['space']['id'] ?? 0 : 0);
  }
}
