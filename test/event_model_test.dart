import 'package:flutter_test/flutter_test.dart';
import 'package:eventify_campus/models/event_model.dart';

void main() {
  final event = EventModel(
    id: 'event-1',
    name: 'Seminar',
    pic: 'Panitia',
    date: DateTime(2026, 12, 10, 9),
    location: 'Auditorium',
    description: 'Deskripsi',
    status: 'Aktif',
    category: 'Seminar',
    createdAt: DateTime(2026, 11, 1),
    createdBy: 'owner-uid',
    isPublished: true,
    reminderDaysBefore: const [7, 1, 0],
  );

  test('reminder options survive JSON serialization', () {
    final restored = EventModel.fromJson(event.toJson());

    expect(restored.reminderDaysBefore, [7, 1, 0]);
  });

  test('reminder options survive Firestore serialization', () {
    final restored = EventModel.fromFirestore(event.toMap(), event.id);

    expect(restored.reminderDaysBefore, [7, 1, 0]);
    expect(restored.createdBy, 'owner-uid');
    expect(restored.isPublished, isTrue);
  });

  test(
    'existing Firestore events default to the previous one-day reminder',
    () {
      final restored = EventModel.fromFirestore({
        'name': event.name,
        'pic': event.pic,
        'date': event.date.toIso8601String(),
        'location': event.location,
        'description': event.description,
        'status': event.status,
        'category': event.category,
        'createdAt': event.createdAt.toIso8601String(),
      }, event.id);

      expect(restored.reminderDaysBefore, [1]);
      expect(restored.createdBy, isEmpty);
      expect(restored.isPublished, isTrue);
    },
  );

  test('only supported reminder offsets are loaded', () {
    final restored = EventModel.fromJson({
      ...event.toJson(),
      'reminderDaysBefore': [7, 2, 1, 1, -1],
    });

    expect(restored.reminderDaysBefore, [7, 1]);
  });
}
