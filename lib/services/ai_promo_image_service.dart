import 'package:cloud_functions/cloud_functions.dart';

import '../config/app_config.dart';

/// Result from the server-side AI promo-background generator.
class AiPromoImageResult {
  final String imageUrl;
  final String storagePath;

  const AiPromoImageResult({
    required this.imageUrl,
    required this.storagePath,
  });
}

/// Calls the authenticated Cloud Function that owns the image-provider key.
///
/// No AI provider key is ever embedded in the mobile app. The backend applies
/// content restrictions, rate limits, and saves the result into the event
/// owner's Firebase Storage path.
class AiPromoImageService {
  AiPromoImageService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  Future<AiPromoImageResult> generate({
    required String eventId,
    required String title,
    required String description,
    required String category,
    required String venue,
    String artDirection = '',
    required String style,
    required String aspectRatio,
  }) async {
    try {
      // This Workspace has Domain Restricted Sharing enabled, which prevents
      // an `allUsers` Cloud Run Invoker binding. Calling the backing Gen 2
      // service URL lets Cloud Run accept the request; the `onCall` handler
      // still verifies the Firebase Auth token before doing any work.
      final callable = _functions.httpsCallableFromUrl(
        AppConfig.aiPromoFunctionUrl,
      );
      final result = await callable.call<Map<String, dynamic>>({
        'eventId': eventId,
        'title': title.trim(),
        'description': description.trim(),
        'category': category.trim(),
        'venue': venue.trim(),
        'artDirection': artDirection.trim(),
        'style': style,
        'aspectRatio': aspectRatio,
      });
      final data = Map<String, dynamic>.from(result.data);
      final imageUrl = data['imageUrl'] as String? ?? '';
      final storagePath = data['storagePath'] as String? ?? '';
      if (imageUrl.isEmpty || storagePath.isEmpty) {
        throw Exception('The image service did not return a usable promo image.');
      }
      return AiPromoImageResult(imageUrl: imageUrl, storagePath: storagePath);
    } on FirebaseFunctionsException catch (error) {
      throw Exception(_messageFor(error));
    }
  }

  String _messageFor(FirebaseFunctionsException error) {
    switch (error.code) {
      case 'unauthenticated':
        return 'Sign in before generating a promo image.';
      case 'resource-exhausted':
        return 'You have reached today\'s AI image limit. Try again tomorrow.';
      case 'invalid-argument':
        return error.message ?? 'Complete the event details before generating an image.';
      case 'failed-precondition':
        return error.message ?? 'AI promo images are not configured yet.';
      case 'permission-denied':
        return error.message ?? 'This image request could not be approved.';
      case 'not-found':
        return 'AI promo images are not configured yet. Ask the app owner to finish setup.';
      case 'unavailable':
        return 'The AI image service is temporarily unavailable. Please try again shortly.';
      case 'deadline-exceeded':
      case 'internal':
        // Firebase intentionally hides most server internals from an app. Do
        // not expose the raw "internal" code to creators; it is not an image
        // review state and gives them no useful action to take.
        return 'The AI image service could not complete this request. Please try again.';
      default:
        final message = error.message?.trim();
        if (message == null ||
            message.isEmpty ||
            message.toLowerCase() == error.code.toLowerCase() ||
            message.toLowerCase() == 'internal') {
          return 'Could not generate a promo image. Please try again.';
        }
        return message;
    }
  }
}
