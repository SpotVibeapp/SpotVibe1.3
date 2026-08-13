enum ClaimStatus { pending, approved, rejected }

enum ClaimRole { owner, promoter, bookingAgent, marketing, other }

enum ClaimProofMethod { officialEmail, venueWebsite, contract, pressContact }

extension ClaimRoleLabel on ClaimRole {
  String get label {
    switch (this) {
      case ClaimRole.owner:
        return 'Owner / operator';
      case ClaimRole.promoter:
        return 'Authorized promoter';
      case ClaimRole.bookingAgent:
        return 'Booking agent';
      case ClaimRole.marketing:
        return 'Marketing / PR';
      case ClaimRole.other:
        return 'Other authorized rep';
    }
  }
}

extension ClaimProofLabel on ClaimProofMethod {
  String get label {
    switch (this) {
      case ClaimProofMethod.officialEmail:
        return 'Work email at the venue or promoter company';
      case ClaimProofMethod.venueWebsite:
        return 'I am listed on the official website or socials';
      case ClaimProofMethod.contract:
        return 'I have a booking / promotion contract';
      case ClaimProofMethod.pressContact:
        return 'I am the listed press or box-office contact';
    }
  }
}

class EventClaim {
  final String id;
  final String eventId;
  final String eventTitle;
  final String venueName;
  final String userId;
  final String fullName;
  final String email;
  final String phone;
  final String organization;
  final ClaimRole role;
  final ClaimProofMethod proofMethod;
  final String proofUrl;
  final String statement;
  final ClaimStatus status;
  final DateTime createdAt;

  const EventClaim({
    required this.id,
    required this.eventId,
    required this.eventTitle,
    required this.venueName,
    required this.userId,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.organization,
    required this.role,
    required this.proofMethod,
    required this.proofUrl,
    required this.statement,
    required this.status,
    required this.createdAt,
  });
}
