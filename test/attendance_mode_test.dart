import 'package:flutter_test/flutter_test.dart';
import 'package:spotvibe_app/models/attendance_mode.dart';

void main() {
  test('category defaults keep tickets off for free hosts', () {
    expect(defaultAttendanceMode('Community', isPremium: false), AttendanceMode.dropIn);
    expect(defaultAttendanceMode('Other', isPremium: true), AttendanceMode.dropIn);
    expect(defaultAttendanceMode('Fun & Games', isPremium: false), AttendanceMode.rsvpRequested);
    expect(defaultAttendanceMode('Music', isPremium: false), AttendanceMode.rsvpRequested);
    expect(defaultAttendanceMode('Music', isPremium: true), AttendanceMode.tickets);
  });

  test('existing events default to RSVP requested unless a first-party ticket link is present', () {
    expect(resolveAttendanceMode(), AttendanceMode.rsvpRequested);
    expect(
      resolveAttendanceMode(ticketUrl: 'https://ticketmaster.com/x', isUserCreated: false),
      AttendanceMode.rsvpRequested,
    );
    expect(
      resolveAttendanceMode(ticketUrl: 'https://tickets.example/x', isUserCreated: true),
      AttendanceMode.tickets,
    );
    expect(resolveAttendanceMode(stored: 'dropIn'), AttendanceMode.dropIn);
  });
}
