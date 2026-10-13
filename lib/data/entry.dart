import 'package:uuid/uuid.dart';

class Entry {
  const Entry({
    required this.id,
    required this.entryDate,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.updatedAt,
    this.mood,
  });

  final String id;

  /// The writer's local date, `yyyy-MM-dd`. One entry per day.
  final String entryDate;
  final String title;
  final String body;
  final int? mood;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Entry.blank(String entryDate) {
    final now = DateTime.now().toUtc();
    return Entry(
      id: Uuid().v4(),
      entryDate: entryDate,
      title: '',
      body: '',
      createdAt: now,
      updatedAt: now,
    );
  }

  Entry edited({
    required String title,
    required String body,
    required int? mood,
  }) {
    return Entry(
      id: id,
      entryDate: entryDate,
      title: title,
      body: body,
      mood: mood,
      createdAt: createdAt,
      updatedAt: DateTime.now().toUtc(),
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'entry_date': entryDate,
    'title': title,
    'body': body,
    'mood': mood,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory Entry.fromMap(Map<String, Object?> m) {
    return Entry(
      id: m['id'] as String,
      entryDate: m['entry_date'] as String,
      title: m['title'] as String,
      body: m['body'] as String,
      mood: m['mood'] as int?,
      createdAt: DateTime.parse(m['created_at'] as String),
      updatedAt: DateTime.parse(m['updated_at'] as String),
    );
  }
}
