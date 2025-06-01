import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:weather/l10n/app_localizations.g.dart';
import 'package:weather/routes.dart'; // Import AppRoutes

// This widget displays the list of navigation options for the "Other" section.
class OtherPageListView extends StatefulWidget {
  const OtherPageListView({super.key});

  @override
  State<OtherPageListView> createState() => _OtherPageListViewState();
}

class _OtherPageListViewState extends State<OtherPageListView> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Important for AutomaticKeepAliveClientMixin
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                localizations.otherPageTitle,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 2,
                child: InkWell(
                  onTap: () => context.goNamed(AppRoutes.settings.name), // Use .name
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(children: [
                      const Icon(Icons.settings, size: 40),
                      const SizedBox(width: 16),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(localizations.settingsPageTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(localizations.settingsPageDescription, style: const TextStyle(fontSize: 14)),
                      ])),
                      const Icon(Icons.arrow_forward_ios),
                    ]),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 2,
                child: InkWell(
                  onTap: () => context.goNamed(AppRoutes.weatherSymbols.name), // Use .name
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(children: [
                      const Icon(Icons.cloud, size: 40),
                      const SizedBox(width: 16),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(localizations.weatherSymbolsPageTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(localizations.weatherSymbolsPageDescription, style: const TextStyle(fontSize: 14)),
                      ])),
                      const Icon(Icons.arrow_forward_ios),
                    ]),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 2,
                child: InkWell(
                  onTap: () => context.goNamed(AppRoutes.about.name), // Use .name
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(children: [
                      const Icon(Icons.info, size: 40),
                      const SizedBox(width: 16),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(localizations.aboutPageTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(localizations.aboutPageDescription, style: const TextStyle(fontSize: 14)),
                      ])),
                      const Icon(Icons.arrow_forward_ios),
                    ]),
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
