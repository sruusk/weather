import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:weather/utils/logger.dart';

/// Service for checking and monitoring network connectivity
class ConnectivityService {
  /// Singleton instance
  static final ConnectivityService _instance = ConnectivityService._internal();

  /// Factory constructor to return the singleton instance
  factory ConnectivityService() => _instance;

  /// Private constructor
  ConnectivityService._internal() {
    // Initialize connectivity monitoring
    _initConnectivity();
    _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  /// The connectivity plugin instance
  final Connectivity _connectivity = Connectivity();

  /// Current connectivity status
  ConnectivityResult _connectionStatus = ConnectivityResult.none;

  /// Stream controller for connectivity status updates
  final _connectionStatusController =
      StreamController<ConnectivityResult>.broadcast();

  /// Stream of connectivity status updates
  Stream<ConnectivityResult> get connectionStatusStream =>
      _connectionStatusController.stream;

  /// Current connectivity status
  ConnectivityResult get connectionStatus => _connectionStatus;

  /// Whether the device is currently connected to the internet
  bool get isConnected => _connectionStatus != ConnectivityResult.none;

  /// Whether the device is currently connected to a mobile network
  bool get isConnectedMobile => _connectionStatus == ConnectivityResult.mobile;

  /// Whether the device is currently connected to a WiFi network
  bool get isConnectedWifi => _connectionStatus == ConnectivityResult.wifi;

  /// Whether the device is currently connected to an ethernet network
  bool get isConnectedEthernet =>
      _connectionStatus == ConnectivityResult.ethernet;

  /// Initializes the connectivity monitoring
  Future<void> _initConnectivity() async {
    try {
      _connectionStatus = await _connectivity.checkConnectivity();
      _connectionStatusController.add(_connectionStatus);
      Logger.debug('Initial connectivity status: $_connectionStatus');
    } catch (e) {
      Logger.error('Error checking connectivity', e);
    }
  }

  /// Updates the connection status and notifies listeners
  void _updateConnectionStatus(ConnectivityResult result) {
    if (_connectionStatus != result) {
      _connectionStatus = result;
      _connectionStatusController.add(result);
      Logger.debug('Connectivity changed: $result');
    }
  }

  /// Checks the current connectivity status
  Future<ConnectivityResult> checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
      return result;
    } catch (e) {
      Logger.error('Error checking connectivity', e);
      return ConnectivityResult.none;
    }
  }

  /// Disposes of the connectivity service
  void dispose() {
    _connectionStatusController.close();
  }
}
