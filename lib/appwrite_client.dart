import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:weather/app_state.dart';
import 'package:weather/data/location.dart';

enum SyncDirection { toAppwrite, fromAppwrite, both }

class AppwriteClient {
  static final AppwriteClient _instance = AppwriteClient._internal();
  late Client client;
  late Account account;

  factory AppwriteClient() {
    return _instance;
  }

  AppwriteClient._internal() {
    client = Client()
        .setEndpoint("https://aw.a32.fi/v1") // Replace with your endpoint
        .setProject("6843138e001dcb69f2be"); // Replace with your project ID
    account = Account(client);
  }

  Client get getClient => client;

  Account get getAccount => account;

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

    if(!await isLoggedIn()) {
      appState.setSyncFavouritesToAppwrite(false);
      throw Exception('User is not logged in, disabling sync');
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
}
