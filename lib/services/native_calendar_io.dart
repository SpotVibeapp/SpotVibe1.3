import 'package:add_2_calendar/add_2_calendar.dart';

Future<bool> addNativeCalendarEvent({
  required String title,
  required String description,
  required String location,
  required DateTime start,
  required DateTime end,
}) async {
  try {
    return await Add2Calendar.addEvent2Cal(
      Event(
        title: title,
        description: description,
        location: location,
        startDate: start,
        endDate: end,
      ),
    );
  } catch (_) {
    return false;
  }
}
