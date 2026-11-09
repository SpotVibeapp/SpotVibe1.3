import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// A photo loaded from the network.
///
/// On Android and iOS this is [CachedNetworkImage], unchanged. On the web,
/// CanvasKit fetches images with XHR, and Ticketmaster / SeatGeek / JamBase
/// do not send CORS headers, so those photos never paint. An HTML `<img>`
/// (via [WebHtmlElementStrategy.prefer]) is allowed to display a cross-origin
/// image without reading its pixels, which is all the feed and event pages
/// need.
class NetworkPhoto extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Map<String, String>? httpHeaders;
  final FilterQuality filterQuality;
  final Widget Function(BuildContext context, String url)? placeholder;
  final Widget Function(BuildContext context, String url, Object error)?
      errorWidget;

  const NetworkPhoto({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.httpHeaders,
    this.filterQuality = FilterQuality.low,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Image.network(
        imageUrl,
        fit: fit,
        width: width,
        height: height,
        headers: httpHeaders,
        filterQuality: filterQuality,
        webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return placeholder?.call(context, imageUrl) ??
              SizedBox(width: width, height: height);
        },
        errorBuilder: (context, error, _) =>
            errorWidget?.call(context, imageUrl, error) ??
            SizedBox(width: width, height: height),
      );
    }
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      width: width,
      height: height,
      httpHeaders: httpHeaders,
      filterQuality: filterQuality,
      fadeInDuration: const Duration(milliseconds: 250),
      placeholder: placeholder == null
          ? null
          : (context, url) => placeholder!(context, url),
      errorWidget: errorWidget == null
          ? null
          : (context, url, error) => errorWidget!(context, url, error),
    );
  }
}
