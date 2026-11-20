import 'package:eventify_campus/models/event_model.dart';
import 'package:eventify_campus/widgets/event_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final event = EventModel(
    id: 'public-event',
    name: 'Seminar Nasional',
    pic: 'Panitia',
    date: DateTime(2026, 12, 10, 9),
    location: 'Aula',
    description: 'Kegiatan kampus',
    status: 'Aktif',
    category: 'Seminar',
    createdAt: DateTime(2026, 11, 1),
    createdBy: 'owner-a',
  );

  Widget buildCard({required bool showActions}) {
    return MaterialApp(
      home: Scaffold(
        body: EventCard(
          event: event,
          showActions: showActions,
          onTap: () {},
          onEdit: () {},
          onDelete: () {},
        ),
      ),
    );
  }

  testWidgets('hides edit and delete controls for non-owners', (tester) async {
    await tester.pumpWidget(buildCard(showActions: false));

    expect(find.byTooltip('Edit Event'), findsNothing);
    expect(find.byTooltip('Hapus Event'), findsNothing);
    expect(find.text('Seminar Nasional'), findsOneWidget);
  });

  testWidgets('shows edit and delete controls for the owner', (tester) async {
    await tester.pumpWidget(buildCard(showActions: true));

    expect(find.byTooltip('Edit Event'), findsOneWidget);
    expect(find.byTooltip('Hapus Event'), findsOneWidget);
  });
}
