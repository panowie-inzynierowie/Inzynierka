class Device {
  String name;
  String description;
  String oldName;

  Device({required this.name, this.description = 'Opis urządzenia'})
      : oldName = name;

  Device copyWith({String? name, String? description}) {
    return Device(
      name: name ?? this.name,
      description: description ?? this.description,
    )..oldName = oldName;
  }
}
