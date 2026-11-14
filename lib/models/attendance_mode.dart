/// How people signal they're coming to an event.
enum AttendanceMode {
  /// Yard sales and flea markets: a light "I'm going" tap only.
  dropIn,

  /// Game nights and similar: basic RSVP with a headcount and name list.
  rsvpRequested,

  /// Ticketed shows: the ticket link, which is a Premium perk.
  tickets,
}

extension AttendanceModeStorage on AttendanceMode {
  String get storageName {
    switch (this) {
      case AttendanceMode.dropIn:
        return 'dropIn';
      case AttendanceMode.rsvpRequested:
        return 'rsvpRequested';
      case AttendanceMode.tickets:
        return 'tickets';
    }
  }
}

/// Category defaults. Tickets is only the default for Music when the host
/// is already Premium, so a free host is not steered into a locked mode.
AttendanceMode defaultAttendanceMode(String category, {required bool isPremium}) {
  switch (category) {
    case 'Community':
    case 'Other':
      return AttendanceMode.dropIn;
    case 'Music':
      return isPremium ? AttendanceMode.tickets : AttendanceMode.rsvpRequested;
    default:
      return AttendanceMode.rsvpRequested;
  }
}

/// Resolve a stored or legacy event to a mode. Existing events without
/// [stored] default to RSVP requested, unless they already have a ticket
/// link or were marked ticketed.
AttendanceMode resolveAttendanceMode({
  String? stored,
  String? ticketUrl,
  bool isTicketed = false,
  bool isUserCreated = false,
}) {
  switch (stored) {
    case 'dropIn':
      return AttendanceMode.dropIn;
    case 'rsvpRequested':
      return AttendanceMode.rsvpRequested;
    case 'tickets':
      return AttendanceMode.tickets;
  }
  // External Ticketmaster-style rows keep RSVP requested so the existing
  // Get Tickets + RSVP pair does not change. First-party posts with a
  // ticket link map to tickets.
  final url = (ticketUrl ?? '').trim();
  if (isUserCreated && (isTicketed || url.isNotEmpty)) {
    return AttendanceMode.tickets;
  }
  return AttendanceMode.rsvpRequested;
}
