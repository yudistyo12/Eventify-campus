import 'package:flutter_test/flutter_test.dart';
import 'package:eventify_campus/services/notification_service.dart';

void main() {
  test('cleanup is safe before notifications are initialized', () async {
    final service = NotificationService();

    await service.cancelAll();
    await service.cancelEventReminders('event-1');

    expect(await service.getPendingNotifications(), isEmpty);
  });
}
