import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_colors.dart';

enum NetworkConnectionType {
  none,
  wifi,
  cellular,
  ethernet,
  vpn,
  other,
}

class NetworkStatus {
  final bool isOnline;
  final bool hasChecked;
  final NetworkConnectionType connectionType;
  final bool isReconnecting;
  final DateTime lastChecked;

  const NetworkStatus({
    required this.isOnline,
    required this.hasChecked,
    required this.connectionType,
    this.isReconnecting = false,
    required this.lastChecked,
  });

  factory NetworkStatus.initial() {
    return NetworkStatus(
      isOnline: true,
      hasChecked: false,
      connectionType: NetworkConnectionType.other,
      isReconnecting: false,
      lastChecked: DateTime.now(),
    );
  }

  NetworkStatus copyWith({
    bool? isOnline,
    bool? hasChecked,
    NetworkConnectionType? connectionType,
    bool? isReconnecting,
    DateTime? lastChecked,
  }) {
    return NetworkStatus(
      isOnline: isOnline ?? this.isOnline,
      hasChecked: hasChecked ?? this.hasChecked,
      connectionType: connectionType ?? this.connectionType,
      isReconnecting: isReconnecting ?? this.isReconnecting,
      lastChecked: lastChecked ?? this.lastChecked,
    );
  }

  String get label {
    if (!isOnline) return 'Offline';
    switch (connectionType) {
      case NetworkConnectionType.wifi:
        return 'Online (Wi-Fi)';
      case NetworkConnectionType.cellular:
        return 'Online (Seluler)';
      case NetworkConnectionType.ethernet:
        return 'Online (LAN)';
      case NetworkConnectionType.vpn:
        return 'Online (VPN)';
      case NetworkConnectionType.other:
        return 'Online';
      case NetworkConnectionType.none:
        return 'Offline';
    }
  }
}

class NetworkNotifier extends StateNotifier<NetworkStatus> {
  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _reconnectingTimer;

  NetworkNotifier([Connectivity? connectivity])
      : _connectivity = connectivity ?? Connectivity(),
        super(NetworkStatus.initial()) {
    _init();
  }

  Future<void> _init() async {
    try {
      final results = await _connectivity.checkConnectivity();
      await _evaluateConnectivity(results);
    } catch (_) {
      state = state.copyWith(isOnline: false, hasChecked: true);
    }

    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      _evaluateConnectivity(results);
    });
  }

  Future<void> _evaluateConnectivity(List<ConnectivityResult> results) async {
    final hasInterface = results.isNotEmpty &&
        !results.every((r) => r == ConnectivityResult.none);

    if (!hasInterface) {
      if (state.isOnline) {
        // Just went offline
        _reconnectingTimer?.cancel();
        state = state.copyWith(
          isOnline: false,
          hasChecked: true,
          connectionType: NetworkConnectionType.none,
          isReconnecting: false,
          lastChecked: DateTime.now(),
        );
      }
      return;
    }

    // Determine primary connection type
    NetworkConnectionType type = NetworkConnectionType.other;
    if (results.contains(ConnectivityResult.wifi)) {
      type = NetworkConnectionType.wifi;
    } else if (results.contains(ConnectivityResult.mobile)) {
      type = NetworkConnectionType.cellular;
    } else if (results.contains(ConnectivityResult.ethernet)) {
      type = NetworkConnectionType.ethernet;
    } else if (results.contains(ConnectivityResult.vpn)) {
      type = NetworkConnectionType.vpn;
    }

    // Ping check for genuine internet reachability
    final reachable = await _checkReachability();

    final wasOffline = !state.isOnline && state.hasChecked;

    if (reachable) {
      if (wasOffline) {
        // Trigger temporary reconnecting visual state
        state = state.copyWith(
          isOnline: true,
          hasChecked: true,
          connectionType: type,
          isReconnecting: true,
          lastChecked: DateTime.now(),
        );
        _reconnectingTimer?.cancel();
        _reconnectingTimer = Timer(const Duration(milliseconds: 2500), () {
          if (mounted) {
            state = state.copyWith(isReconnecting: false);
          }
        });
      } else {
        state = state.copyWith(
          isOnline: true,
          hasChecked: true,
          connectionType: type,
          isReconnecting: false,
          lastChecked: DateTime.now(),
        );
      }
    } else {
      state = state.copyWith(
        isOnline: false,
        hasChecked: true,
        connectionType: type,
        isReconnecting: false,
        lastChecked: DateTime.now(),
      );
    }
  }

  Future<bool> _checkReachability() async {
    try {
      final lookup = await InternetAddress.lookup('student.amikompurwokerto.ac.id')
          .timeout(const Duration(milliseconds: 2500));
      if (lookup.isNotEmpty && lookup[0].rawAddress.isNotEmpty) {
        return true;
      }
    } catch (_) {
      try {
        final fallback = await InternetAddress.lookup('google.com')
            .timeout(const Duration(milliseconds: 2000));
        return fallback.isNotEmpty && fallback[0].rawAddress.isNotEmpty;
      } catch (_) {
        return false;
      }
    }
    return false;
  }

  /// Manually trigger a fresh check (e.g. from Retry button)
  Future<bool> refreshStatus() async {
    try {
      final results = await _connectivity.checkConnectivity();
      await _evaluateConnectivity(results);
      return state.isOnline;
    } catch (_) {
      state = state.copyWith(isOnline: false, hasChecked: true);
      return false;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _reconnectingTimer?.cancel();
    super.dispose();
  }
}

final networkStatusProvider =
    StateNotifierProvider<NetworkNotifier, NetworkStatus>((ref) {
  return NetworkNotifier();
});

/// Reusable Guard Helper for Online Actions (Presensi validation, Refresh, etc.)
bool ensureOnline(
  BuildContext context,
  WidgetRef ref, {
  String message = 'Fitur ini memerlukan koneksi internet aktif.',
}) {
  final status = ref.read(networkStatusProvider);
  if (!status.isOnline) {
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(LucideIcons.wifiOff, color: AppColors.neutral0, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppColors.neutral0,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Cek Ulang',
          textColor: AppColors.neutral0,
          onPressed: () {
            ref.read(networkStatusProvider.notifier).refreshStatus();
          },
        ),
      ),
    );
    return false;
  }
  return true;
}
