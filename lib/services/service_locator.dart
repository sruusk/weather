import 'package:weather/repositories/weather_repository.dart';
import 'package:weather/repositories/weather_repository_impl.dart';
import 'package:weather/services/connectivity_service.dart';
import 'package:weather/utils/logger.dart';

/// A simple service locator for dependency injection
///
/// This class provides a way to register and access services and repositories
/// throughout the application without directly instantiating them.
class ServiceLocator {
  // Private constructor
  ServiceLocator._();

  // Singleton instance
  static final ServiceLocator _instance = ServiceLocator._();

  // Factory constructor to return the singleton instance
  factory ServiceLocator() => _instance;

  // Map to store registered services
  final Map<Type, dynamic> _services = {};

  /// Registers a service with the service locator
  ///
  /// If [singleton] is true, the service will be created once and reused.
  /// If [singleton] is false, a new instance will be created each time.
  void register<T>(T Function() factory, {bool singleton = true}) {
    if (singleton) {
      // For singletons, create the instance immediately and store it
      final instance = factory();
      _services[T] = instance;
      Logger.debug('Registered singleton service: ${T.toString()}');
    } else {
      // For non-singletons, store the factory function
      _services[T] = factory;
      Logger.debug('Registered factory service: ${T.toString()}');
    }
  }

  /// Gets a service from the service locator
  ///
  /// Throws an exception if the service is not registered.
  T get<T>() {
    final service = _services[T];

    if (service == null) {
      throw Exception('Service not registered: ${T.toString()}');
    }

    // If the service is a factory function, call it to create a new instance
    if (service is Function) {
      return service();
    }

    // Otherwise, return the singleton instance
    return service as T;
  }

  /// Checks if a service is registered
  bool isRegistered<T>() {
    return _services.containsKey(T);
  }

  /// Unregisters a service
  void unregister<T>() {
    _services.remove(T);
    Logger.debug('Unregistered service: ${T.toString()}');
  }

  /// Resets the service locator by removing all registered services
  void reset() {
    _services.clear();
    Logger.debug('Reset service locator');
  }
}

/// Global instance of the service locator for easy access
final serviceLocator = ServiceLocator();

/// Initializes the service locator with all required services
void setupServiceLocator() {
  Logger.debug('Setting up service locator');

  // Register services first
  serviceLocator.register<ConnectivityService>(() => ConnectivityService());

  // Register repositories that depend on services
  serviceLocator.register<WeatherRepository>(() => WeatherRepositoryImpl());

  Logger.debug('Service locator setup complete');
}
