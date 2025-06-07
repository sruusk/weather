import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:weather/l10n/app_localizations.g.dart';

import '../app_state.dart';
import '../data/location.dart';
import '../data/weather_data.dart';

class FavouritesPage extends StatefulWidget {
  const FavouritesPage({super.key});

  @override
  State<FavouritesPage> createState() => _FavouritesPageState();
}

class _FavouritesPageState extends State<FavouritesPage> with AutomaticKeepAliveClientMixin<FavouritesPage> {
  final TextEditingController _searchController = TextEditingController();
  final WeatherData _weatherData = WeatherData();
  List<Location> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  // Search for locations as the user types
  void _onSearchChanged(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final lang = Provider.of<AppState>(context, listen: false).locale.languageCode;
      final results = await _weatherData.getAutoCompleteResults(query, lang: lang);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error searching locations: $e');
      }
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
    }
  }

  // Add a location to favorites
  void _addToFavorites(Location location) {
    final appState = Provider.of<AppState>(context, listen: false);
    appState.addFavouriteLocation(location);

    // Clear search
    _searchController.clear();
    setState(() {
      _searchResults = [];
    });
  }

  // Remove a location from favorites
  void _removeFromFavorites(Location location) {
    final appState = Provider.of<AppState>(context, listen: false);
    appState.removeFavouriteLocation(location);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Call super to ensure keep alive works

    final localizations = AppLocalizations.of(context)!;
    final appState = Provider.of<AppState>(context);
    final favouriteLocations = appState.favouriteLocations;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: localizations.searchForLocation,
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchResults = [];
                            });
                          },
                        )
                      : null,
                ),
                onChanged: _onSearchChanged,
              ),

              const SizedBox(height: 20),

              // Search results
              if (_isSearching)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_searchResults.isNotEmpty)
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final location = _searchResults[index];
                      return ListTile(
                        title: Text(location.name),
                        subtitle: Text(
                          [
                            if (location.region != null) location.region!,
                            if (location.country != null) location.country!,
                          ].join(', '),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () => _addToFavorites(location),
                        ),
                        onTap: () => _addToFavorites(location),
                      );
                    },
                  ),
                )
              else
                Expanded(
                  child: favouriteLocations.isEmpty
                      ? Center(
                          child: Text(
                            localizations.searchAndAddFavourites,
                            style: const TextStyle(fontSize: 16),
                          ),
                        )
                      : ReorderableListView.builder(
                          buildDefaultDragHandles: false,
                          itemCount: favouriteLocations.length,
                          onReorder: (oldIndex, newIndex) {
                            appState.reorderFavouriteLocations(oldIndex, newIndex);
                          },
                          itemBuilder: (context, index) {
                            final location = favouriteLocations[index];
                            return Card(
                              key: ValueKey(location.toString()),
                              margin: const EdgeInsets.symmetric(vertical: 5.0),
                              child: ListTile(
                                title: Text(
                                  location.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  [
                                    if (location.region != null)
                                      location.region!,
                                    if (location.country != null)
                                      location.country!,
                                  ].join(', '),
                                ),
                                leading: ReorderableDragStartListener(
                                  index: index,
                                  child: const Icon(Icons.drag_handle),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () =>
                                      _removeFromFavorites(location),
                                ),
                                // onTap: () {
                                //   // Set as active location
                                //   appState.setActiveLocation(location);
                                // },
                              ),
                            );
                          },
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
