import 'package:flutter/widgets.dart';

import '../models/event_claim.dart';
import 'app_localizations.dart';

String claimRoleLabel(BuildContext context, ClaimRole role) {
  final l = AppLocalizations.of(context)!;
  switch (role) {
    case ClaimRole.owner:
      return l.claimRoleOwner;
    case ClaimRole.promoter:
      return l.claimRolePromoter;
    case ClaimRole.bookingAgent:
      return l.claimRoleBookingAgent;
    case ClaimRole.marketing:
      return l.claimRoleMarketing;
    case ClaimRole.other:
      return l.claimRoleOther;
  }
}

String claimProofLabel(BuildContext context, ClaimProofMethod method) {
  final l = AppLocalizations.of(context)!;
  switch (method) {
    case ClaimProofMethod.officialEmail:
      return l.claimProofOfficialEmail;
    case ClaimProofMethod.venueWebsite:
      return l.claimProofVenueWebsite;
    case ClaimProofMethod.contract:
      return l.claimProofContract;
    case ClaimProofMethod.pressContact:
      return l.claimProofPressContact;
  }
}
