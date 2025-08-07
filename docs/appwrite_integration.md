# AppWrite Integration Documentation

This document provides an overview of how AppWrite is integrated into the Weather App, explaining the key features,
components, and how they work together.

## AppWrite Overview

[AppWrite](https://appwrite.io/) is an open-source backend server that provides ready-to-use APIs for authentication,
databases, storage, and more. The Weather App uses AppWrite for:

1. **User Authentication**: Managing user accounts and sessions
2. **Database**: Storing and syncing favorite locations
3. **Functions**: Executing server-side functions for specific tasks
4. **Realtime**: Receiving real-time updates for data changes

## AppwriteClient Class

The `AppwriteClient` class is the central component for AppWrite integration, implemented as a singleton for app-wide
access.

### Initialization

```dart
AppwriteClient._internal
() {client = Client
().setEndpoint
("https://aw.a32.fi/v1
"
)
.setProject("6843138e001dcb69f2be");
account = Account(client);
realtime = Realtime(client);
}
```

The client is initialized with:

- AppWrite endpoint URL
- Project ID
- Account and Realtime services

### Authentication

The `AppwriteClient` provides methods for user authentication:

```dart
Future<bool> isLoggedIn() async {
  try {
    await account.getSession(sessionId: 'current');
    return true;
  } catch (_) {
    return false;
  }
}

Future<void> logout() async {
  await account.deleteSession(sessionId: 'current');
  unsubscribe();
}

Future<bool> deleteAccount() async {
  unsubscribe();
  final functions = Functions(client);
  try {
    final Execution response = await functions.createExecution(
        functionId: 'delete-account', xasync: false);
    // ...
  }
  // ...
}
```

These methods allow the app to:

- Check if a user is currently logged in
- Log out the current user
- Delete the user's account

### Favorite Locations Sync

A key feature is syncing favorite locations between devices:

```dart
Future<void> syncFavourites(AppState appState,
    {SyncDirection direction = SyncDirection.both}) async {
  final databases = Databases(client);

  // Check if user is logged in
  if (!await isLoggedIn()) {
    appState.setSyncFavouritesToAppwrite(false);
    unsubscribe();
    throw Exception('User is not logged in, disabling sync');
  }

  // Sync logic based on direction
  switch (direction) {
    case SyncDirection.toAppwrite:
    // Sync from local to AppWrite
      break;
    case SyncDirection.fromAppwrite:
    // Sync from AppWrite to local
      if ((await _getDbFavourites(databases)).total == 0) break;
      appState.removeAllLocalFavouriteLocations();
      break;
    case SyncDirection.both:
    // Bidirectional sync
      break;
  }

  // Sync implementation...
}
```

The sync process:

1. Verifies the user is logged in
2. Determines the sync direction (to AppWrite, from AppWrite, or both)
3. Fetches locations from AppWrite
4. Compares with local favorites
5. Updates both sides as needed

### Realtime Updates

The app uses AppWrite's Realtime feature to receive live updates:

```dart
void subscribe() {
  if (subscription != null || _appState == null) return;
  subscription = realtime.subscribe([
    'databases.sync.collections.favourites.documents',
  ]);
  subscription!.stream.listen((data) {
    // Handle realtime updates
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
```

This allows the app to:

- Subscribe to changes in the favorites collection
- Receive notifications when documents are created, updated, or deleted
- Update the local state accordingly without triggering another sync

### Custom Functions

The app uses AppWrite Functions for server-side operations:

```dart
Future<Map<String, dynamic>> getReverseGeocoding(double lat, double lon,
    {String lang = 'fi'}) async {
  final functions = Functions(client);
  try {
    final Execution response = await functions.createExecution(
      functionId: 'reverse-geocode',
      body: jsonEncode({
        'lat': lat,
        'lon': lon,
        'lang': lang,
      }),
      xasync: false,
    );
    // Process response...
  }
  // ...
}
```

Functions used:

- `reverse-geocode`: Converts coordinates to location information
- `delete-account`: Handles account deletion process

## Database Structure

The app uses AppWrite's database for storing favorite locations:

### Collections

- **favourites**: Stores user's favorite locations

### Document Structure

Each favorite location is stored as a document with:

```json
{
  "lat": 60.1699,
  "lon": 24.9384,
  "name": "Helsinki",
  "region": "Uusimaa",
  "countryCode": "FI",
  "country": "Finland",
  "index": 0
}
```

### Permissions

Documents have user-specific permissions:

```dart
permissions: [
Permission.read
(
Role.user(user.$id)),
Permission.write(Role.user(user.$id)
)
,
]
```

This ensures that:

- Each user can only access their own favorites
- The data is secure and private

## Integration with App State

The AppWrite integration is tightly coupled with the app's state management:

```dart
// In AppState class
final ValueNotifier<bool> _syncFavouritesToAppwriteNotifier =
ValueNotifier<bool>(false);

void setSyncFavouritesToAppwrite(bool enabled) {
  _syncFavouritesToAppwriteNotifier.value = enabled;
  _preferencesNotifier.setPreference(
      _syncFavouritesToAppwriteKey, enabled.toString());
  notifyListeners();
}

// When adding a favorite location
if (
syncFavouritesToAppwrite && sync) {
_appwriteClient
    .syncFavourites(this, direction: SyncDirection.toAppwrite)
    .then((_) {
// Handle success
}).catchError((e, s) {
// Handle error
});
}
```

This integration allows:

- Users to enable/disable syncing in settings
- Automatic syncing when favorites change
- Error handling for sync failures

## Sync Direction Enum

The app defines a `SyncDirection` enum to control sync behavior:

```dart
enum SyncDirection { toAppwrite, fromAppwrite, both }
```

This allows for flexible syncing strategies:

- `toAppwrite`: Push local changes to AppWrite
- `fromAppwrite`: Pull AppWrite changes to local
- `both`: Bidirectional sync

## Error Handling

The AppWrite integration includes robust error handling:

```dart
try {
// AppWrite operations
} catch (e) {
if (kDebugMode) {
print('Error in AppWrite operation: $e');
}
// Handle error appropriately
}
```

Common error scenarios:

- Network connectivity issues
- Authentication failures
- Permission errors
- Server-side errors

## Security Considerations

The AppWrite integration implements several security best practices:

1. **Session Management**: Proper handling of user sessions
2. **Error Handling**: Secure error handling that doesn't expose sensitive information
3. **Permissions**: Document-level permissions for user data
4. **Secure Functions**: Server-side functions for sensitive operations

## Conclusion

The AppWrite integration in the Weather App provides:

- Secure user authentication
- Cross-device synchronization of favorites
- Real-time updates for a responsive experience
- Server-side functions for complex operations

This integration enhances the app's functionality while maintaining security and performance, allowing users to access
their favorite locations across multiple devices.
