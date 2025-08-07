import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:weather/app_state.dart';
import 'package:weather/l10n/app_localizations.g.dart';
import 'package:weather/main.dart' show showGlobalSnackBar;
import 'package:weather/viewmodels/home_view_model.dart';
import 'package:weather/widgets/home/no_locations_widget.dart';
import 'package:weather/widgets/home/weather_content_widget.dart';
import 'package:weather/widgets/skeleton/weather_skeleton.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin<HomePage>, WidgetsBindingObserver {
  late HomeViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    final appState = Provider.of<AppState>(context, listen: false);
    _viewModel = HomeViewModel(appState: appState);

    // Load initial forecast when the widget is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel.loadInitialForecast();
    });

    // Add observer for app lifecycle changes
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App has come back to the foreground
      final appState = Provider.of<AppState>(context, listen: false);
      if (appState.geolocationEnabled) {
        // Only reload if geolocation is enabled in app settings
        _viewModel.loadInitialForecast();
      }
      WidgetsBinding.instance.removeObserver(this);
    }
  }

  @override
  void dispose() {
    _viewModel.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Call super to ensure keep alive works

    final localizations = AppLocalizations.of(context)!;

    // Use AnimatedBuilder to rebuild when the ViewModel changes
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, child) {
        // Check if we need to load initial forecast
        if (!_viewModel.isLoading &&
            _viewModel.forecast == null &&
            (_viewModel.locations.isNotEmpty ||
                Provider.of<AppState>(context, listen: false)
                    .geolocationEnabled)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _viewModel.loadInitialForecast();
          });
        }

        // Show error message if there is one
        if (_viewModel.errorMessage != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            showGlobalSnackBar(
              message: _viewModel.errorMessage!,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: localizations.retry,
                onPressed: _viewModel.retryGeolocation,
              ),
            );
          });
        }

        return Scaffold(
          body: SafeArea(
            child: _buildContent(localizations),
          ),
        );
      },
    );
  }

  /// Builds the main content based on the current state
  Widget _buildContent(AppLocalizations localizations) {
    // Use LayoutBuilder to determine screen size for the skeleton
    return LayoutBuilder(builder: (context, constraints) {
      final isWideScreen = constraints.maxWidth > 900;

      if (_viewModel.isLoading) {
        // Show skeleton loading screen when loading
        return WeatherSkeleton(isWideScreen: isWideScreen);
      }

      if (_viewModel.forecast == null || _viewModel.locations.isEmpty) {
        return const NoLocations();
      }

      // Wrap with RefreshIndicator for pull-to-refresh functionality
      return RefreshIndicator(
        onRefresh: _viewModel.refreshForecast,
        child: SingleChildScrollView(
          // Ensure the SingleChildScrollView can be scrolled even when content is small
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              WeatherContentWidget(
                forecast: _viewModel.forecast!,
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      );
    });
  }
}

