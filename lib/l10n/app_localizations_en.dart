// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'SpotVibe';

  @override
  String get continueBtn => 'Continue';

  @override
  String get skipForNow => 'Skip for now';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get allow => 'Allow';

  @override
  String get allowed => 'Allowed';

  @override
  String get denied => 'Denied';

  @override
  String get close => 'Close';

  @override
  String get optional => 'Optional';

  @override
  String get fullNameLabel => 'Full Name';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get createAccount => 'Create Account';

  @override
  String get signIn => 'Sign In';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get passwordResetBackend =>
      'Password reset requires a backend integration.';

  @override
  String get emailRequired => 'Email is required';

  @override
  String get validEmail => 'Enter a valid email address';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get passwordMinChars => 'Password must be at least 6 characters';

  @override
  String get fullNameRequired => 'Full name is required';

  @override
  String get alreadyHaveAccount => 'Already have an account? Sign in';

  @override
  String get noAccountCreate => 'Don\'t have an account? Create one';

  @override
  String get orContinueWithEmail => 'or continue with email';

  @override
  String get continueAsGuest => 'Continue as Guest';

  @override
  String get agreeToTermsPrefix => 'By continuing you agree to our ';

  @override
  String get termsOfUse => 'Terms of Use';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get google => 'Google';

  @override
  String get facebook => 'Facebook';

  @override
  String get apple => 'Apple';

  @override
  String get discoverTitle => 'Discover events\nhappening near you';

  @override
  String get discoverBody =>
      'SpotVibe surfaces the best local events — concerts, food festivals, community meetups and more — personalised to what you love.';

  @override
  String get nearYou => 'Near you';

  @override
  String get personalised => 'Personalised';

  @override
  String get social => 'Social';

  @override
  String get reminders => 'Reminders';

  @override
  String get quickPermsTitle => 'A couple of quick\npermissions';

  @override
  String get quickPermsBody =>
      'Granting these makes SpotVibe way more useful. You can change them at any time in Settings.';

  @override
  String get location => 'Location';

  @override
  String get locationDesc =>
      'Find events happening right near you. Only used while the app is open — never in the background.';

  @override
  String get notifications => 'Notifications';

  @override
  String get notifDesc =>
      'Get alerts for events you care about, RSVP reminders, and social updates.';

  @override
  String get whatAreYouInto => 'What are you into?';

  @override
  String get pickInterestsBody =>
      'Pick your interests and we\'ll show you events you\'ll actually care about.';

  @override
  String get selectAtLeastOne =>
      'Select at least one to personalise your feed.';

  @override
  String get allSetTitle => 'You\'re all set! 🎉';

  @override
  String get allSetBody =>
      'Your personalised event feed is ready.\nTap Explore to see what\'s happening near you.';

  @override
  String get browseNearYou => 'Browse events near you';

  @override
  String get filterByDatePrice => 'Filter by date, price & category';

  @override
  String get seeWhosGoing => 'See who else is going';

  @override
  String get exploreSpotVibe => 'Explore SpotVibe';

  @override
  String get interestMusic => 'Music';

  @override
  String get interestSports => 'Sports';

  @override
  String get interestFoodDrink => 'Food & Drink';

  @override
  String get interestArts => 'Arts';

  @override
  String get interestNightlife => 'Nightlife';

  @override
  String get interestComedy => 'Comedy';

  @override
  String get interestCommunity => 'Community';

  @override
  String get interestTech => 'Tech';

  @override
  String get interestFitness => 'Fitness';

  @override
  String get interestFamily => 'Family';

  @override
  String get interestOutdoor => 'Outdoor';

  @override
  String get interestFilm => 'Film';

  @override
  String get setupTitle => 'Let\'s set up SpotVibe';

  @override
  String get setupBody =>
      'A couple of quick permissions make the experience\nway better.';

  @override
  String get locationCardDesc =>
      'Find events happening near you. SpotVibe uses your location only while the app is open — never in the background.';

  @override
  String get notifCardDesc =>
      'Get alerts for new events near you, messages from friends, and updates on events you\'re attending.';

  @override
  String get changeSettingsAnytime =>
      'You can change these settings at any time in your device\'s Settings app.';

  @override
  String get profile => 'Profile';

  @override
  String get browsingAsGuest => 'Browsing as Guest';

  @override
  String get guestPrompt =>
      'Create an account to RSVP, leave comments, create events, and connect with others.';

  @override
  String get signInOrCreate => 'Sign In or Create Account';

  @override
  String get notificationsSettings => 'Notifications';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get map => 'Map';

  @override
  String get myEvents => 'My Events';

  @override
  String get savedEvents => 'Saved Events';

  @override
  String get signOut => 'Sign Out';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get language => 'Language';

  @override
  String get languageSystemDefault => 'System default';

  @override
  String get english => 'English';

  @override
  String get spanish => 'Español (México)';

  @override
  String get deleteAccountTitle => 'Delete account?';

  @override
  String get deleteAccountBody =>
      'This permanently deletes your account, profile, events, RSVPs, and comments. This cannot be undone.';

  @override
  String get passwordEmailAccounts => 'Password (email accounts)';

  @override
  String get accountDeletedMsg => 'Your account and data have been deleted.';

  @override
  String get forPromoters => 'For promoters, venues, and organizers';

  @override
  String thenPrice(String price) {
    return 'then $price';
  }

  @override
  String foundingLock(String price, int remaining, int limit) {
    return 'Founding venues lock $price — $remaining of $limit left';
  }

  @override
  String get freeTier => 'Free — \$0';

  @override
  String premiumTier(String price) {
    return 'Premium — $price';
  }

  @override
  String get everythingPlus => 'Everything in Free, plus the tools below.';

  @override
  String get welcomePremium => 'Welcome to SpotVibe Premium.';

  @override
  String get restorePurchases => 'Restore Purchases';

  @override
  String get noSubscriptionFound => 'No subscription found to restore.';

  @override
  String get bySubscribingPrefix => 'By subscribing you agree to our ';

  @override
  String get youAreOnPremium => 'You\'re on Premium';

  @override
  String get premiumUnlockedBody =>
      'Recurring events, analytics, branding, and verified claims are unlocked.';

  @override
  String get freePerk1 => 'Post up to 2 upcoming one-time events at a time';

  @override
  String get freePerk2 =>
      'Basic event page — title, description, photo, location, time';

  @override
  String get freePerk3 => 'Event appears in the public feed';

  @override
  String get premiumPerk1Title => 'Recurring events';

  @override
  String get premiumPerk1Subtitle => 'Post once — repeats weekly or monthly';

  @override
  String get premiumPerk2Title => 'Featured placement';

  @override
  String get premiumPerk2Subtitle => 'Top of the category feed 1× per week';

  @override
  String get premiumPerk3Title => 'Analytics dashboard';

  @override
  String get premiumPerk3Subtitle => 'Live views, saves, and click-throughs';

  @override
  String get premiumPerk4Title => 'Custom branding';

  @override
  String get premiumPerk4Subtitle => 'Logo and brand colors on your event page';

  @override
  String get premiumPerk5Title => 'Contact button';

  @override
  String get premiumPerk5Subtitle => 'Phone, website, and social links';

  @override
  String get premiumPerk6Title => 'No ads';

  @override
  String get premiumPerk6Subtitle => 'Clean event pages with no ads';

  @override
  String get premiumPerk7Title => 'Claim existing events';

  @override
  String get premiumPerk7Subtitle => 'Verify first. Your first claim is free';

  @override
  String get trialLabel => '7-day free trial';

  @override
  String get startFreeTrial => 'Start 7-day free trial';

  @override
  String perMonth(String price) {
    return '$price/month';
  }

  @override
  String afterTrial(String trial) {
    return 'after a $trial';
  }

  @override
  String billingFoundingOpen(
    String trial,
    String price,
    int remaining,
    int limit,
  ) {
    return '$trial, then $price locked for founding venues · $remaining of $limit left · cancel anytime';
  }

  @override
  String billingFoundingLocked(String price) {
    return 'Founding price locked at $price · billed monthly · cancel anytime';
  }

  @override
  String billingStandard(String trial, String price) {
    return '$trial, then $price · billed monthly · cancel anytime';
  }

  @override
  String get purchaseFailed => 'Purchase failed. Please try again.';

  @override
  String get noActiveSubscription => 'No active subscription found to restore.';

  @override
  String get restoreFailed => 'Restore failed. Please try again.';

  @override
  String get filtersTooltip => 'Filters';

  @override
  String get couldNotGetLocation =>
      'Could not get your location. Please allow location access.';

  @override
  String showingEventsIn(String area) {
    return 'Showing events in \"$area\"';
  }

  @override
  String get clear => 'Clear';

  @override
  String searchResults(int count, String query) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count results for \"$query\"',
      one: '1 result for \"$query\"',
    );
    return '$_temp0';
  }

  @override
  String get nearestFirst => 'Nearest first';

  @override
  String get byDate => 'By date';

  @override
  String get errorTitle => 'Couldn\'t load events';

  @override
  String get errorSubtitle =>
      'Check your connection and try again. Your saved events are still available.';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get viewSavedEvents => 'View Saved Events';

  @override
  String get noMatchesTitle => 'No matches for these filters';

  @override
  String get noMatchesSubtitle =>
      'Try broadening your search — adjust the date, price, or category filters to see more events.';

  @override
  String get clearFilters => 'Clear Filters';

  @override
  String noEventsNear(String area) {
    return 'No events near \"$area\"';
  }

  @override
  String get noEventsNearSubtitle =>
      'Try a different city, zip code, or increase your search radius in the filter options.';

  @override
  String get increaseRadius => 'Increase Radius';

  @override
  String get clearLocation => 'Clear Location';

  @override
  String get locationNeededTitle => 'Location needed';

  @override
  String get locationNeededSubtitle =>
      'Enable location so SpotVibe can find events happening near you right now.';

  @override
  String get enableLocation => 'Enable Location';

  @override
  String get browseAllEvents => 'Browse All Events';

  @override
  String get noEventsFoundTitle => 'No events found nearby';

  @override
  String get noEventsFoundSubtitle =>
      'Try increasing your search radius or check back later — new events are added every day.';

  @override
  String get shareEventTooltip => 'Share event';

  @override
  String get featuredThisWeek => 'FEATURED THIS WEEK';

  @override
  String get tickets => 'Tickets';

  @override
  String get aboutThisEvent => 'About this Event';

  @override
  String get organizer => 'Organizer';

  @override
  String bookmarkedCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Bookmarked',
      one: '1 Bookmarked',
    );
    return '$_temp0';
  }

  @override
  String interestedCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Interested',
      one: '1 Interested',
    );
    return '$_temp0';
  }

  @override
  String followingName(String name) {
    return 'Following $name';
  }

  @override
  String unfollowedName(String name) {
    return 'Unfollowed $name';
  }

  @override
  String get userBlocked => 'User blocked';

  @override
  String get reportUser => 'Report User';

  @override
  String get reasonForReporting => 'Reason for reporting...';

  @override
  String get reportSubmitted => 'Report submitted';

  @override
  String get submit => 'Submit';

  @override
  String get freePlanLimit => 'Free plan limit';

  @override
  String freePlanLimitBody(String trial) {
    return 'Free accounts can have 2 upcoming one-time events at a time. Start a $trial for unlimited and recurring events.';
  }

  @override
  String get notNow => 'Not now';

  @override
  String get goPremium => 'Go Premium';

  @override
  String policyViolation(String category, String reason) {
    return '$category policy violation: $reason';
  }

  @override
  String contentWarning(String category, String reason) {
    return '$category warning: $reason Your event will still be submitted.';
  }

  @override
  String get content => 'Content';

  @override
  String get eventUpdated => 'Event updated!';

  @override
  String get eventCreated => 'Event created!';

  @override
  String get editEvent => 'Edit Event';

  @override
  String get createEvent => 'Create Event';

  @override
  String get save => 'Save';

  @override
  String get publish => 'Publish';

  @override
  String get eventPublishing => 'Event Publishing';

  @override
  String get eventDetails => 'Event Details';

  @override
  String get eventTitle => 'Event Title';

  @override
  String get eventTitleHint => 'e.g. Summer Night Market';

  @override
  String get titleRequired => 'Title is required';

  @override
  String get description => 'Description';

  @override
  String get descriptionHint => 'Tell people what your event is about...';

  @override
  String get descriptionRequired => 'Description is required';

  @override
  String get dateAndTime => 'Date & Time';

  @override
  String get date => 'Date';

  @override
  String get time => 'Time';

  @override
  String get locationSection => 'Location';

  @override
  String get venueName => 'Venue Name';

  @override
  String get venueNameHint => 'e.g. Riverside Park';

  @override
  String get venueNameRequired => 'Venue name is required';

  @override
  String get streetAddress => 'Street Address';

  @override
  String get streetAddressHint => '123 Main St';

  @override
  String get city => 'City';

  @override
  String get cityHint => 'New York';

  @override
  String get state => 'State';

  @override
  String get stateHint => 'NY';

  @override
  String get zip => 'ZIP';

  @override
  String get zipHint => '10001';

  @override
  String get mapLinkOptional => 'Map Link (optional)';

  @override
  String get extras => 'Extras';

  @override
  String get ticketPriceLabel => 'Ticket Price (leave blank for free)';

  @override
  String get enterValidPrice => 'Enter a valid price';

  @override
  String get eventImageUrl => 'Event Image URL (optional)';

  @override
  String get eventVideoUrl => 'Event Video URL (optional)';

  @override
  String get chatLink => 'Community Chat Link (optional)';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get publishPremium => 'Publish Event — Premium';

  @override
  String get publishFree => 'Publish Event — Free';

  @override
  String get premium => 'Premium';

  @override
  String get premiumFeaturesSubtitle =>
      'Recurring events · analytics · custom branding · contact button';

  @override
  String get premiumFeaturesUnlocked => 'Premium features unlocked';

  @override
  String get recurringSchedule => 'Recurring Schedule';

  @override
  String get contactInfo => 'Contact Info';

  @override
  String get phoneOptional => 'Phone (optional)';

  @override
  String get websiteOptional => 'Website (optional)';

  @override
  String get socialHandleOptional => 'Social Handle (optional)';

  @override
  String get customBranding => 'Custom Branding';

  @override
  String get brandAccentColor => 'Brand Accent Color';

  @override
  String get brandLogoUrl => 'Brand Logo URL (optional)';

  @override
  String get oneTime => 'One-time';

  @override
  String get weekly => 'Weekly';

  @override
  String get monthly => 'Monthly';

  @override
  String get category => 'Category';

  @override
  String get premiumUnlimited => 'Premium — unlimited events';

  @override
  String get premiumIncludes =>
      'Recurring events, analytics, branding, and claims are included.';

  @override
  String get freePlan => 'Free plan';

  @override
  String get freePlanBody =>
      'One upcoming one-time event at a time. Basic page (title, description, photo, location, time) in the public feed.';

  @override
  String upgradeToPremium(String price) {
    return 'Upgrade to Premium — $price';
  }

  @override
  String get searchHint => 'Search events, artists, venues...';

  @override
  String get areaHint => 'Zip code, city, or state...';

  @override
  String get usingYourLocation => 'Using your location';

  @override
  String get useMyLocation => 'Use my location';

  @override
  String get featured => 'FEATURED';

  @override
  String byOrganizer(String name) {
    return 'by $name';
  }

  @override
  String get underTenthMi => '<0.1 mi';

  @override
  String miShort(String value) {
    return '$value mi';
  }

  @override
  String get couldNotOpenTickets => 'Could not open tickets.';

  @override
  String get getTicketsOnTm => 'Get tickets on Ticketmaster';

  @override
  String get getTickets => 'Get tickets';

  @override
  String get logInToRsvp => 'Log in to RSVP';

  @override
  String get rsvpToThisEvent => 'RSVP to this Event';

  @override
  String get youAreAttending => 'You\'re attending!';

  @override
  String get privateRsvp => 'Private RSVP';

  @override
  String get publicRsvp => 'Public RSVP';

  @override
  String get cancelRsvp => 'Cancel RSVP';

  @override
  String get rsvpSubtitle =>
      'Let others know you\'re going, or keep it private.';

  @override
  String get keepPrivate => 'Keep my RSVP private';

  @override
  String get onlyCountVisible =>
      'Only the count will be visible — not your name.';

  @override
  String get nameWillAppear => 'Your name will appear in the attendees list.';

  @override
  String get confirmRsvp => 'Confirm RSVP';

  @override
  String get claimPromo =>
      'Promoter? Verify this listing — first claim is free.';

  @override
  String get calendarError =>
      'Could not open calendar. Please add the event manually.';

  @override
  String get googleCalendarError => 'Could not open Google Calendar.';

  @override
  String get addToGoogleCalendar => 'Add to Google Calendar';

  @override
  String get addToAppleCalendar => 'Add to Apple Calendar';

  @override
  String get sponsored => 'Sponsored';

  @override
  String get goingOutThisWeek => 'Going out this week?';

  @override
  String get pageAdBody =>
      'SpotVibe shows live music, food, and nightlife near you — no hunting around town.';

  @override
  String get browseEvents => 'Browse events';

  @override
  String get comments => 'Comments';

  @override
  String get noCommentsYet => 'No comments yet. Be the first!';

  @override
  String get logInToComment => 'Log in to leave a comment';

  @override
  String get justNow => 'just now';

  @override
  String minutesAgo(int minutes) {
    return '${minutes}m ago';
  }

  @override
  String hoursAgo(int hours) {
    return '${hours}h ago';
  }

  @override
  String get you => 'You';

  @override
  String detectedLabel(String category) {
    return '$category Detected';
  }

  @override
  String warningLabel(String category) {
    return '$category Warning';
  }

  @override
  String get reviewComment => 'Please review your comment.';

  @override
  String get addCommentHint => 'Add a comment…';

  @override
  String get whosGoing => 'Who\'s going';

  @override
  String get noRsvpsYet => 'No one has RSVP\'d yet';

  @override
  String get beFirstToGo => 'Be the first to say you\'re going.';

  @override
  String get attendeesPrivate => 'Attendees are keeping their RSVPs private.';

  @override
  String peopleGoing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people are going',
      one: '1 person is going',
    );
    return '$_temp0';
  }

  @override
  String get bePartOfExperience => 'Be part of the experience';

  @override
  String privateCount(int count) {
    return '+$count private';
  }

  @override
  String get mapsError => 'Could not open maps for this venue.';

  @override
  String get reportEvent => 'Report Event';

  @override
  String get whatsWrong => 'What\'s wrong with this event?';

  @override
  String get reportSubmittedThanks => 'Report submitted. Thank you!';

  @override
  String get calendar => 'Calendar';

  @override
  String get directions => 'Directions';

  @override
  String get share => 'Share';

  @override
  String get story => 'Story';

  @override
  String get reportThisEvent => 'Report this event';

  @override
  String get practicalInfo => 'Practical Info';

  @override
  String get weather => 'Weather';

  @override
  String get weatherValue => 'Check forecast closer to the date';

  @override
  String get parking => 'Parking';

  @override
  String get parkingValue => 'Street parking & nearby lots available';

  @override
  String get duration => 'Duration';

  @override
  String get age => 'Age';

  @override
  String get accessible => 'Accessible';

  @override
  String get accessibleValue => 'Wheelchair accessible venue';

  @override
  String get dur2to3 => '2–3 hours';

  @override
  String get dur2to4 => '2–4 hours';

  @override
  String get dur1to2 => '1–2 hours';

  @override
  String get dur1to3 => '1–3 hours';

  @override
  String get dur15to25 => '1.5–2.5 hours';

  @override
  String get dur3to5 => '3–5 hours';

  @override
  String get age21plus => '21+ only';

  @override
  String get age18plus => '18+';

  @override
  String get moreLikeThis => 'More like this';

  @override
  String get seeAll => 'See all';

  @override
  String get whyAmISeeing => 'Why am I seeing this?';

  @override
  String get personalizationBody =>
      'SpotVibe learns from how you interact with events — what you view, save, and RSVP to. Over time, the feed re-orders to show more of what you enjoy.';

  @override
  String get topInterests => 'Your top interests right now:';

  @override
  String get resetMyPreferences => 'Reset my preferences';

  @override
  String get gotIt => 'Got it';

  @override
  String get personalizingFeed => 'Personalizing your feed…';

  @override
  String get showingMore => 'Showing more ';

  @override
  String get forYou => ' for you';

  @override
  String showingAll(int total) {
    return 'Showing all $total events';
  }

  @override
  String showingRange(int start, int end, int total) {
    return 'Showing $start–$end of $total events';
  }

  @override
  String get previous => 'Previous';

  @override
  String pageXOfY(int page, int total) {
    return 'Page $page of $total';
  }

  @override
  String get next => 'Next';

  @override
  String get allDates => 'All dates';

  @override
  String get today => 'Today';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String get thisWeekend => 'This weekend';

  @override
  String get thisWeek => 'This week';

  @override
  String get customRange => 'Custom range';

  @override
  String get anyPrice => 'Any price';

  @override
  String get free => 'Free';

  @override
  String get under20 => 'Under \$20';

  @override
  String get under50 => 'Under \$50';

  @override
  String get anyTime => 'Any time';

  @override
  String get morning => 'Morning';

  @override
  String get afternoon => 'Afternoon';

  @override
  String get evening => 'Evening';

  @override
  String get night => 'Night';

  @override
  String get anyDate => 'Any date';

  @override
  String get anyDistance => 'Any distance';

  @override
  String get filterEvents => 'Filter Events';

  @override
  String get clearAll => 'Clear all';

  @override
  String get from => 'From';

  @override
  String get to => 'To';

  @override
  String get price => 'Price';

  @override
  String get timeOfDay => 'Time of Day';

  @override
  String get distance => 'Distance';

  @override
  String get any => 'Any';

  @override
  String get locationHint => 'e.g. Brooklyn, Manhattan...';

  @override
  String get eventSources => 'Event Sources';

  @override
  String get showResults => 'Show Results';

  @override
  String get catAll => 'All';

  @override
  String get catMusic => 'Music';

  @override
  String get catFood => 'Food';

  @override
  String get catFoodDrink => 'Food & Drink';

  @override
  String get catArts => 'Arts';

  @override
  String get catSports => 'Sports';

  @override
  String get catTech => 'Tech';

  @override
  String get catCommunity => 'Community';

  @override
  String get catFamily => 'Family';

  @override
  String get catWellness => 'Wellness';

  @override
  String get catSocial => 'Social';

  @override
  String get catMarkets => 'Markets';

  @override
  String get catDance => 'Dance';

  @override
  String get catFunGames => 'Fun & Games';

  @override
  String get catHealth => 'Health';

  @override
  String get catOther => 'Other';

  @override
  String get catNightlife => 'Nightlife';

  @override
  String get catComedy => 'Comedy';

  @override
  String get catFitness => 'Fitness';

  @override
  String get catOutdoor => 'Outdoor';

  @override
  String get catFilm => 'Film';

  @override
  String activeLabel(String price) {
    return 'Active — $price';
  }

  @override
  String trialActiveLabel(String price) {
    return 'Trial active — then $price';
  }

  @override
  String get and => ' and ';

  @override
  String get tourNext => 'Next';

  @override
  String get tourDone => 'Done';

  @override
  String get tourSkip => 'Skip';

  @override
  String get takeTheTour => 'Take the tour';

  @override
  String get tourRestarted =>
      'Tour restarted. It will play again on the next screens you open.';

  @override
  String get tourHome1Title => 'Welcome to SpotVibe';

  @override
  String get tourHome1Body =>
      'Find real events near you — concerts, food, nightlife and more.';

  @override
  String get tourHome2Title => 'Search events';

  @override
  String get tourHome2Body =>
      'Search by event, artist, or venue — or by zip code, city, or state.';

  @override
  String get tourHome3Title => 'Filter results';

  @override
  String get tourHome3Body =>
      'Narrow things down by date, price, time of day, distance, and more.';

  @override
  String get tourHome4Title => 'Browse categories';

  @override
  String get tourHome4Body =>
      'Tap a category to focus your feed on what you love.';

  @override
  String get tourHome5Title => 'Your event feed';

  @override
  String get tourHome5Body =>
      'Scroll to discover events. Tap any card for details, tickets, and RSVP.';

  @override
  String get tourEvent1Title => 'RSVP';

  @override
  String get tourEvent1Body =>
      'Tap here to say you\'re going — public or private, it\'s your call.';

  @override
  String get tourEvent2Title => 'Save & track';

  @override
  String get tourEvent2Body =>
      'Bookmark events or mark the ones you\'re interested in.';

  @override
  String get tourEvent3Title => 'Share';

  @override
  String get tourEvent3Body =>
      'Send the event to friends as a link or a share card.';

  @override
  String get tourProfile1Title => 'SpotVibe Premium';

  @override
  String get tourProfile1Body =>
      'Unlock recurring events, analytics, and custom branding.';

  @override
  String get tourProfile2Title => 'Language';

  @override
  String get tourProfile2Body => 'Switch between English and Spanish anytime.';

  @override
  String get tourProfile3Title => 'Your events';

  @override
  String get tourProfile3Body => 'Manage the events you\'ve created and saved.';

  @override
  String get adminDashboard => 'Admin Dashboard';

  @override
  String get adminReports => 'Reports';

  @override
  String get adminEvents => 'Events';

  @override
  String get adminNoReports => 'No open reports — you\'re all caught up.';

  @override
  String get adminResolve => 'Mark resolved';

  @override
  String get adminRemove => 'Remove';

  @override
  String get adminRemoveEvent => 'Remove event';

  @override
  String get adminRemoveEventTitle => 'Remove this event?';

  @override
  String get adminRemoveEventBody =>
      'This permanently removes the event, its comments, and its RSVPs from the public feed.';

  @override
  String get adminEventRemoved => 'Event removed.';

  @override
  String get adminReportResolved => 'Report resolved.';

  @override
  String get adminSearchEvents => 'Search events…';

  @override
  String get adminNoEvents => 'No events found.';

  @override
  String adminReason(String reason) {
    return 'Reason: $reason';
  }

  @override
  String adminReportedUser(String id) {
    return 'Reported user: $id';
  }

  @override
  String adminReportedBy(String id) {
    return 'Reported by: $id';
  }

  @override
  String get adminAccess => 'Admin';

  @override
  String get adminDeleteComment => 'Delete comment';

  @override
  String get adminCommentRemoved => 'Comment removed.';

  @override
  String get adminPostUnlimited =>
      'Official account — unlimited one-time events';

  @override
  String get adminSearchHint => 'Search by title, venue, or organizer…';

  @override
  String get adminDeleteCommentBody =>
      'This permanently removes the comment from the event page.';

  @override
  String get adminClaims => 'Claims';

  @override
  String get adminNoClaims => 'No venue claims yet.';

  @override
  String get adminApprove => 'Approve';

  @override
  String get adminReject => 'Reject';

  @override
  String get adminClaimApproved =>
      'Claim approved — the venue can now edit this listing.';

  @override
  String get adminClaimRejected => 'Claim rejected.';

  @override
  String get adminPending => 'Pending';

  @override
  String get adminApproved => 'Approved';

  @override
  String get adminRejected => 'Rejected';

  @override
  String get adminBanUser => 'Ban user';

  @override
  String get adminUnban => 'Unban';

  @override
  String get adminBannedUsers => 'Banned users';

  @override
  String get adminNoBanned => 'No banned users.';

  @override
  String get adminUserBanned => 'User banned — their content is now hidden.';

  @override
  String get adminUserUnbanned => 'User unbanned.';

  @override
  String get adminBanConfirmTitle => 'Ban this user?';

  @override
  String get adminBanConfirmBody =>
      'This hides all of their events, comments, and RSVPs from the app. You can undo this anytime.';

  @override
  String get claimRoleOwner => 'Owner / operator';

  @override
  String get claimRolePromoter => 'Authorized promoter';

  @override
  String get claimRoleBookingAgent => 'Booking agent';

  @override
  String get claimRoleMarketing => 'Marketing / PR';

  @override
  String get claimRoleOther => 'Other authorized rep';
}
