import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:senior_magnifier/services/network_state_service.dart';

void main() {
  group('NetworkStateService', () {
    test('isOnline returns false when connectivity is none', () async {
      final service = NetworkStateService(
        checkConnectivity: () async => ConnectivityResult.none,
        connectivityChanges: () => const Stream<dynamic>.empty(),
      );

      expect(await service.isOnline(), isFalse);
    });

    test('isOnline returns true when connectivity is available', () async {
      final service = NetworkStateService(
        checkConnectivity: () async => ConnectivityResult.wifi,
        connectivityChanges: () => const Stream<dynamic>.empty(),
      );

      expect(await service.isOnline(), isTrue);
    });

    test('isOnline supports list-style connectivity result', () async {
      final service = NetworkStateService(
        checkConnectivity: () async => <ConnectivityResult>[
          ConnectivityResult.mobile,
          ConnectivityResult.wifi,
        ],
        connectivityChanges: () => const Stream<dynamic>.empty(),
      );

      expect(await service.isOnline(), isTrue);
    });

    test('onlineStatusChanges maps stream to booleans', () async {
      final controller = StreamController<dynamic>();
      final service = NetworkStateService(
        checkConnectivity: () async => ConnectivityResult.none,
        connectivityChanges: () => controller.stream,
      );

      final emitted = <bool>[];
      final sub = service.onlineStatusChanges().listen(emitted.add);

      controller.add(ConnectivityResult.none);
      controller.add(ConnectivityResult.wifi);
      controller.add(ConnectivityResult.mobile);

      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(emitted, <bool>[false, true]);

      await sub.cancel();
      await controller.close();
    });
  });
}
