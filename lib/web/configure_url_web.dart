import 'dart:js_interop';

import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:web/web.dart' as web;

@JS('spotvibeInitialPath')
external String? get _spotvibeInitialPath;

/// The path the visitor actually opened. Saved in index.html before Flutter
/// boots, because `<base href="/app/">` makes [Uri.base] ignore everything
/// after `/app/` and the router may rewrite the address bar on startup.
String browserPathname() {
  final saved = _spotvibeInitialPath;
  if (saved != null && saved.isNotEmpty) return saved;
  return web.window.location.pathname;
}

/// The web app is hosted at `https://spotvibeapp.com/app/`.
///
/// [PathUrlStrategy] already strips the `<base href>` when Flutter was built
/// with `--base-href /app/`. This subclass also strips a literal `/app`
/// prefix so go_router keeps the same `/event/:id` paths the phone app uses,
/// and it writes browser URLs back under `/app` so a refresh stays inside
/// the hosting rewrite.
class SpotVibePathStrategy extends PathUrlStrategy {
  static const String basePath = '/app';

  @override
  String getPath() {
    var path = super.getPath();
    final queryIndex = path.indexOf('?');
    final query = queryIndex == -1 ? '' : path.substring(queryIndex);
    var bare = queryIndex == -1 ? path : path.substring(0, queryIndex);
    if (bare.endsWith('/') && bare.length > 1) {
      bare = bare.substring(0, bare.length - 1);
    }
    if (bare == basePath) return '/$query';
    if (bare.startsWith('$basePath/')) {
      bare = bare.substring(basePath.length);
    }
    if (bare.isEmpty) bare = '/';
    return '$bare$query';
  }

  @override
  String prepareExternalUrl(String internalUrl) {
    final prepared = super.prepareExternalUrl(internalUrl);
    if (prepared == basePath ||
        prepared.startsWith('$basePath/') ||
        prepared.startsWith('$basePath?')) {
      return prepared;
    }
    if (internalUrl.startsWith('/')) return '$basePath$internalUrl';
    return prepared;
  }
}

void configureAppUrlStrategy() {
  setUrlStrategy(SpotVibePathStrategy());
}
