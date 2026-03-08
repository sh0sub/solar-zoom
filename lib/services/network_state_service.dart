import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

typedef ConnectivityCheck = Future<dynamic> Function();
typedef ConnectivityChanges = Stream<dynamic> Function();

abstract class NetworkStateReader {
  Future<bool> isOnline();
  Stream<bool> onlineStatusChanges();
}

class NetworkStateService implements NetworkStateReader {
  final ConnectivityCheck _checkConnectivity;
  final ConnectivityChanges _connectivityChanges;

  NetworkStateService({
    Connectivity? connectivity,
    ConnectivityCheck? checkConnectivity,
    ConnectivityChanges? connectivityChanges,
  }) : this._(
         connectivity: connectivity ?? Connectivity(),
         checkConnectivity: checkConnectivity,
         connectivityChanges: connectivityChanges,
       );

  NetworkStateService._({
    required Connectivity connectivity,
    ConnectivityCheck? checkConnectivity,
    ConnectivityChanges? connectivityChanges,
  }) : _checkConnectivity = checkConnectivity ?? connectivity.checkConnectivity,
       _connectivityChanges =
           connectivityChanges ?? (() => connectivity.onConnectivityChanged);

  @override
  Future<bool> isOnline() async {
    final dynamic result = await _checkConnectivity();
    return _hasNetwork(result);
  }

  @override
  Stream<bool> onlineStatusChanges() {
    return _connectivityChanges()
        .map((dynamic result) => _hasNetwork(result))
        .distinct();
  }

  bool _hasNetwork(dynamic result) {
    if (result is ConnectivityResult) {
      return result != ConnectivityResult.none;
    }
    if (result is List<ConnectivityResult>) {
      return result.any(
        (ConnectivityResult item) => item != ConnectivityResult.none,
      );
    }
    return false;
  }
}
