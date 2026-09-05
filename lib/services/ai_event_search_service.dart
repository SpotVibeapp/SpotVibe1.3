import 'package:cloud_functions/cloud_functions.dart';

import '../config/app_config.dart';
import '../models/ai_event_search.dart';

/// Calls the authenticated server-side AI intent parser for event discovery.
///
/// The AI function receives a short natural-language request and returns only
/// structured filters. It never returns event listings: the client separately
/// fetches every result from SpotVibe and Ticketmaster so the assistant cannot
/// invent an event, venue, time, price, or ticket availability.
class AiEventSearchService {
  AiEventSearchService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  bool get isConfigured => AppConfig.aiEventSearchFunctionUrl.isNotEmpty;

  Future<AiEventSearchPlan> interpret(String request) async {
    final query = request.trim();
    if (query.isEmpty) {
      throw Exception('Tell SpotVibe what you want to find.');
    }
    if (!isConfigured) {
      throw Exception('The AI event assistant is not configured yet.');
    }

    try {
      // Like AI promo backgrounds, this uses a direct Gen 2 Cloud Run callable
      // URL because the Workspace policy blocks Firebase's normal public
      // invoker binding. The function still verifies Firebase Auth itself.
      final callable = _functions.httpsCallableFromUrl(
        AppConfig.aiEventSearchFunctionUrl,
      );
      final result = await callable.call<Map<String, dynamic>>({
        'query': query,
      });
      return AiEventSearchPlan.fromMap(
        Map<String, dynamic>.from(result.data),
      );
    } on FirebaseFunctionsException catch (error) {
      throw Exception(_messageFor(error));
    }
  }

  String _messageFor(FirebaseFunctionsException error) {
    switch (error.code) {
      case 'unauthenticated':
        return 'Sign in to use Ask SpotVibe.';
      case 'resource-exhausted':
        return 'You have reached today\'s Ask SpotVibe limit. Try again tomorrow.';
      case 'invalid-argument':
        return error.message ?? 'Try a shorter event request.';
      case 'failed-precondition':
      case 'not-found':
        return 'The AI event assistant is not configured yet.';
      case 'permission-denied':
        return 'This event-search request cannot be completed.';
      case 'unavailable':
      case 'deadline-exceeded':
        return 'Ask SpotVibe is temporarily unavailable. Please try again shortly.';
      default:
        return 'Ask SpotVibe could not complete that search. Please try again.';
    }
  }
}
