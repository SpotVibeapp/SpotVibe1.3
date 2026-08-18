import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'SpotVibe'**
  String get appTitle;

  /// No description provided for @continueBtn.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueBtn;

  /// No description provided for @skipForNow.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get skipForNow;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @allow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get allow;

  /// No description provided for @allowed.
  ///
  /// In en, this message translates to:
  /// **'Allowed'**
  String get allowed;

  /// No description provided for @denied.
  ///
  /// In en, this message translates to:
  /// **'Denied'**
  String get denied;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @fullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullNameLabel;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @passwordResetBackend.
  ///
  /// In en, this message translates to:
  /// **'Password reset requires a backend integration.'**
  String get passwordResetBackend;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// No description provided for @validEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get validEmail;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// No description provided for @passwordMinChars.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMinChars;

  /// No description provided for @fullNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Full name is required'**
  String get fullNameRequired;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get alreadyHaveAccount;

  /// No description provided for @noAccountCreate.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Create one'**
  String get noAccountCreate;

  /// No description provided for @orContinueWithEmail.
  ///
  /// In en, this message translates to:
  /// **'or continue with email'**
  String get orContinueWithEmail;

  /// No description provided for @continueAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue as Guest'**
  String get continueAsGuest;

  /// No description provided for @agreeToTermsPrefix.
  ///
  /// In en, this message translates to:
  /// **'By continuing you agree to our '**
  String get agreeToTermsPrefix;

  /// No description provided for @termsOfUse.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get termsOfUse;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @google.
  ///
  /// In en, this message translates to:
  /// **'Google'**
  String get google;

  /// No description provided for @facebook.
  ///
  /// In en, this message translates to:
  /// **'Facebook'**
  String get facebook;

  /// No description provided for @apple.
  ///
  /// In en, this message translates to:
  /// **'Apple'**
  String get apple;

  /// No description provided for @discoverTitle.
  ///
  /// In en, this message translates to:
  /// **'Discover events\nhappening near you'**
  String get discoverTitle;

  /// No description provided for @discoverBody.
  ///
  /// In en, this message translates to:
  /// **'SpotVibe surfaces the best local events — concerts, food festivals, community meetups and more — personalised to what you love.'**
  String get discoverBody;

  /// No description provided for @nearYou.
  ///
  /// In en, this message translates to:
  /// **'Near you'**
  String get nearYou;

  /// No description provided for @personalised.
  ///
  /// In en, this message translates to:
  /// **'Personalised'**
  String get personalised;

  /// No description provided for @social.
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get social;

  /// No description provided for @reminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get reminders;

  /// No description provided for @quickPermsTitle.
  ///
  /// In en, this message translates to:
  /// **'A couple of quick\npermissions'**
  String get quickPermsTitle;

  /// No description provided for @quickPermsBody.
  ///
  /// In en, this message translates to:
  /// **'Granting these makes SpotVibe way more useful. You can change them at any time in Settings.'**
  String get quickPermsBody;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @locationDesc.
  ///
  /// In en, this message translates to:
  /// **'Find events happening right near you. Only used while the app is open — never in the background.'**
  String get locationDesc;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @notifDesc.
  ///
  /// In en, this message translates to:
  /// **'Get alerts for events you care about, RSVP reminders, and social updates.'**
  String get notifDesc;

  /// No description provided for @whatAreYouInto.
  ///
  /// In en, this message translates to:
  /// **'What are you into?'**
  String get whatAreYouInto;

  /// No description provided for @pickInterestsBody.
  ///
  /// In en, this message translates to:
  /// **'Pick your interests and we\'ll show you events you\'ll actually care about.'**
  String get pickInterestsBody;

  /// No description provided for @selectAtLeastOne.
  ///
  /// In en, this message translates to:
  /// **'Select at least one to personalise your feed.'**
  String get selectAtLeastOne;

  /// No description provided for @allSetTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re all set! 🎉'**
  String get allSetTitle;

  /// No description provided for @allSetBody.
  ///
  /// In en, this message translates to:
  /// **'Your personalised event feed is ready.\nTap Explore to see what\'s happening near you.'**
  String get allSetBody;

  /// No description provided for @browseNearYou.
  ///
  /// In en, this message translates to:
  /// **'Browse events near you'**
  String get browseNearYou;

  /// No description provided for @filterByDatePrice.
  ///
  /// In en, this message translates to:
  /// **'Filter by date, price & category'**
  String get filterByDatePrice;

  /// No description provided for @seeWhosGoing.
  ///
  /// In en, this message translates to:
  /// **'See who else is going'**
  String get seeWhosGoing;

  /// No description provided for @exploreSpotVibe.
  ///
  /// In en, this message translates to:
  /// **'Explore SpotVibe'**
  String get exploreSpotVibe;

  /// No description provided for @interestMusic.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get interestMusic;

  /// No description provided for @interestSports.
  ///
  /// In en, this message translates to:
  /// **'Sports'**
  String get interestSports;

  /// No description provided for @interestFoodDrink.
  ///
  /// In en, this message translates to:
  /// **'Food & Drink'**
  String get interestFoodDrink;

  /// No description provided for @interestArts.
  ///
  /// In en, this message translates to:
  /// **'Arts'**
  String get interestArts;

  /// No description provided for @interestNightlife.
  ///
  /// In en, this message translates to:
  /// **'Nightlife'**
  String get interestNightlife;

  /// No description provided for @interestComedy.
  ///
  /// In en, this message translates to:
  /// **'Comedy'**
  String get interestComedy;

  /// No description provided for @interestCommunity.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get interestCommunity;

  /// No description provided for @interestTech.
  ///
  /// In en, this message translates to:
  /// **'Tech'**
  String get interestTech;

  /// No description provided for @interestFitness.
  ///
  /// In en, this message translates to:
  /// **'Fitness'**
  String get interestFitness;

  /// No description provided for @interestFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get interestFamily;

  /// No description provided for @interestOutdoor.
  ///
  /// In en, this message translates to:
  /// **'Outdoor'**
  String get interestOutdoor;

  /// No description provided for @interestFilm.
  ///
  /// In en, this message translates to:
  /// **'Film'**
  String get interestFilm;

  /// No description provided for @setupTitle.
  ///
  /// In en, this message translates to:
  /// **'Let\'s set up SpotVibe'**
  String get setupTitle;

  /// No description provided for @setupBody.
  ///
  /// In en, this message translates to:
  /// **'A couple of quick permissions make the experience\nway better.'**
  String get setupBody;

  /// No description provided for @locationCardDesc.
  ///
  /// In en, this message translates to:
  /// **'Find events happening near you. SpotVibe uses your location only while the app is open — never in the background.'**
  String get locationCardDesc;

  /// No description provided for @notifCardDesc.
  ///
  /// In en, this message translates to:
  /// **'Get alerts for new events near you, messages from friends, and updates on events you\'re attending.'**
  String get notifCardDesc;

  /// No description provided for @changeSettingsAnytime.
  ///
  /// In en, this message translates to:
  /// **'You can change these settings at any time in your device\'s Settings app.'**
  String get changeSettingsAnytime;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @browsingAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Browsing as Guest'**
  String get browsingAsGuest;

  /// No description provided for @guestPrompt.
  ///
  /// In en, this message translates to:
  /// **'Create an account to RSVP, leave comments, create events, and connect with others.'**
  String get guestPrompt;

  /// No description provided for @signInOrCreate.
  ///
  /// In en, this message translates to:
  /// **'Sign In or Create Account'**
  String get signInOrCreate;

  /// No description provided for @notificationsSettings.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsSettings;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @map.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get map;

  /// No description provided for @myEvents.
  ///
  /// In en, this message translates to:
  /// **'My Events'**
  String get myEvents;

  /// No description provided for @savedEvents.
  ///
  /// In en, this message translates to:
  /// **'Saved Events'**
  String get savedEvents;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSystemDefault.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystemDefault;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @spanish.
  ///
  /// In en, this message translates to:
  /// **'Español (México)'**
  String get spanish;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account?'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountBody.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes your account, profile, events, RSVPs, and comments. This cannot be undone.'**
  String get deleteAccountBody;

  /// No description provided for @passwordEmailAccounts.
  ///
  /// In en, this message translates to:
  /// **'Password (email accounts)'**
  String get passwordEmailAccounts;

  /// No description provided for @accountDeletedMsg.
  ///
  /// In en, this message translates to:
  /// **'Your account and data have been deleted.'**
  String get accountDeletedMsg;

  /// No description provided for @forPromoters.
  ///
  /// In en, this message translates to:
  /// **'For promoters, venues, and organizers'**
  String get forPromoters;

  /// No description provided for @thenPrice.
  ///
  /// In en, this message translates to:
  /// **'then {price}'**
  String thenPrice(String price);

  /// No description provided for @foundingLock.
  ///
  /// In en, this message translates to:
  /// **'Founding venues lock {price} — {remaining} of {limit} left'**
  String foundingLock(String price, int remaining, int limit);

  /// No description provided for @freeTier.
  ///
  /// In en, this message translates to:
  /// **'Free — \$0'**
  String get freeTier;

  /// No description provided for @premiumTier.
  ///
  /// In en, this message translates to:
  /// **'Premium — {price}'**
  String premiumTier(String price);

  /// No description provided for @everythingPlus.
  ///
  /// In en, this message translates to:
  /// **'Everything in Free, plus the tools below.'**
  String get everythingPlus;

  /// No description provided for @welcomePremium.
  ///
  /// In en, this message translates to:
  /// **'Welcome to SpotVibe Premium.'**
  String get welcomePremium;

  /// No description provided for @restorePurchases.
  ///
  /// In en, this message translates to:
  /// **'Restore Purchases'**
  String get restorePurchases;

  /// No description provided for @noSubscriptionFound.
  ///
  /// In en, this message translates to:
  /// **'No subscription found to restore.'**
  String get noSubscriptionFound;

  /// No description provided for @bySubscribingPrefix.
  ///
  /// In en, this message translates to:
  /// **'By subscribing you agree to our '**
  String get bySubscribingPrefix;

  /// No description provided for @youAreOnPremium.
  ///
  /// In en, this message translates to:
  /// **'You\'re on Premium'**
  String get youAreOnPremium;

  /// No description provided for @premiumUnlockedBody.
  ///
  /// In en, this message translates to:
  /// **'Recurring events, analytics, branding, and verified claims are unlocked.'**
  String get premiumUnlockedBody;

  /// No description provided for @freePerk1.
  ///
  /// In en, this message translates to:
  /// **'Post up to 2 upcoming one-time events at a time'**
  String get freePerk1;

  /// No description provided for @freePerk2.
  ///
  /// In en, this message translates to:
  /// **'Basic event page — title, description, photo, location, time'**
  String get freePerk2;

  /// No description provided for @freePerk3.
  ///
  /// In en, this message translates to:
  /// **'Event appears in the public feed'**
  String get freePerk3;

  /// No description provided for @premiumPerk1Title.
  ///
  /// In en, this message translates to:
  /// **'Recurring events'**
  String get premiumPerk1Title;

  /// No description provided for @premiumPerk1Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Post once — repeats weekly or monthly'**
  String get premiumPerk1Subtitle;

  /// No description provided for @premiumPerk2Title.
  ///
  /// In en, this message translates to:
  /// **'Featured placement'**
  String get premiumPerk2Title;

  /// No description provided for @premiumPerk2Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Top of the category feed 1× per week'**
  String get premiumPerk2Subtitle;

  /// No description provided for @premiumPerk3Title.
  ///
  /// In en, this message translates to:
  /// **'Analytics dashboard'**
  String get premiumPerk3Title;

  /// No description provided for @premiumPerk3Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Live views, saves, and click-throughs'**
  String get premiumPerk3Subtitle;

  /// No description provided for @premiumPerk4Title.
  ///
  /// In en, this message translates to:
  /// **'Custom branding'**
  String get premiumPerk4Title;

  /// No description provided for @premiumPerk4Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Logo and brand colors on your event page'**
  String get premiumPerk4Subtitle;

  /// No description provided for @premiumPerk5Title.
  ///
  /// In en, this message translates to:
  /// **'Contact button'**
  String get premiumPerk5Title;

  /// No description provided for @premiumPerk5Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Phone, website, and social links'**
  String get premiumPerk5Subtitle;

  /// No description provided for @premiumPerk6Title.
  ///
  /// In en, this message translates to:
  /// **'No ads'**
  String get premiumPerk6Title;

  /// No description provided for @premiumPerk6Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Clean event pages with no ads'**
  String get premiumPerk6Subtitle;

  /// No description provided for @premiumPerk7Title.
  ///
  /// In en, this message translates to:
  /// **'Claim existing events'**
  String get premiumPerk7Title;

  /// No description provided for @premiumPerk7Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Verify first. Your first claim is free'**
  String get premiumPerk7Subtitle;

  /// No description provided for @trialLabel.
  ///
  /// In en, this message translates to:
  /// **'7-day free trial'**
  String get trialLabel;

  /// No description provided for @startFreeTrial.
  ///
  /// In en, this message translates to:
  /// **'Start 7-day free trial'**
  String get startFreeTrial;

  /// No description provided for @perMonth.
  ///
  /// In en, this message translates to:
  /// **'{price}/month'**
  String perMonth(String price);

  /// No description provided for @afterTrial.
  ///
  /// In en, this message translates to:
  /// **'after a {trial}'**
  String afterTrial(String trial);

  /// No description provided for @billingFoundingOpen.
  ///
  /// In en, this message translates to:
  /// **'{trial}, then {price} locked for founding venues · {remaining} of {limit} left · cancel anytime'**
  String billingFoundingOpen(
    String trial,
    String price,
    int remaining,
    int limit,
  );

  /// No description provided for @billingFoundingLocked.
  ///
  /// In en, this message translates to:
  /// **'Founding price locked at {price} · billed monthly · cancel anytime'**
  String billingFoundingLocked(String price);

  /// No description provided for @billingStandard.
  ///
  /// In en, this message translates to:
  /// **'{trial}, then {price} · billed monthly · cancel anytime'**
  String billingStandard(String trial, String price);

  /// No description provided for @purchaseFailed.
  ///
  /// In en, this message translates to:
  /// **'Purchase failed. Please try again.'**
  String get purchaseFailed;

  /// No description provided for @noActiveSubscription.
  ///
  /// In en, this message translates to:
  /// **'No active subscription found to restore.'**
  String get noActiveSubscription;

  /// No description provided for @restoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Restore failed. Please try again.'**
  String get restoreFailed;

  /// No description provided for @filtersTooltip.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filtersTooltip;

  /// No description provided for @couldNotGetLocation.
  ///
  /// In en, this message translates to:
  /// **'Could not get your location. Please allow location access.'**
  String get couldNotGetLocation;

  /// No description provided for @showingEventsIn.
  ///
  /// In en, this message translates to:
  /// **'Showing events in \"{area}\"'**
  String showingEventsIn(String area);

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @searchResults.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 result for \"{query}\"} other{{count} results for \"{query}\"}}'**
  String searchResults(int count, String query);

  /// No description provided for @nearestFirst.
  ///
  /// In en, this message translates to:
  /// **'Nearest first'**
  String get nearestFirst;

  /// No description provided for @byDate.
  ///
  /// In en, this message translates to:
  /// **'By date'**
  String get byDate;

  /// No description provided for @errorTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load events'**
  String get errorTitle;

  /// No description provided for @errorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again. Your saved events are still available.'**
  String get errorSubtitle;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @viewSavedEvents.
  ///
  /// In en, this message translates to:
  /// **'View Saved Events'**
  String get viewSavedEvents;

  /// No description provided for @noMatchesTitle.
  ///
  /// In en, this message translates to:
  /// **'No matches for these filters'**
  String get noMatchesTitle;

  /// No description provided for @noMatchesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try broadening your search — adjust the date, price, or category filters to see more events.'**
  String get noMatchesSubtitle;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear Filters'**
  String get clearFilters;

  /// No description provided for @noEventsNear.
  ///
  /// In en, this message translates to:
  /// **'No events near \"{area}\"'**
  String noEventsNear(String area);

  /// No description provided for @noEventsNearSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try a different city, zip code, or increase your search radius in the filter options.'**
  String get noEventsNearSubtitle;

  /// No description provided for @increaseRadius.
  ///
  /// In en, this message translates to:
  /// **'Increase Radius'**
  String get increaseRadius;

  /// No description provided for @clearLocation.
  ///
  /// In en, this message translates to:
  /// **'Clear Location'**
  String get clearLocation;

  /// No description provided for @locationNeededTitle.
  ///
  /// In en, this message translates to:
  /// **'Location needed'**
  String get locationNeededTitle;

  /// No description provided for @locationNeededSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enable location so SpotVibe can find events happening near you right now.'**
  String get locationNeededSubtitle;

  /// No description provided for @enableLocation.
  ///
  /// In en, this message translates to:
  /// **'Enable Location'**
  String get enableLocation;

  /// No description provided for @browseAllEvents.
  ///
  /// In en, this message translates to:
  /// **'Browse All Events'**
  String get browseAllEvents;

  /// No description provided for @noEventsFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'No events found nearby'**
  String get noEventsFoundTitle;

  /// No description provided for @noEventsFoundSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try increasing your search radius or check back later — new events are added every day.'**
  String get noEventsFoundSubtitle;

  /// No description provided for @shareEventTooltip.
  ///
  /// In en, this message translates to:
  /// **'Share event'**
  String get shareEventTooltip;

  /// No description provided for @featuredThisWeek.
  ///
  /// In en, this message translates to:
  /// **'FEATURED THIS WEEK'**
  String get featuredThisWeek;

  /// No description provided for @tickets.
  ///
  /// In en, this message translates to:
  /// **'Tickets'**
  String get tickets;

  /// No description provided for @aboutThisEvent.
  ///
  /// In en, this message translates to:
  /// **'About this Event'**
  String get aboutThisEvent;

  /// No description provided for @organizer.
  ///
  /// In en, this message translates to:
  /// **'Organizer'**
  String get organizer;

  /// No description provided for @bookmarkedCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 Bookmarked} other{{count} Bookmarked}}'**
  String bookmarkedCountLabel(int count);

  /// No description provided for @interestedCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 Interested} other{{count} Interested}}'**
  String interestedCountLabel(int count);

  /// No description provided for @followingName.
  ///
  /// In en, this message translates to:
  /// **'Following {name}'**
  String followingName(String name);

  /// No description provided for @unfollowedName.
  ///
  /// In en, this message translates to:
  /// **'Unfollowed {name}'**
  String unfollowedName(String name);

  /// No description provided for @userBlocked.
  ///
  /// In en, this message translates to:
  /// **'User blocked'**
  String get userBlocked;

  /// No description provided for @reportUser.
  ///
  /// In en, this message translates to:
  /// **'Report User'**
  String get reportUser;

  /// No description provided for @reasonForReporting.
  ///
  /// In en, this message translates to:
  /// **'Reason for reporting...'**
  String get reasonForReporting;

  /// No description provided for @reportSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Report submitted'**
  String get reportSubmitted;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @freePlanLimit.
  ///
  /// In en, this message translates to:
  /// **'Free plan limit'**
  String get freePlanLimit;

  /// No description provided for @freePlanLimitBody.
  ///
  /// In en, this message translates to:
  /// **'Free accounts can have 2 upcoming one-time events at a time. Start a {trial} for unlimited and recurring events.'**
  String freePlanLimitBody(String trial);

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @goPremium.
  ///
  /// In en, this message translates to:
  /// **'Go Premium'**
  String get goPremium;

  /// No description provided for @policyViolation.
  ///
  /// In en, this message translates to:
  /// **'{category} policy violation: {reason}'**
  String policyViolation(String category, String reason);

  /// No description provided for @contentWarning.
  ///
  /// In en, this message translates to:
  /// **'{category} warning: {reason} Your event will still be submitted.'**
  String contentWarning(String category, String reason);

  /// No description provided for @content.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get content;

  /// No description provided for @eventUpdated.
  ///
  /// In en, this message translates to:
  /// **'Event updated!'**
  String get eventUpdated;

  /// No description provided for @eventCreated.
  ///
  /// In en, this message translates to:
  /// **'Event created!'**
  String get eventCreated;

  /// No description provided for @editEvent.
  ///
  /// In en, this message translates to:
  /// **'Edit Event'**
  String get editEvent;

  /// No description provided for @createEvent.
  ///
  /// In en, this message translates to:
  /// **'Create Event'**
  String get createEvent;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @publish.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get publish;

  /// No description provided for @eventPublishing.
  ///
  /// In en, this message translates to:
  /// **'Event Publishing'**
  String get eventPublishing;

  /// No description provided for @eventDetails.
  ///
  /// In en, this message translates to:
  /// **'Event Details'**
  String get eventDetails;

  /// No description provided for @eventTitle.
  ///
  /// In en, this message translates to:
  /// **'Event Title'**
  String get eventTitle;

  /// No description provided for @eventTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Summer Night Market'**
  String get eventTitleHint;

  /// No description provided for @titleRequired.
  ///
  /// In en, this message translates to:
  /// **'Title is required'**
  String get titleRequired;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @descriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Tell people what your event is about...'**
  String get descriptionHint;

  /// No description provided for @descriptionRequired.
  ///
  /// In en, this message translates to:
  /// **'Description is required'**
  String get descriptionRequired;

  /// No description provided for @dateAndTime.
  ///
  /// In en, this message translates to:
  /// **'Date & Time'**
  String get dateAndTime;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @locationSection.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get locationSection;

  /// No description provided for @venueName.
  ///
  /// In en, this message translates to:
  /// **'Venue Name'**
  String get venueName;

  /// No description provided for @venueNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Riverside Park'**
  String get venueNameHint;

  /// No description provided for @venueNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Venue name is required'**
  String get venueNameRequired;

  /// No description provided for @streetAddress.
  ///
  /// In en, this message translates to:
  /// **'Street Address'**
  String get streetAddress;

  /// No description provided for @streetAddressHint.
  ///
  /// In en, this message translates to:
  /// **'123 Main St'**
  String get streetAddressHint;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @cityHint.
  ///
  /// In en, this message translates to:
  /// **'New York'**
  String get cityHint;

  /// No description provided for @state.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get state;

  /// No description provided for @stateHint.
  ///
  /// In en, this message translates to:
  /// **'NY'**
  String get stateHint;

  /// No description provided for @zip.
  ///
  /// In en, this message translates to:
  /// **'ZIP'**
  String get zip;

  /// No description provided for @zipHint.
  ///
  /// In en, this message translates to:
  /// **'10001'**
  String get zipHint;

  /// No description provided for @mapLinkOptional.
  ///
  /// In en, this message translates to:
  /// **'Map Link (optional)'**
  String get mapLinkOptional;

  /// No description provided for @extras.
  ///
  /// In en, this message translates to:
  /// **'Extras'**
  String get extras;

  /// No description provided for @ticketPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Ticket Price (leave blank for free)'**
  String get ticketPriceLabel;

  /// No description provided for @enterValidPrice.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid price'**
  String get enterValidPrice;

  /// No description provided for @eventImageUrl.
  ///
  /// In en, this message translates to:
  /// **'Event Image URL (optional)'**
  String get eventImageUrl;

  /// No description provided for @eventVideoUrl.
  ///
  /// In en, this message translates to:
  /// **'Event Video URL (optional)'**
  String get eventVideoUrl;

  /// No description provided for @chatLink.
  ///
  /// In en, this message translates to:
  /// **'Community Chat Link (optional)'**
  String get chatLink;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @publishPremium.
  ///
  /// In en, this message translates to:
  /// **'Publish Event — Premium'**
  String get publishPremium;

  /// No description provided for @publishFree.
  ///
  /// In en, this message translates to:
  /// **'Publish Event — Free'**
  String get publishFree;

  /// No description provided for @premium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get premium;

  /// No description provided for @premiumFeaturesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Recurring events · analytics · custom branding · contact button'**
  String get premiumFeaturesSubtitle;

  /// No description provided for @premiumFeaturesUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Premium features unlocked'**
  String get premiumFeaturesUnlocked;

  /// No description provided for @recurringSchedule.
  ///
  /// In en, this message translates to:
  /// **'Recurring Schedule'**
  String get recurringSchedule;

  /// No description provided for @contactInfo.
  ///
  /// In en, this message translates to:
  /// **'Contact Info'**
  String get contactInfo;

  /// No description provided for @phoneOptional.
  ///
  /// In en, this message translates to:
  /// **'Phone (optional)'**
  String get phoneOptional;

  /// No description provided for @websiteOptional.
  ///
  /// In en, this message translates to:
  /// **'Website (optional)'**
  String get websiteOptional;

  /// No description provided for @socialHandleOptional.
  ///
  /// In en, this message translates to:
  /// **'Social Handle (optional)'**
  String get socialHandleOptional;

  /// No description provided for @customBranding.
  ///
  /// In en, this message translates to:
  /// **'Custom Branding'**
  String get customBranding;

  /// No description provided for @brandAccentColor.
  ///
  /// In en, this message translates to:
  /// **'Brand Accent Color'**
  String get brandAccentColor;

  /// No description provided for @brandLogoUrl.
  ///
  /// In en, this message translates to:
  /// **'Brand Logo URL (optional)'**
  String get brandLogoUrl;

  /// No description provided for @oneTime.
  ///
  /// In en, this message translates to:
  /// **'One-time'**
  String get oneTime;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @premiumUnlimited.
  ///
  /// In en, this message translates to:
  /// **'Premium — unlimited events'**
  String get premiumUnlimited;

  /// No description provided for @premiumIncludes.
  ///
  /// In en, this message translates to:
  /// **'Recurring events, analytics, branding, and claims are included.'**
  String get premiumIncludes;

  /// No description provided for @freePlan.
  ///
  /// In en, this message translates to:
  /// **'Free plan'**
  String get freePlan;

  /// No description provided for @freePlanBody.
  ///
  /// In en, this message translates to:
  /// **'One upcoming one-time event at a time. Basic page (title, description, photo, location, time) in the public feed.'**
  String get freePlanBody;

  /// No description provided for @upgradeToPremium.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Premium — {price}'**
  String upgradeToPremium(String price);

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search events, artists, venues...'**
  String get searchHint;

  /// No description provided for @areaHint.
  ///
  /// In en, this message translates to:
  /// **'Zip code, city, or state...'**
  String get areaHint;

  /// No description provided for @usingYourLocation.
  ///
  /// In en, this message translates to:
  /// **'Using your location'**
  String get usingYourLocation;

  /// No description provided for @useMyLocation.
  ///
  /// In en, this message translates to:
  /// **'Use my location'**
  String get useMyLocation;

  /// No description provided for @featured.
  ///
  /// In en, this message translates to:
  /// **'FEATURED'**
  String get featured;

  /// No description provided for @byOrganizer.
  ///
  /// In en, this message translates to:
  /// **'by {name}'**
  String byOrganizer(String name);

  /// No description provided for @underTenthMi.
  ///
  /// In en, this message translates to:
  /// **'<0.1 mi'**
  String get underTenthMi;

  /// No description provided for @miShort.
  ///
  /// In en, this message translates to:
  /// **'{value} mi'**
  String miShort(String value);

  /// No description provided for @couldNotOpenTickets.
  ///
  /// In en, this message translates to:
  /// **'Could not open tickets.'**
  String get couldNotOpenTickets;

  /// No description provided for @getTicketsOnTm.
  ///
  /// In en, this message translates to:
  /// **'Get tickets on Ticketmaster'**
  String get getTicketsOnTm;

  /// No description provided for @getTickets.
  ///
  /// In en, this message translates to:
  /// **'Get tickets'**
  String get getTickets;

  /// No description provided for @logInToRsvp.
  ///
  /// In en, this message translates to:
  /// **'Log in to RSVP'**
  String get logInToRsvp;

  /// No description provided for @rsvpToThisEvent.
  ///
  /// In en, this message translates to:
  /// **'RSVP to this Event'**
  String get rsvpToThisEvent;

  /// No description provided for @youAreAttending.
  ///
  /// In en, this message translates to:
  /// **'You\'re attending!'**
  String get youAreAttending;

  /// No description provided for @privateRsvp.
  ///
  /// In en, this message translates to:
  /// **'Private RSVP'**
  String get privateRsvp;

  /// No description provided for @publicRsvp.
  ///
  /// In en, this message translates to:
  /// **'Public RSVP'**
  String get publicRsvp;

  /// No description provided for @cancelRsvp.
  ///
  /// In en, this message translates to:
  /// **'Cancel RSVP'**
  String get cancelRsvp;

  /// No description provided for @rsvpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Let others know you\'re going, or keep it private.'**
  String get rsvpSubtitle;

  /// No description provided for @keepPrivate.
  ///
  /// In en, this message translates to:
  /// **'Keep my RSVP private'**
  String get keepPrivate;

  /// No description provided for @onlyCountVisible.
  ///
  /// In en, this message translates to:
  /// **'Only the count will be visible — not your name.'**
  String get onlyCountVisible;

  /// No description provided for @nameWillAppear.
  ///
  /// In en, this message translates to:
  /// **'Your name will appear in the attendees list.'**
  String get nameWillAppear;

  /// No description provided for @confirmRsvp.
  ///
  /// In en, this message translates to:
  /// **'Confirm RSVP'**
  String get confirmRsvp;

  /// No description provided for @claimPromo.
  ///
  /// In en, this message translates to:
  /// **'Promoter? Verify this listing — first claim is free.'**
  String get claimPromo;

  /// No description provided for @calendarError.
  ///
  /// In en, this message translates to:
  /// **'Could not open calendar. Please add the event manually.'**
  String get calendarError;

  /// No description provided for @googleCalendarError.
  ///
  /// In en, this message translates to:
  /// **'Could not open Google Calendar.'**
  String get googleCalendarError;

  /// No description provided for @addToGoogleCalendar.
  ///
  /// In en, this message translates to:
  /// **'Add to Google Calendar'**
  String get addToGoogleCalendar;

  /// No description provided for @addToAppleCalendar.
  ///
  /// In en, this message translates to:
  /// **'Add to Apple Calendar'**
  String get addToAppleCalendar;

  /// No description provided for @sponsored.
  ///
  /// In en, this message translates to:
  /// **'Sponsored'**
  String get sponsored;

  /// No description provided for @goingOutThisWeek.
  ///
  /// In en, this message translates to:
  /// **'Going out this week?'**
  String get goingOutThisWeek;

  /// No description provided for @pageAdBody.
  ///
  /// In en, this message translates to:
  /// **'SpotVibe shows live music, food, and nightlife near you — no hunting around town.'**
  String get pageAdBody;

  /// No description provided for @browseEvents.
  ///
  /// In en, this message translates to:
  /// **'Browse events'**
  String get browseEvents;

  /// No description provided for @comments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get comments;

  /// No description provided for @noCommentsYet.
  ///
  /// In en, this message translates to:
  /// **'No comments yet. Be the first!'**
  String get noCommentsYet;

  /// No description provided for @logInToComment.
  ///
  /// In en, this message translates to:
  /// **'Log in to leave a comment'**
  String get logInToComment;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String minutesAgo(int minutes);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String hoursAgo(int hours);

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// No description provided for @detectedLabel.
  ///
  /// In en, this message translates to:
  /// **'{category} Detected'**
  String detectedLabel(String category);

  /// No description provided for @warningLabel.
  ///
  /// In en, this message translates to:
  /// **'{category} Warning'**
  String warningLabel(String category);

  /// No description provided for @reviewComment.
  ///
  /// In en, this message translates to:
  /// **'Please review your comment.'**
  String get reviewComment;

  /// No description provided for @addCommentHint.
  ///
  /// In en, this message translates to:
  /// **'Add a comment…'**
  String get addCommentHint;

  /// No description provided for @whosGoing.
  ///
  /// In en, this message translates to:
  /// **'Who\'s going'**
  String get whosGoing;

  /// No description provided for @noRsvpsYet.
  ///
  /// In en, this message translates to:
  /// **'No one has RSVP\'d yet'**
  String get noRsvpsYet;

  /// No description provided for @beFirstToGo.
  ///
  /// In en, this message translates to:
  /// **'Be the first to say you\'re going.'**
  String get beFirstToGo;

  /// No description provided for @attendeesPrivate.
  ///
  /// In en, this message translates to:
  /// **'Attendees are keeping their RSVPs private.'**
  String get attendeesPrivate;

  /// No description provided for @peopleGoing.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 person is going} other{{count} people are going}}'**
  String peopleGoing(int count);

  /// No description provided for @bePartOfExperience.
  ///
  /// In en, this message translates to:
  /// **'Be part of the experience'**
  String get bePartOfExperience;

  /// No description provided for @privateCount.
  ///
  /// In en, this message translates to:
  /// **'+{count} private'**
  String privateCount(int count);

  /// No description provided for @mapsError.
  ///
  /// In en, this message translates to:
  /// **'Could not open maps for this venue.'**
  String get mapsError;

  /// No description provided for @reportEvent.
  ///
  /// In en, this message translates to:
  /// **'Report Event'**
  String get reportEvent;

  /// No description provided for @whatsWrong.
  ///
  /// In en, this message translates to:
  /// **'What\'s wrong with this event?'**
  String get whatsWrong;

  /// No description provided for @reportSubmittedThanks.
  ///
  /// In en, this message translates to:
  /// **'Report submitted. Thank you!'**
  String get reportSubmittedThanks;

  /// No description provided for @calendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar;

  /// No description provided for @directions.
  ///
  /// In en, this message translates to:
  /// **'Directions'**
  String get directions;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @story.
  ///
  /// In en, this message translates to:
  /// **'Story'**
  String get story;

  /// No description provided for @reportThisEvent.
  ///
  /// In en, this message translates to:
  /// **'Report this event'**
  String get reportThisEvent;

  /// No description provided for @practicalInfo.
  ///
  /// In en, this message translates to:
  /// **'Practical Info'**
  String get practicalInfo;

  /// No description provided for @weather.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get weather;

  /// No description provided for @weatherValue.
  ///
  /// In en, this message translates to:
  /// **'Check forecast closer to the date'**
  String get weatherValue;

  /// No description provided for @parking.
  ///
  /// In en, this message translates to:
  /// **'Parking'**
  String get parking;

  /// No description provided for @parkingValue.
  ///
  /// In en, this message translates to:
  /// **'Street parking & nearby lots available'**
  String get parkingValue;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @age.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get age;

  /// No description provided for @accessible.
  ///
  /// In en, this message translates to:
  /// **'Accessible'**
  String get accessible;

  /// No description provided for @accessibleValue.
  ///
  /// In en, this message translates to:
  /// **'Wheelchair accessible venue'**
  String get accessibleValue;

  /// No description provided for @dur2to3.
  ///
  /// In en, this message translates to:
  /// **'2–3 hours'**
  String get dur2to3;

  /// No description provided for @dur2to4.
  ///
  /// In en, this message translates to:
  /// **'2–4 hours'**
  String get dur2to4;

  /// No description provided for @dur1to2.
  ///
  /// In en, this message translates to:
  /// **'1–2 hours'**
  String get dur1to2;

  /// No description provided for @dur1to3.
  ///
  /// In en, this message translates to:
  /// **'1–3 hours'**
  String get dur1to3;

  /// No description provided for @dur15to25.
  ///
  /// In en, this message translates to:
  /// **'1.5–2.5 hours'**
  String get dur15to25;

  /// No description provided for @dur3to5.
  ///
  /// In en, this message translates to:
  /// **'3–5 hours'**
  String get dur3to5;

  /// No description provided for @age21plus.
  ///
  /// In en, this message translates to:
  /// **'21+ only'**
  String get age21plus;

  /// No description provided for @age18plus.
  ///
  /// In en, this message translates to:
  /// **'18+'**
  String get age18plus;

  /// No description provided for @moreLikeThis.
  ///
  /// In en, this message translates to:
  /// **'More like this'**
  String get moreLikeThis;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @whyAmISeeing.
  ///
  /// In en, this message translates to:
  /// **'Why am I seeing this?'**
  String get whyAmISeeing;

  /// No description provided for @personalizationBody.
  ///
  /// In en, this message translates to:
  /// **'SpotVibe learns from how you interact with events — what you view, save, and RSVP to. Over time, the feed re-orders to show more of what you enjoy.'**
  String get personalizationBody;

  /// No description provided for @topInterests.
  ///
  /// In en, this message translates to:
  /// **'Your top interests right now:'**
  String get topInterests;

  /// No description provided for @resetMyPreferences.
  ///
  /// In en, this message translates to:
  /// **'Reset my preferences'**
  String get resetMyPreferences;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// No description provided for @personalizingFeed.
  ///
  /// In en, this message translates to:
  /// **'Personalizing your feed…'**
  String get personalizingFeed;

  /// No description provided for @showingMore.
  ///
  /// In en, this message translates to:
  /// **'Showing more '**
  String get showingMore;

  /// No description provided for @forYou.
  ///
  /// In en, this message translates to:
  /// **' for you'**
  String get forYou;

  /// No description provided for @showingAll.
  ///
  /// In en, this message translates to:
  /// **'Showing all {total} events'**
  String showingAll(int total);

  /// No description provided for @showingRange.
  ///
  /// In en, this message translates to:
  /// **'Showing {start}–{end} of {total} events'**
  String showingRange(int start, int end, int total);

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @pageXOfY.
  ///
  /// In en, this message translates to:
  /// **'Page {page} of {total}'**
  String pageXOfY(int page, int total);

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @allDates.
  ///
  /// In en, this message translates to:
  /// **'All dates'**
  String get allDates;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// No description provided for @thisWeekend.
  ///
  /// In en, this message translates to:
  /// **'This weekend'**
  String get thisWeekend;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get thisWeek;

  /// No description provided for @customRange.
  ///
  /// In en, this message translates to:
  /// **'Custom range'**
  String get customRange;

  /// No description provided for @anyPrice.
  ///
  /// In en, this message translates to:
  /// **'Any price'**
  String get anyPrice;

  /// No description provided for @free.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get free;

  /// No description provided for @under20.
  ///
  /// In en, this message translates to:
  /// **'Under \$20'**
  String get under20;

  /// No description provided for @under50.
  ///
  /// In en, this message translates to:
  /// **'Under \$50'**
  String get under50;

  /// No description provided for @anyTime.
  ///
  /// In en, this message translates to:
  /// **'Any time'**
  String get anyTime;

  /// No description provided for @morning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get morning;

  /// No description provided for @afternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon'**
  String get afternoon;

  /// No description provided for @evening.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get evening;

  /// No description provided for @night.
  ///
  /// In en, this message translates to:
  /// **'Night'**
  String get night;

  /// No description provided for @anyDate.
  ///
  /// In en, this message translates to:
  /// **'Any date'**
  String get anyDate;

  /// No description provided for @anyDistance.
  ///
  /// In en, this message translates to:
  /// **'Any distance'**
  String get anyDistance;

  /// No description provided for @filterEvents.
  ///
  /// In en, this message translates to:
  /// **'Filter Events'**
  String get filterEvents;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get clearAll;

  /// No description provided for @from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get from;

  /// No description provided for @to.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get to;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @timeOfDay.
  ///
  /// In en, this message translates to:
  /// **'Time of Day'**
  String get timeOfDay;

  /// No description provided for @distance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distance;

  /// No description provided for @any.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get any;

  /// No description provided for @locationHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Brooklyn, Manhattan...'**
  String get locationHint;

  /// No description provided for @eventSources.
  ///
  /// In en, this message translates to:
  /// **'Event Sources'**
  String get eventSources;

  /// No description provided for @showResults.
  ///
  /// In en, this message translates to:
  /// **'Show Results'**
  String get showResults;

  /// No description provided for @catAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get catAll;

  /// No description provided for @catMusic.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get catMusic;

  /// No description provided for @catFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get catFood;

  /// No description provided for @catFoodDrink.
  ///
  /// In en, this message translates to:
  /// **'Food & Drink'**
  String get catFoodDrink;

  /// No description provided for @catArts.
  ///
  /// In en, this message translates to:
  /// **'Arts'**
  String get catArts;

  /// No description provided for @catSports.
  ///
  /// In en, this message translates to:
  /// **'Sports'**
  String get catSports;

  /// No description provided for @catTech.
  ///
  /// In en, this message translates to:
  /// **'Tech'**
  String get catTech;

  /// No description provided for @catCommunity.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get catCommunity;

  /// No description provided for @catFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get catFamily;

  /// No description provided for @catWellness.
  ///
  /// In en, this message translates to:
  /// **'Wellness'**
  String get catWellness;

  /// No description provided for @catSocial.
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get catSocial;

  /// No description provided for @catMarkets.
  ///
  /// In en, this message translates to:
  /// **'Markets'**
  String get catMarkets;

  /// No description provided for @catDance.
  ///
  /// In en, this message translates to:
  /// **'Dance'**
  String get catDance;

  /// No description provided for @catFunGames.
  ///
  /// In en, this message translates to:
  /// **'Fun & Games'**
  String get catFunGames;

  /// No description provided for @catHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get catHealth;

  /// No description provided for @catOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get catOther;

  /// No description provided for @catNightlife.
  ///
  /// In en, this message translates to:
  /// **'Nightlife'**
  String get catNightlife;

  /// No description provided for @catComedy.
  ///
  /// In en, this message translates to:
  /// **'Comedy'**
  String get catComedy;

  /// No description provided for @catFitness.
  ///
  /// In en, this message translates to:
  /// **'Fitness'**
  String get catFitness;

  /// No description provided for @catOutdoor.
  ///
  /// In en, this message translates to:
  /// **'Outdoor'**
  String get catOutdoor;

  /// No description provided for @catFilm.
  ///
  /// In en, this message translates to:
  /// **'Film'**
  String get catFilm;

  /// No description provided for @activeLabel.
  ///
  /// In en, this message translates to:
  /// **'Active — {price}'**
  String activeLabel(String price);

  /// No description provided for @trialActiveLabel.
  ///
  /// In en, this message translates to:
  /// **'Trial active — then {price}'**
  String trialActiveLabel(String price);

  /// No description provided for @and.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get and;

  /// No description provided for @tourNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get tourNext;

  /// No description provided for @tourDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get tourDone;

  /// No description provided for @tourSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get tourSkip;

  /// No description provided for @takeTheTour.
  ///
  /// In en, this message translates to:
  /// **'Take the tour'**
  String get takeTheTour;

  /// No description provided for @tourRestarted.
  ///
  /// In en, this message translates to:
  /// **'Tour restarted. It will play again on the next screens you open.'**
  String get tourRestarted;

  /// No description provided for @tourHome1Title.
  ///
  /// In en, this message translates to:
  /// **'Welcome to SpotVibe'**
  String get tourHome1Title;

  /// No description provided for @tourHome1Body.
  ///
  /// In en, this message translates to:
  /// **'Find real events near you — concerts, food, nightlife and more.'**
  String get tourHome1Body;

  /// No description provided for @tourHome2Title.
  ///
  /// In en, this message translates to:
  /// **'Search events'**
  String get tourHome2Title;

  /// No description provided for @tourHome2Body.
  ///
  /// In en, this message translates to:
  /// **'Search by event, artist, or venue — or by zip code, city, or state.'**
  String get tourHome2Body;

  /// No description provided for @tourHome3Title.
  ///
  /// In en, this message translates to:
  /// **'Filter results'**
  String get tourHome3Title;

  /// No description provided for @tourHome3Body.
  ///
  /// In en, this message translates to:
  /// **'Narrow things down by date, price, time of day, distance, and more.'**
  String get tourHome3Body;

  /// No description provided for @tourHome4Title.
  ///
  /// In en, this message translates to:
  /// **'Browse categories'**
  String get tourHome4Title;

  /// No description provided for @tourHome4Body.
  ///
  /// In en, this message translates to:
  /// **'Tap a category to focus your feed on what you love.'**
  String get tourHome4Body;

  /// No description provided for @tourHome5Title.
  ///
  /// In en, this message translates to:
  /// **'Your event feed'**
  String get tourHome5Title;

  /// No description provided for @tourHome5Body.
  ///
  /// In en, this message translates to:
  /// **'Scroll to discover events. Tap any card for details, tickets, and RSVP.'**
  String get tourHome5Body;

  /// No description provided for @tourEvent1Title.
  ///
  /// In en, this message translates to:
  /// **'RSVP'**
  String get tourEvent1Title;

  /// No description provided for @tourEvent1Body.
  ///
  /// In en, this message translates to:
  /// **'Tap here to say you\'re going — public or private, it\'s your call.'**
  String get tourEvent1Body;

  /// No description provided for @tourEvent2Title.
  ///
  /// In en, this message translates to:
  /// **'Save & track'**
  String get tourEvent2Title;

  /// No description provided for @tourEvent2Body.
  ///
  /// In en, this message translates to:
  /// **'Bookmark events or mark the ones you\'re interested in.'**
  String get tourEvent2Body;

  /// No description provided for @tourEvent3Title.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get tourEvent3Title;

  /// No description provided for @tourEvent3Body.
  ///
  /// In en, this message translates to:
  /// **'Send the event to friends as a link or a share card.'**
  String get tourEvent3Body;

  /// No description provided for @tourProfile1Title.
  ///
  /// In en, this message translates to:
  /// **'SpotVibe Premium'**
  String get tourProfile1Title;

  /// No description provided for @tourProfile1Body.
  ///
  /// In en, this message translates to:
  /// **'Unlock recurring events, analytics, and custom branding.'**
  String get tourProfile1Body;

  /// No description provided for @tourProfile2Title.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get tourProfile2Title;

  /// No description provided for @tourProfile2Body.
  ///
  /// In en, this message translates to:
  /// **'Switch between English and Spanish anytime.'**
  String get tourProfile2Body;

  /// No description provided for @tourProfile3Title.
  ///
  /// In en, this message translates to:
  /// **'Your events'**
  String get tourProfile3Title;

  /// No description provided for @tourProfile3Body.
  ///
  /// In en, this message translates to:
  /// **'Manage the events you\'ve created and saved.'**
  String get tourProfile3Body;

  /// No description provided for @adminDashboard.
  ///
  /// In en, this message translates to:
  /// **'Admin Dashboard'**
  String get adminDashboard;

  /// No description provided for @adminReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get adminReports;

  /// No description provided for @adminEvents.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get adminEvents;

  /// No description provided for @adminNoReports.
  ///
  /// In en, this message translates to:
  /// **'No open reports — you\'re all caught up.'**
  String get adminNoReports;

  /// No description provided for @adminResolve.
  ///
  /// In en, this message translates to:
  /// **'Mark resolved'**
  String get adminResolve;

  /// No description provided for @adminRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get adminRemove;

  /// No description provided for @adminRemoveEvent.
  ///
  /// In en, this message translates to:
  /// **'Remove event'**
  String get adminRemoveEvent;

  /// No description provided for @adminRemoveEventTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove this event?'**
  String get adminRemoveEventTitle;

  /// No description provided for @adminRemoveEventBody.
  ///
  /// In en, this message translates to:
  /// **'This permanently removes the event, its comments, and its RSVPs from the public feed.'**
  String get adminRemoveEventBody;

  /// No description provided for @adminEventRemoved.
  ///
  /// In en, this message translates to:
  /// **'Event removed.'**
  String get adminEventRemoved;

  /// No description provided for @adminReportResolved.
  ///
  /// In en, this message translates to:
  /// **'Report resolved.'**
  String get adminReportResolved;

  /// No description provided for @adminSearchEvents.
  ///
  /// In en, this message translates to:
  /// **'Search events…'**
  String get adminSearchEvents;

  /// No description provided for @adminNoEvents.
  ///
  /// In en, this message translates to:
  /// **'No events found.'**
  String get adminNoEvents;

  /// No description provided for @adminReason.
  ///
  /// In en, this message translates to:
  /// **'Reason: {reason}'**
  String adminReason(String reason);

  /// No description provided for @adminReportedUser.
  ///
  /// In en, this message translates to:
  /// **'Reported user: {id}'**
  String adminReportedUser(String id);

  /// No description provided for @adminReportedBy.
  ///
  /// In en, this message translates to:
  /// **'Reported by: {id}'**
  String adminReportedBy(String id);

  /// No description provided for @adminAccess.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get adminAccess;

  /// No description provided for @adminDeleteComment.
  ///
  /// In en, this message translates to:
  /// **'Delete comment'**
  String get adminDeleteComment;

  /// No description provided for @adminCommentRemoved.
  ///
  /// In en, this message translates to:
  /// **'Comment removed.'**
  String get adminCommentRemoved;

  /// No description provided for @adminPostUnlimited.
  ///
  /// In en, this message translates to:
  /// **'Official account — unlimited one-time events'**
  String get adminPostUnlimited;

  /// No description provided for @adminSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by title, venue, or organizer…'**
  String get adminSearchHint;

  /// No description provided for @adminDeleteCommentBody.
  ///
  /// In en, this message translates to:
  /// **'This permanently removes the comment from the event page.'**
  String get adminDeleteCommentBody;

  /// No description provided for @adminClaims.
  ///
  /// In en, this message translates to:
  /// **'Claims'**
  String get adminClaims;

  /// No description provided for @adminNoClaims.
  ///
  /// In en, this message translates to:
  /// **'No venue claims yet.'**
  String get adminNoClaims;

  /// No description provided for @adminApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get adminApprove;

  /// No description provided for @adminReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get adminReject;

  /// No description provided for @adminClaimApproved.
  ///
  /// In en, this message translates to:
  /// **'Claim approved — the venue can now edit this listing.'**
  String get adminClaimApproved;

  /// No description provided for @adminClaimRejected.
  ///
  /// In en, this message translates to:
  /// **'Claim rejected.'**
  String get adminClaimRejected;

  /// No description provided for @adminPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get adminPending;

  /// No description provided for @adminApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get adminApproved;

  /// No description provided for @adminRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get adminRejected;

  /// No description provided for @adminBanUser.
  ///
  /// In en, this message translates to:
  /// **'Ban user'**
  String get adminBanUser;

  /// No description provided for @adminUnban.
  ///
  /// In en, this message translates to:
  /// **'Unban'**
  String get adminUnban;

  /// No description provided for @adminBannedUsers.
  ///
  /// In en, this message translates to:
  /// **'Banned users'**
  String get adminBannedUsers;

  /// No description provided for @adminNoBanned.
  ///
  /// In en, this message translates to:
  /// **'No banned users.'**
  String get adminNoBanned;

  /// No description provided for @adminUserBanned.
  ///
  /// In en, this message translates to:
  /// **'User banned — their content is now hidden.'**
  String get adminUserBanned;

  /// No description provided for @adminUserUnbanned.
  ///
  /// In en, this message translates to:
  /// **'User unbanned.'**
  String get adminUserUnbanned;

  /// No description provided for @adminBanConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Ban this user?'**
  String get adminBanConfirmTitle;

  /// No description provided for @adminBanConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This hides all of their events, comments, and RSVPs from the app. You can undo this anytime.'**
  String get adminBanConfirmBody;

  /// No description provided for @claimRoleOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner / operator'**
  String get claimRoleOwner;

  /// No description provided for @claimRolePromoter.
  ///
  /// In en, this message translates to:
  /// **'Authorized promoter'**
  String get claimRolePromoter;

  /// No description provided for @claimRoleBookingAgent.
  ///
  /// In en, this message translates to:
  /// **'Booking agent'**
  String get claimRoleBookingAgent;

  /// No description provided for @claimRoleMarketing.
  ///
  /// In en, this message translates to:
  /// **'Marketing / PR'**
  String get claimRoleMarketing;

  /// No description provided for @claimRoleOther.
  ///
  /// In en, this message translates to:
  /// **'Other authorized rep'**
  String get claimRoleOther;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
