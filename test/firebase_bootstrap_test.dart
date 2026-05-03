import 'package:apapane/config/firebase_bootstrap.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('iOS release App Check uses DeviceCheck without App Attest entitlement',
      () {
    expect(
      FirebaseBootstrap.appleProviderForTesting(debugMode: false),
      AppleProvider.deviceCheck,
    );
  });

  test('iOS debug App Check keeps the debug provider', () {
    expect(
      FirebaseBootstrap.appleProviderForTesting(debugMode: true),
      AppleProvider.debug,
    );
  });
}
