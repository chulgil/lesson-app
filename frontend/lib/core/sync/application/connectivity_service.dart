import 'package:connectivity_plus/connectivity_plus.dart';

enum SyncConnectivity { online, offline, unknown }

class ConnectivityService {
  ConnectivityService([Connectivity? connectivity])
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  Future<SyncConnectivity> get current async {
    final result = await _connectivity.checkConnectivity();
    return _toSyncConnectivityFromList(result);
  }

  Stream<SyncConnectivity> get connectivityChanges {
    return _connectivity.onConnectivityChanged.map(_toSyncConnectivityFromList);
  }

  SyncConnectivity _toSyncConnectivityFromList(
    List<ConnectivityResult> result,
  ) {
    if (result.isEmpty) {
      return SyncConnectivity.unknown;
    }

    if (result.contains(ConnectivityResult.none)) {
      return SyncConnectivity.offline;
    }
    if (result.contains(ConnectivityResult.ethernet)) {
      return SyncConnectivity.online;
    }
    if (result.contains(ConnectivityResult.wifi)) {
      return SyncConnectivity.online;
    }
    if (result.contains(ConnectivityResult.mobile)) {
      return SyncConnectivity.online;
    }

    return _toSyncConnectivity(result.first);
  }

  SyncConnectivity _toSyncConnectivity(ConnectivityResult result) {
    if (result == ConnectivityResult.bluetooth ||
        result == ConnectivityResult.other) {
      return SyncConnectivity.online;
    }
    if (result == ConnectivityResult.none) {
      return SyncConnectivity.offline;
    }
    return SyncConnectivity.online;
  }

  Future<bool> get isOnline async {
    return (await current) == SyncConnectivity.online;
  }
}
