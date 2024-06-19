class Command {
  final int id;
  final String description;
  final DateTime? scheduledAt;
  final List<int> deviceIds;

  Command({
    required this.id,
    required this.description,
    this.scheduledAt,
    required this.deviceIds,
  });

  factory Command.fromJson(Map<String, dynamic> json) {
    return Command(
      id: json['id'] ?? 0,
      description: json['description'] ?? '',
      scheduledAt: json['scheduled_at'] != null
          ? DateTime.parse(json['scheduled_at'])
          : null,
      deviceIds:
          List<int>.from(json['devices']?.map((device) => device['id']) ?? []),
    );
  }
}
