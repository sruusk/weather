import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:weather/l10n/app_localizations.g.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
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
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                localizations.dataSourcesHeader,
                style:
                    const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
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
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset('assets/about/fmiodata.webp',
                          width: 200, height: 50),
                      const SizedBox(height: 8),
                      Text(
                        localizations.fmiDescription,
                        textAlign: TextAlign.center,
                      ),
                      TextButton(
                        onPressed: () => launchUrl(Uri.parse(
                            'https://www.ilmatieteenlaitos.fi/avoin-data')),
                        child: Text(localizations.visitWebsite),
                      ),
                    ],
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
                style:
                    const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              // SmartMet Alert Client license entry
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        localizations.smartmetAlertClientName,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        localizations.smartmetAlertClientLicense,
                        style: const TextStyle(fontSize: 14),
                      ),
                      TextButton(
                        onPressed: () => launchUrl(Uri.parse(
                            'https://github.com/fmidev/smartmet-alert-client/blob/6c8445634b2cea006ebad82ca219e1f822f43461/LICENSE')),
                        child: Text(localizations.viewLicense),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
