import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:weather/app_state.dart';

WebViewEnvironment? webViewEnvironment;

class WarningsPageOld extends StatefulWidget {
  const WarningsPageOld({super.key});

  @override
  State<WarningsPageOld> createState() => _WarningsPageOldState();
}

class _WarningsPageOldState extends State<WarningsPageOld>
    with AutomaticKeepAliveClientMixin<WarningsPageOld> {
  final GlobalKey webViewKey = GlobalKey();
  String? theme;
  String? language;
  bool? isAmoledTheme;

  InAppWebViewController? webViewController;
  InAppWebViewSettings settings = InAppWebViewSettings(
      isInspectable: kDebugMode,
      mediaPlaybackRequiresUserGesture: false,
      allowsInlineMediaPlayback: true);

  String url = "";
  double progress = 0;
  final urlController = TextEditingController();

  @override
  void initState() {
    super.initState();

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      InAppWebViewController.setWebContentsDebuggingEnabled(kDebugMode);
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Call super to ensure keep alive works
    bool needReload = false;

    final appState = Provider.of<AppState>(context);
    if (language != appState.locale.languageCode) {
      setState(() {
        language = appState.locale.languageCode;
      });
      needReload = true;
    }

    if (theme !=
        (Theme.of(context).brightness == Brightness.dark ? ".dark" : "")) {
      setState(() {
        theme = Theme.of(context).brightness == Brightness.dark ? ".dark" : "";
      });
      needReload = true;
    }

    if (isAmoledTheme != appState.isAmoledTheme) {
      setState(() {
        isAmoledTheme = appState.isAmoledTheme;
      });
      needReload = true;
    }

    if (needReload) _loadContent();

    return SafeArea(
        child: Column(children: <Widget>[
      Expanded(
        child: InAppWebView(
          key: webViewKey,
          webViewEnvironment: webViewEnvironment,
          initialSettings: settings,
          onWebViewCreated: (controller) async {
            webViewController = controller;
            _loadContent();
          },
          onLoadStart: (controller, url) {
            setState(() {
              this.url = url.toString();
              urlController.text = this.url;
            });
          },
          onPermissionRequest: (controller, request) async {
            return PermissionResponse(
                resources: request.resources,
                action: PermissionResponseAction.GRANT);
          },
          shouldOverrideUrlLoading: (controller, navigationAction) async {
            var uri = navigationAction.request.url!;

            if (![
              "http",
              "https",
              "file",
              "chrome",
              "data",
              "javascript",
              "about"
            ].contains(uri.scheme)) {
              if (await canLaunchUrl(uri)) {
                // Launch the App
                await launchUrl(
                  uri,
                );
                // and cancel the request
                return NavigationActionPolicy.CANCEL;
              }
            }

            return NavigationActionPolicy.ALLOW;
          },
          onLoadStop: (controller, url) async {
            setState(() {
              this.url = url.toString();
              urlController.text = this.url;
            });
          },
          onReceivedError: (controller, request, error) {
            if (kDebugMode) print('Error: $error');
          },
          onProgressChanged: (controller, progress) {
            setState(() {
              this.progress = progress / 100;
              urlController.text = url;
            });
          },
          onUpdateVisitedHistory: (controller, url, androidIsReload) {
            setState(() {
              this.url = url.toString();
              urlController.text = this.url;
            });
          },
          onConsoleMessage: (controller, consoleMessage) {
            if (kDebugMode) {
              print(consoleMessage);
            }
          },
        ),
      )
    ]));
  }

  _loadContent() async {
    if (kDebugMode) {
      print(
          "Loading warnings page content, theme: $theme, language: $language");
    }
    // Determine asset paths
    if (theme == null) return;
    final htmlPath = 'assets/smartmet-alert-client/index$theme.html';
    final jsPath = 'assets/smartmet-alert-client/index.js';
    // Load template and script
    String htmlTemplate = await rootBundle.loadString(htmlPath);
    String jsContent = await rootBundle.loadString(jsPath);
    // Replace language attribute
    htmlTemplate = htmlTemplate.replaceAll(
        RegExp(r'language="[^"]*"'), 'language="$language"');
    // Replace background color if amoled theme
    if (isAmoledTheme == true) {
      htmlTemplate = htmlTemplate.replaceAll(RegExp(r'#191b22'), '#000000');
    }
    // Inline JS by replacing external script tag
    final html = htmlTemplate.replaceFirst(
        RegExp(r'<script[^>]*src="./index\.js"[^>]*></script>'),
        '<script type="module">$jsContent</script>');
    // Load data into WebView
    await webViewController!.loadData(
      data: html,
      baseUrl: WebUri('about:blank'),
      historyUrl: WebUri('about:blank'),
    );
  }
}
