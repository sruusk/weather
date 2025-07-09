import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:flutter/foundation.dart';
import 'package:weather/app_state.dart';
import 'package:weather/data/location.dart';

enum SyncDirection { toAppwrite, fromAppwrite, both }

class AppwriteClient {
  static final AppwriteClient _instance = AppwriteClient._internal();
  late final Client client;
  late final Account account;
  late final Realtime realtime;
  RealtimeSubscription? subscription;
  AppState? _appState;

  factory AppwriteClient() {
    return _instance;
  }

  AppwriteClient._internal() {
    client = Client()
        .setEndpoint("https://aw.a32.fi/v1") // Replace with your endpoint
        .setProject("6843138e001dcb69f2be"); //// Replace with your project ID
    account = Account(client);
    realtime = Realtime(client);
  }

  Client get getClient => client;

  Account get getAccount => account;

  void setAppState(AppState state) {
    _appState = state;
  }

  Future<bool> isLoggedIn() async {
    try {
      await account.getSession(sessionId: 'current');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> syncFavourites(AppState appState,
      {SyncDirection direction = SyncDirection.both}) async {
    final databases = Databases(client);

    if (!await isLoggedIn()) {
      appState.setSyncFavouritesToAppwrite(false);
      unsubscribe();
      throw Exception('User is not logged in, disabling sync');
    }

    if(!appState.syncFavouritesToAppwrite) {
      unsubscribe();
      return;
    }

    final User user = await account.get();

    switch (direction) {
      case SyncDirection.toAppwrite:
        break;
      case SyncDirection.fromAppwrite:
        if ((await _getDbFavourites(databases)).total == 0) break;
        appState.removeAllLocalFavouriteLocations();
        break;
      case SyncDirection.both:
        break;
    }

    // First get the favourites from appwrite
    final List<(String, Location)> awFavourites =
        (await _getDbFavourites(databases)).documents.map((doc) {
      return (
        doc.$id,
        Location(
          lat: doc.data['lat'] as double,
          lon: doc.data['lon'] as double,
          name: doc.data['name'] as String,
          region: doc.data['region'] as String?,
          countryCode: doc.data['countryCode'] as String,
          country: doc.data['country'] as String?,
          index: doc.data['index'] as int,
        )
      );
    }).toList();

    final List<Location> localFavourites = appState.favouriteLocations;

    // Compare and update local favourites
    for (final awFav in awFavourites) {
      final Location location = awFav.$2;
      if (!localFavourites
          .any((loc) => loc.lat == location.lat && loc.lon == location.lon)) {
        switch (direction) {
          case SyncDirection.toAppwrite:
            // If the location is not in local favourites, remove it from Appwrite
            await databases.deleteDocument(
                databaseId: 'sync',
                collectionId: 'favourites',
                documentId: awFav.$1);
            break;
          case SyncDirection.fromAppwrite:
          case SyncDirection.both:
            // If the location is not in local favourites, add it
            appState.addFavouriteLocation(location, sync: false);
            break;
        }
      }
    }
    for (final Location location in localFavourites) {
      if (!awFavourites.any(
          (loc) => loc.$2.lat == location.lat && loc.$2.lon == location.lon)) {
        // If the location is not in Appwrite, add it
        await databases.createDocument(
            databaseId: 'sync',
            collectionId: 'favourites',
            documentId: ID.unique(),
            data: {
              'lat': location.lat,
              'lon': location.lon,
              'name': location.name,
              'region': location.region,
              'countryCode': location.countryCode,
              'country': location.country,
              'index': location.index ?? 0,
            },
            permissions: [
              Permission.read(Role.user(user.$id)),
              Permission.write(Role.user(user.$id)),
            ]);
      } else {
        // If the location exists in both local and Appwrite, check if the index needs to be updated
        // Find the matching Appwrite document
        final awFav = awFavourites.firstWhere(
            (loc) => loc.$2.lat == location.lat && loc.$2.lon == location.lon);

        // Check if the indexes are different
        if (location.index != awFav.$2.index) {
          // Update only the index in Appwrite
          await databases.updateDocument(
            databaseId: 'sync',
            collectionId: 'favourites',
            documentId: awFav.$1,
            data: {
              'index': location.index ?? 0,
            },
          );
        }
      }
    }
  }

  Future<DocumentList> _getDbFavourites(Databases databases) async {
    return await databases.listDocuments(
      databaseId: 'sync',
      collectionId: 'favourites',
    );
  }

  Future<void> logout() async {
    await account.deleteSession(sessionId: 'current');
    unsubscribe();
    // account = Account(client); // Reinitialize account to reset state
  }

  Future<bool> deleteAccount() async {
    unsubscribe();
    final functions = Functions(client);
    try {
      final Execution response = await functions.createExecution(
          functionId: 'delete-account', xasync: false);

      if (response.status == 'completed' &&
          response.responseStatusCode == 200) {
        // Logout might not work, since the account has been deleted?
        // This is probably not needed, but let's try to be safe
        try {
          await logout();
        } catch (e) {
          if (kDebugMode) {
            print('Error logging out after account deletion: $e');
          }
        }
        return true;
      } else {
        throw Exception('Failed to delete account: ${response.status}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting account: $e');
      }
      return false;
    }
  }

  void subscribe() {
    if (subscription != null || _appState == null) return;
    subscription = realtime.subscribe([
      'databases.sync.collections.favourites.documents',
    ]);
    subscription!.stream.listen((data) {
      if (data.payload.isEmpty) return;
      final item = data.payload;

      final location = Location(
        lat: item['lat'] as double,
        lon: item['lon'] as double,
        name: item['name'] as String,
        region: item['region'] as String?,
        countryCode: item['countryCode'] as String,
        country: item['country'] as String?,
        index: item['index'] as int,
      );

      if (kDebugMode) {
        print('Realtime event: ${data.events.first} for location: $location');
      }

      if (data.events.first.endsWith('.create')) {
        _appState!.addFavouriteLocation(location, sync: false);
      } else if (data.events.first.endsWith('.update')) {
        _appState!.removeFavouriteLocation(location, sync: false);
        _appState!.addFavouriteLocation(location, sync: false);
      } else if (data.events.first.endsWith('.delete')) {
        _appState!.removeFavouriteLocation(location, sync: false);
      }
    });
  }

  void unsubscribe() {
    if (subscription != null) {
      subscription!.close();
      subscription = null;
    }
  }
}
