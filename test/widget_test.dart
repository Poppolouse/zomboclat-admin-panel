import 'package:flutter_test/flutter_test.dart';
import 'package:zomboclat_admin_panel/main.dart';

void main() {
  test('AppUser permissions check', () {
    const admin = AppUser(
      id: 1,
      username: 'admin',
      role: 'ADMIN',
      isAdmin: true,
    );
    expect(admin.canRestartServer, isTrue);
    expect(admin.isAdmin, isTrue);

    const op = AppUser(
      id: 2,
      username: 'operator',
      role: 'OPERATOR',
      isAdmin: false,
    );
    expect(op.canRestartServer, isTrue);
    expect(op.isAdmin, isFalse);

    const user = AppUser(id: 3, username: 'user', role: 'USER', isAdmin: false);
    expect(user.canRestartServer, isFalse);
    expect(user.isAdmin, isFalse);
  });
}
