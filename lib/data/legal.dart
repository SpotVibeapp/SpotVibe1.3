/// Public URLs for App Store Connect / Play Console after
/// `firebase deploy --only hosting`.
const String kPrivacyPolicyUrl = 'https://spotvibe-cfa08.web.app/privacy.html';
const String kTermsOfUseUrl = 'https://spotvibe-cfa08.web.app/terms.html';

const String kLegalEntityName = 'Spotvibe LLC';
const String kLegalContactEmail = 'blakejohnson@spotvibeapp.com';
const String kLegalEffectiveDate = 'August 12, 2026';

class LegalSection {
  final String heading;
  final String body;
  const LegalSection(this.heading, this.body);
}

class LegalDocument {
  final String title;
  final String intro;
  final List<LegalSection> sections;
  const LegalDocument({
    required this.title,
    required this.intro,
    required this.sections,
  });
}

const LegalDocument kPrivacyPolicy = LegalDocument(
  title: 'Privacy Policy',
  intro:
      'This Privacy Policy explains how $kLegalEntityName, a Texas limited liability company (“SpotVibe,” “we,” “us”), collects, uses, and shares information when you use the SpotVibe mobile and web apps. Effective $kLegalEffectiveDate.',
  sections: [
    LegalSection(
      'Who we are',
      'SpotVibe is operated by $kLegalEntityName. We help people in places like El Paso discover real upcoming events, RSVP, and let venues and promoters list or claim pages. Contact us at $kLegalContactEmail.',
    ),
    LegalSection(
      'Information you give us',
      'Account: name, email, password (stored by Firebase Authentication, not in plain text), and profile photo if you sign in with Google, Apple, or Facebook.\n\n'
          'Events you create: title, description, photos or image URLs, location, time, ticket price, and optional contact or branding fields.\n\n'
          'RSVPs and comments: whether you are going, and any text you post.\n\n'
          'Venue / event claims: your name, work email, phone, organization, role, and any proof you submit so we can verify you are authorized.\n\n'
          'Support: anything you email us.',
    ),
    LegalSection(
      'Information collected automatically',
      'Approximate or precise location if you allow it, so we can sort events by distance. You can refuse location and still browse.\n\n'
          'Device and app data: device type, OS, crash logs, and basic usage (screens viewed, events opened).\n\n'
          'On-device settings stored locally (for example theme, notification preferences, and a local trial flag if the stores are not yet connected).\n\n'
          'Purchase status: whether you have an active SpotVibe Premium trial or subscription. Apple, Google, and RevenueCat process the payment. We do not see or store your full card number.',
    ),
    LegalSection(
      'Information from others',
      'Ticketmaster Discovery API: we request public event listings (title, venue, time, official photos, ticket links). We do not receive your Ticketmaster account.\n\n'
          'Sign-in providers: Google, Apple, or Facebook send us the name, email, and avatar you allow.\n\n'
          'Other users: if someone tags you in a comment or you appear on a public RSVP list.',
    ),
    LegalSection(
      'How we use information',
      'To run the app: show the feed, publish your events, RSVPs, claims, and analytics for Premium organizers.\n\n'
          'To personalize the feed (categories you view or save) on your device.\n\n'
          'To process subscriptions, prevent fraud and abuse, and send optional notifications you enable (event reminders, new events nearby).\n\n'
          'To improve SpotVibe and comply with law.',
    ),
    LegalSection(
      'When we share information',
      'Service providers that host or process data for us: Google Firebase (auth, database), Apple and Google (app stores and in-app purchases), RevenueCat (subscription status), and Ticketmaster (outbound event search only).\n\n'
          'The public: events you publish, public RSVPs, and comments are visible to other users.\n\n'
          'Legal: if required by law, to protect people, or in a sale of the business.\n\n'
          'We do not sell your personal information.',
    ),
    LegalSection(
      'Location',
      'Location is optional. If you grant permission we use it to filter and sort nearby events. You can turn it off in system settings. We do not sell location data.',
    ),
    LegalSection(
      'Children',
      'SpotVibe is not directed at children under 13. We do not knowingly collect personal information from children under 13. If you believe we have, email $kLegalContactEmail and we will delete it.',
    ),
    LegalSection(
      'Retention and your choices',
      'We keep account and event data while your account is open, and for a reasonable period after if needed for backups, disputes, or law.\n\n'
          'You may access or update your profile in the app, delete events you created, and sign out. To delete your account and associated personal data, email $kLegalContactEmail from the address on the account. We aim to complete deletion requests within 30 days, except where we must keep records (for example a paid invoice or a legal hold).\n\n'
          'You can turn off notifications in the app and location in system settings. You can cancel a subscription in your Apple or Google account settings; we cannot cancel a store subscription for you.',
    ),
    LegalSection(
      'Security',
      'We use industry-standard services (Firebase Authentication, HTTPS) to protect data. No method of transmission or storage is 100% secure.\n\n'
          'Our providers may process data in the United States and other countries. If you use SpotVibe from outside the U.S., you understand your information may be transferred to the U.S.',
    ),
    LegalSection(
      'U.S. state privacy rights',
      'Depending on where you live (including Texas and California), you may have the right to know, access, correct, or delete personal information, and to opt out of certain sharing. Email $kLegalContactEmail. We will not discriminate against you for exercising these rights. We do not sell personal information or share it for cross-context behavioral advertising.',
    ),
    LegalSection(
      'Changes',
      'We may update this policy. We will change the effective date above and, if changes are material, notify you in the app or by email. Continued use after the update means you accept the revised policy.',
    ),
    LegalSection(
      'Contact',
      'SpotVibe\nEl Paso, Texas\n$kLegalContactEmail',
    ),
  ],
);

const LegalDocument kTermsOfUse = LegalDocument(
  title: 'Terms of Use',
  intro:
      'These Terms of Use are a contract between you and $kLegalEntityName (“SpotVibe,” “we,” “us”) for the SpotVibe apps and related services. Effective $kLegalEffectiveDate. By creating an account, browsing as a guest, posting an event, or starting a subscription, you agree to these Terms and our Privacy Policy.',
  sections: [
    LegalSection(
      'The service',
      'SpotVibe is a local events discovery and listing app. Some events are posted by users. Some listings come from official sources such as the Ticketmaster Discovery API. Ticket availability and prices on third-party sites can change and are not controlled by us.',
    ),
    LegalSection(
      'Eligibility and accounts',
      'You must be at least 13 years old. If you are under 18, you need a parent or guardian’s permission.\n\n'
          'You are responsible for your login and for activity on your account. Give us accurate information. Do not impersonate a venue or another person.',
    ),
    LegalSection(
      'Your content',
      'You keep ownership of events, photos, comments, and claim materials you submit. You grant SpotVibe a worldwide, non-exclusive license to host, display, and distribute that content in the app and in shares or previews so the service can work.\n\n'
          'Events must be real, not duplicates, and use accurate images of that event or venue. Do not post spam, illegal activity, hate, harassment, sexual content involving minors, or anyone’s private information.\n\n'
          'We may remove content or suspend accounts that break these rules, including false venue claims.',
    ),
    LegalSection(
      'Claims',
      'Claiming a listing requires verification that you are authorized. Your first approved claim is free. Later claims may require SpotVibe Premium. We may reject or reverse a claim. False claims can lead to suspension.',
    ),
    LegalSection(
      'Subscriptions and payments',
      'Free: browse the feed and post up to two upcoming one-time events at a time.\n\n'
          'SpotVibe Premium is an auto-renewing subscription. After a 7-day free trial (if offered), it costs \$12.99 per month, unless you are one of the first 25 founding venues and purchase the founding plan at \$9.99 per month. Prices may appear in your local currency and may include tax.\n\n'
          'Payment is charged to your Apple App Store or Google Play account. Your subscription renews each month until you cancel. Cancel at least 24 hours before the end of the current period in your Apple or Google subscription settings. Unused portions of a period are generally not refundable except where required by law or store policy.\n\n'
          'If you start a free trial and do not cancel before it ends, you will be charged the then-current subscription price. Managing or restoring purchases is handled by Apple or Google. We do not get your full payment card number.',
    ),
    LegalSection(
      'Tickets and third parties',
      '“Get tickets” links open Ticketmaster or another official seller. Their terms and privacy policies apply to that purchase. SpotVibe is not the ticket seller and is not responsible for sold-out shows, refunds, or venue entry.',
    ),
    LegalSection(
      'Acceptable use',
      'Do not scrape the service, overload our systems, reverse engineer the app except as allowed by law, upload malware, or use SpotVibe to break the law. Automated collection of Ticketmaster or other third-party data through our app is not allowed.',
    ),
    LegalSection(
      'Intellectual property',
      'SpotVibe’s name, logo, and app design are ours. Third-party marks (including Ticketmaster) belong to their owners. You may not use our marks without permission.',
    ),
    LegalSection(
      'Disclaimers',
      'THE SERVICE IS PROVIDED “AS IS.” WE DO NOT WARRANT THAT LISTINGS ARE COMPLETE, THAT AN EVENT WILL OCCUR AS DESCRIBED, OR THAT THE APP WILL BE UNINTERRUPTED OR ERROR-FREE. TO THE MAXIMUM EXTENT ALLOWED BY LAW WE DISCLAIM IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT.',
    ),
    LegalSection(
      'Limitation of liability',
      'TO THE MAXIMUM EXTENT ALLOWED BY LAW, SPOTVIBE AND ITS OWNERS WILL NOT BE LIABLE FOR INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES, OR FOR LOST PROFITS, LOST DATA, OR LOST TICKETS. OUR TOTAL LIABILITY FOR ANY CLAIM RELATING TO THE SERVICE IS LIMITED TO THE GREATER OF (A) THE AMOUNTS YOU PAID US FOR PREMIUM IN THE 12 MONTHS BEFORE THE CLAIM OR (B) \$50. SOME STATES DO NOT ALLOW CERTAIN LIMITS; IN THOSE STATES OUR LIABILITY IS LIMITED TO THE FULLEST EXTENT PERMITTED.',
    ),
    LegalSection(
      'Indemnity',
      'You will defend and indemnify SpotVibe against claims arising from your content, your events, your claims of venue ownership, or your misuse of the service.',
    ),
    LegalSection(
      'Termination',
      'You may stop using SpotVibe and request account deletion at any time. We may suspend or terminate access if you violate these Terms. Sections that should survive (including licenses already granted, disclaimers, and liability limits) will survive.',
    ),
    LegalSection(
      'Copyright',
      'If you believe content on SpotVibe infringes your copyright, email $kLegalContactEmail with: (1) your contact information, (2) a description of the work, (3) the URL or event title of the material, (4) a statement that you have a good-faith belief the use is not authorized, (5) a statement under penalty of perjury that the notice is accurate and you are the owner or authorized to act, and (6) your physical or electronic signature. We may remove the material and, in appropriate cases, terminate repeat infringers.',
    ),
    LegalSection(
      'Apple and Google',
      'If you download SpotVibe from the App Store or Google Play, Apple or Google is not a party to these Terms and is not responsible for the app or its content. You and Spotvibe LLC — not Apple — are responsible for claims relating to the app, including product liability, legal compliance, and intellectual-property claims, to the extent required by Apple’s standard licensed-application terms. Apple and Apple’s subsidiaries are third-party beneficiaries of this section and may enforce it. The same idea applies to Google for Play-distributed copies, to the extent Google’s terms require it.',
    ),
    LegalSection(
      'Governing law',
      'These Terms are governed by the laws of the State of Texas, excluding conflict-of-law rules. Courts in El Paso County, Texas will have exclusive jurisdiction, except that you or we may seek injunctive relief in any court for intellectual-property or abuse issues.',
    ),
    LegalSection(
      'General',
      'These Terms and the Privacy Policy are the entire agreement between you and Spotvibe LLC about the service. If a court finds a part unenforceable, the rest still applies. If we do not enforce a right, we do not waive it. You may not assign these Terms without our consent; we may assign them in a merger, sale, or reorganization. Headings are for convenience only.',
    ),
    LegalSection(
      'Changes',
      'We may update these Terms. We will update the effective date and, for material changes, notify you in the app or by email. If you keep using SpotVibe after the change, you accept the new Terms. If you do not agree, stop using the service and cancel any subscription in your store account.',
    ),
    LegalSection(
      'Contact',
      '$kLegalEntityName\nEl Paso, Texas\n$kLegalContactEmail',
    ),
  ],
);
