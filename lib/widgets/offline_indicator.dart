import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:weather/l10n/app_localizations.g.dart';
import 'package:weather/services/connectivity_service.dart';
import 'package:weather/services/service_locator.dart';

/// A widget that shows an indicator when the device is offline
class OfflineIndicator extends StatefulWidget {
  /// The child widget to display
  final Widget child;

  /// Creates a new OfflineIndicator
  const OfflineIndicator({
    super.key,
    required this.child,
  });

  @override
  State<OfflineIndicator> createState() => _OfflineIndicatorState();
}

class _OfflineIndicatorState extends State<OfflineIndicator> {
  /// The connectivity service
  late final ConnectivityService _connectivityService;

  /// Subscription to connectivity changes
  StreamSubscription<ConnectivityResult>? _subscription;

  /// Whether the device is currently offline
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _connectivityService = serviceLocator.get<ConnectivityService>();

    // Check initial connectivity status
    _checkConnectivity();

    // Listen for connectivity changes
    _subscription =
        _connectivityService.connectionStatusStream.listen((result) {
      setState(() {
        _isOffline = result == ConnectivityResult.none;
      });
    });
  }

  /// Checks the current connectivity status
  Future<void> _checkConnectivity() async {
    final result = await _connectivityService.checkConnectivity();
    setState(() {
      _isOffline = result == ConnectivityResult.none;
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topLeft,
      // Using non-directional alignment instead of the default AlignmentDirectional.topStart
      children: [
        widget.child,
        if (_isOffline) _buildOfflineIndicator(context),
      ],
    );
  }

  /// Builds the offline indicator banner
  Widget _buildOfflineIndicator(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Material(
        color: Colors.transparent,
        child: Container(
          color: theme.colorScheme.error,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                const Icon(
                  Icons.wifi_off,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    localizations.networkError,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _checkConnectivity,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(localizations.retry),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
