class BrowserPlatformLocation {
  String? getBaseHref() {
    throw UnsupportedError(
        'BrowserPlatformLocation is only supported on the web.');
  }
}
