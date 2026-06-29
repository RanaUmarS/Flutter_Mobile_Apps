import 'package:flutter_test/flutter_test.dart';
import 'package:user_repository/user_repository.dart';
import 'package:user_repository/src/models/model.dart';

void main() {
  group('MyUser', () {
    test('supports value equality', () {
      expect(
        MyUser(
          userID: '1',
          email: 'email',
          name: 'name',
          hasActiveCart: true,
        ),
        equals(
          MyUser(
            userID: '1',
            email: 'email',
            name: 'name',
            hasActiveCart: true,
          ),
        ),
      );
    });

    test('copyWith creates a new instance with updated values', () {
      final user = MyUser(
        userID: '1',
        email: 'email',
        name: 'name',
        hasActiveCart: true,
      );
      expect(
        user.copyWith(name: 'new name'),
        equals(
          MyUser(
            userID: '1',
            email: 'email',
            name: 'new name',
            hasActiveCart: true,
          ),
        ),
      );
    });
  });
}
