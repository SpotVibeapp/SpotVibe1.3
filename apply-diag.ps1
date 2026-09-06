Set-Location C:\Apps\SpotVibe
$utf8 = New-Object System.Text.UTF8Encoding($false)
$path = "lib\main.dart"
$script:text = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)

function Apply-Edit([string]$name, [string]$old, [string]$new) {
  if ($script:text.Contains($new)) { Write-Output "ALREADY APPLIED: $name"; return }
  if (-not $script:text.Contains($old)) { Write-Output "MISS: $name"; return }
  $script:text = $script:text.Replace($old, $new)
  Write-Output "OK: $name"
}

Apply-Edit "cold-linkUri-decl" @'
  String initialLocation = '/';
'@ @'
  String initialLocation = '/';
  String? coldLinkUri;
'@

Apply-Edit "cold-block" @'
      final appLinks = AppLinks();
      final coldUri = await appLinks.getInitialLink();
      if (coldUri != null) {
        final path = DeepLinkService.pathFromUri(coldUri.toString());
        if (path != null) initialLocation = path;
      }
    } catch (_) {}
'@ @'
      final appLinks = AppLinks();
      final coldUri = await appLinks.getInitialLink();
      if (coldUri != null) {
        debugPrint('[deepLink] cold-start uri=$coldUri');
        final path = DeepLinkService.pathFromUri(coldUri.toString());
        debugPrint('[deepLink] cold-start parsed path=$path');
        if (path != null) {
          initialLocation = path;
          coldLinkUri = coldUri.toString();
        }
      }
    } catch (e) {
      debugPrint('[deepLink] cold-start read failed: $e');
    }
'@

Apply-Edit "runApp-arg" @'
    initialLocation: initialLocation,
  ));
'@ @'
    initialLocation: initialLocation,
    initialLinkUri: coldLinkUri,
  ));
'@

Apply-Edit "widget-field" @'
  final String initialLocation;
'@ @'
  final String initialLocation;
  final String? initialLinkUri;
'@

Apply-Edit "widget-ctor" @'
    required this.initialLocation,
  });
'@ @'
    required this.initialLocation,
    this.initialLinkUri,
  });
'@

Apply-Edit "state-class-header" @'
class _SpotVibeAppState extends State<SpotVibeApp> {
'@ @'
class _SpotVibeAppState extends State<SpotVibeApp>
    with WidgetsBindingObserver {
'@

Apply-Edit "state-fields" @'
  late final GoRouter _router;
'@ @'
  late final GoRouter _router;
  final AppLinks _appLinks = AppLinks();
  String? _lastResumeLinkUri;
'@

Apply-Edit "initState-seed" @'
    _router = AppRouter.build(initialLocation: widget.initialLocation);

    if (!kIsWeb) {
      // app_links: handles https App Links, universal links, and spotvibe://
'@ @'
    _router = AppRouter.build(initialLocation: widget.initialLocation);
    _lastResumeLinkUri = widget.initialLinkUri;
    if (!kIsWeb) {
      WidgetsBinding.instance.addObserver(this);
      // app_links: handles https App Links, universal links, and spotvibe://
'@

Apply-Edit "stream-logs" @'
      appLinks.uriLinkStream.listen((uri) {
        final path = DeepLinkService.pathFromUri(uri.toString());
        if (path != null) _router.go(path);
      });
'@ @'
      appLinks.uriLinkStream.listen((uri) {
        debugPrint('[deepLink] stream uri=$uri');
        final path = DeepLinkService.pathFromUri(uri.toString());
        debugPrint('[deepLink] stream parsed path=$path');
        if (path != null) _router.go(path);
      });
'@

Apply-Edit "resume-methods" @'
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
'@ @'
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!kIsWeb && state == AppLifecycleState.resumed) {
      _checkLatestLink();
    }
  }

  Future<void> _checkLatestLink() async {
    try {
      final uri = await _appLinks.getLatestLink();
      if (uri == null) {
        debugPrint('[deepLink] resume-check: no link');
        return;
      }
      if (uri.toString() == _lastResumeLinkUri) {
        debugPrint('[deepLink] resume-check skip duplicate: $uri');
        return;
      }
      _lastResumeLinkUri = uri.toString();
      debugPrint('[deepLink] resume-check uri=$uri');
      final path = DeepLinkService.pathFromUri(uri.toString());
      debugPrint('[deepLink] resume-check parsed path=$path');
      if (path != null) _router.go(path);
    } catch (e) {
      debugPrint('[deepLink] resume-check failed: $e');
    }
  }

  @override
  void dispose() {
    if (!kIsWeb) WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
'@

[System.IO.File]::WriteAllText($path, $script:text, $utf8)
Write-Output "---- written ----"
Write-Output ("lines: " + (Get-Content $path).Count)
Write-Output ("deepLink mentions: " + (Select-String -Path $path -Pattern "deepLink").Count)
Write-Output ("getLatestLink: " + (Select-String -Path $path -Pattern "getLatestLink").Count)