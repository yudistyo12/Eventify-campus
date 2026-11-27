import 'package:eventify_campus/services/database_helper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('dark mode preference is persisted independently', () async {
    SharedPreferences.setMockInitialValues({});

    expect(await DatabaseHelper.isDarkModeEnabled(), isFalse);

    await DatabaseHelper.setDarkModeEnabled(true);
    expect(await DatabaseHelper.isDarkModeEnabled(), isTrue);

    await DatabaseHelper.clearLocalData();
    expect(await DatabaseHelper.isDarkModeEnabled(), isTrue);

    await DatabaseHelper.setDarkModeEnabled(false);
    expect(await DatabaseHelper.isDarkModeEnabled(), isFalse);
  });
}
