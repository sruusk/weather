import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:weather/l10n/app_localizations.g.dart';

/// A widget that displays a message and button when no locations are available.
///
/// This widget shows a card with an icon, message, and a button to navigate
/// to the favourites page where users can add locations.
class NoLocations extends StatelessWidget {
  const NoLocations({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final localisations = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Card(
        elevation: 4.0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16.0)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_off,
                size: 48.0,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 16.0),
              Text(
                localisations.noSavedLocations,
                style: textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12.0),
              Text(
                localisations.addLocationsInFavourites,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 24.0),
              SizedBox(
                width: 200.0, // Make button wider
                height: 48.0, // Make button taller
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to the favourites page
                    context.go('/favourites');
                  },
                  style: ElevatedButton.styleFrom(
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12.0)),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                  ),
                  child: Text(
                    localisations.goToFavourites,
                    style: const TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
