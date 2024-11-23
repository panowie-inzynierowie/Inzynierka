class Space {
  String name;
  final String? description;
  final int id;

  Space({required this.name, this.description, required this.id});

  factory Space.fromJson(Map<String, dynamic> json) {
    return Space(
      name: json['name'] ?? '',
      description: json['description'],
      id: json['id'], // Ensure id is parsed correctly
    );
  }
}
