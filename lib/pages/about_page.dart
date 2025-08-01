import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:weather/l10n/app_localizations.g.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage>
    with AutomaticKeepAliveClientMixin<AboutPage> {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(localizations.aboutPageTitle),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  localizations.dataSourcesHeader,
                  style: const TextStyle(
                      fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                // Open-Meteo data source vertical block
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          'assets/about/OpenMeteo-logo.svg',
                          width: 50,
                          height: 50,
                          colorFilter: ColorFilter.mode(
                            Theme.of(context).colorScheme.onSurface,
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          localizations.openMeteoDescription,
                          textAlign: TextAlign.center,
                        ),
                        TextButton(
                          onPressed: () => launchUrl(
                              Uri.parse('https://open-meteo.com/en/license')),
                          child: Text(localizations.visitWebsite),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // FMI data source vertical block
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            'assets/about/fmiodata.svg',
                            height: 30,
                            colorFilter: ColorFilter.mode(
                              Theme.of(context).colorScheme.onSurface,
                              BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.8,
                            // Constrain width to 80% of screen width
                            child: Text(
                              localizations.fmiDescription,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          TextButton(
                            onPressed: () => launchUrl(Uri.parse(
                                'https://www.ilmatieteenlaitos.fi/avoin-data')),
                            child: Text(localizations.visitWebsite),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // OpenStreetMap vertical block
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          localizations.openStreetMapDescription,
                          style: const TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        TextButton(
                          onPressed: () => launchUrl(Uri.parse(
                              'https://www.openstreetmap.org/copyright')),
                          child: Text(localizations.visitWebsite),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Licenses section header
                Text(
                  localizations.licensesHeader,
                  style: const TextStyle(
                      fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                // Open Source Licenses button
                ElevatedButton.icon(
                  onPressed: () {
                    showLicensePage(
                      context: context,
                      applicationName: 'Weather',
                      applicationIcon: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Image.asset(
                          'assets/icon.png',
                          width: 48,
                          height: 48,
                        ),
                      ),
                      applicationLegalese: '© 2025',
                      useRootNavigator: false,
                    );
                  },
                  icon: const Icon(Icons.list_alt),
                  label: Text(localizations.ossLicenses),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
