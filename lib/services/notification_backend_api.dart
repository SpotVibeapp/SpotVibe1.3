/// Device notification operations. Android/iOS use awesome_notifications.
/// The web build uses the browser Notification API.
abstract class NotificationBackend {
  Future<bool> initialize();

  Future<bool> isAllowed();

  Future<bool> requestPermission();

  Future<bool> show({
    required int id,
    required String channelKey,
    required String title,
    required String body,
  });
}
