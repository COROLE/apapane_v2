import 'package:apapane/models/auth/local_session_user.dart';
import 'package:apapane/repositories/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const user = LocalSessionUser(
    id: 'parent-uid',
    email: 'parent@example.com',
    displayName: 'Parent User',
    photoUrl: 'https://example.com/avatar.png',
    isAnonymous: false,
  );

  test('new signup profile starts with 5 coins', () {
    final profile = AuthRepository.buildNewProfile(
      user,
      now: 'now',
    );

    expect(profile.uid, user.uid);
    expect(profile.coins, AuthRepository.initialSignupCoins);
    expect(profile.userName, user.displayName);
    expect(profile.userImageURL, user.photoUrl);
  });

  test('existing profile updates never reset coins', () {
    final updates = AuthRepository.buildExistingProfileUpdates(
      currentProfile: const {
        'userName': 'Existing Parent',
        'userImageURL': '',
        'coins': 1,
      },
      user: user,
      now: 'updated-now',
    );

    expect(updates['userImageURL'], user.photoUrl);
    expect(updates['updatedAt'], 'updated-now');
    expect(updates.containsKey('coins'), isFalse);
  });
}
