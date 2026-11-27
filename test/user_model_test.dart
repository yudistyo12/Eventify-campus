import 'package:eventify_campus/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const userId = 'user-1';

  Map<String, dynamic> userData({Object? role = 'user'}) {
    final Map<String, dynamic> data = {
      'name': 'Faris',
      'email': 'faris@example.com',
      'nim': '12345',
      'major': 'Informatika',
    };
    if (role != null) data['role'] = role;
    return data;
  }

  test('parses explicitly assigned user and admin roles', () {
    expect(UserModel.fromMap(userData(), userId).role, 'user');
    expect(UserModel.fromMap(userData(role: 'admin'), userId).isAdmin, isTrue);
  });

  test('rejects missing and invalid roles', () {
    expect(
      () => UserModel.fromMap(userData(role: null), userId),
      throwsFormatException,
    );
    expect(
      () => UserModel.fromMap(userData(role: 'owner'), userId),
      throwsFormatException,
    );
  });
}
