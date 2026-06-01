import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('de'),
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In de, this message translates to:
  /// **'Einundzwanzig Meetup'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In de, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navWallet.
  ///
  /// In de, this message translates to:
  /// **'Wallet'**
  String get navWallet;

  /// No description provided for @navEvents.
  ///
  /// In de, this message translates to:
  /// **'Events'**
  String get navEvents;

  /// No description provided for @navProfile.
  ///
  /// In de, this message translates to:
  /// **'Profil'**
  String get navProfile;

  /// No description provided for @actionSave.
  ///
  /// In de, this message translates to:
  /// **'Speichern'**
  String get actionSave;

  /// No description provided for @actionCancel.
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get actionCancel;

  /// No description provided for @actionConfirm.
  ///
  /// In de, this message translates to:
  /// **'Bestätigen'**
  String get actionConfirm;

  /// No description provided for @actionDelete.
  ///
  /// In de, this message translates to:
  /// **'Löschen'**
  String get actionDelete;

  /// No description provided for @actionContinue.
  ///
  /// In de, this message translates to:
  /// **'Weiter'**
  String get actionContinue;

  /// No description provided for @actionBack.
  ///
  /// In de, this message translates to:
  /// **'Zurück'**
  String get actionBack;

  /// No description provided for @actionClose.
  ///
  /// In de, this message translates to:
  /// **'Schließen'**
  String get actionClose;

  /// No description provided for @actionRetry.
  ///
  /// In de, this message translates to:
  /// **'Erneut versuchen'**
  String get actionRetry;

  /// No description provided for @actionOk.
  ///
  /// In de, this message translates to:
  /// **'OK'**
  String get actionOk;

  /// No description provided for @actionUnderstood.
  ///
  /// In de, this message translates to:
  /// **'Verstanden'**
  String get actionUnderstood;

  /// No description provided for @settingsTitle.
  ///
  /// In de, this message translates to:
  /// **'Einstellungen'**
  String get settingsTitle;

  /// No description provided for @settingsLanguage.
  ///
  /// In de, this message translates to:
  /// **'Sprache'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSystem.
  ///
  /// In de, this message translates to:
  /// **'System'**
  String get settingsLanguageSystem;

  /// No description provided for @trustScore.
  ///
  /// In de, this message translates to:
  /// **'Trust Score'**
  String get trustScore;

  /// No description provided for @reputation.
  ///
  /// In de, this message translates to:
  /// **'Reputation'**
  String get reputation;

  /// No description provided for @reputationShareQr.
  ///
  /// In de, this message translates to:
  /// **'QR teilen'**
  String get reputationShareQr;

  /// No description provided for @community.
  ///
  /// In de, this message translates to:
  /// **'Community'**
  String get community;

  /// No description provided for @communityPortal.
  ///
  /// In de, this message translates to:
  /// **'Portal'**
  String get communityPortal;

  /// No description provided for @homeMeetup.
  ///
  /// In de, this message translates to:
  /// **'Home Meetup'**
  String get homeMeetup;

  /// No description provided for @shoutout.
  ///
  /// In de, this message translates to:
  /// **'Shoutout'**
  String get shoutout;

  /// No description provided for @joinCommunity.
  ///
  /// In de, this message translates to:
  /// **'Community betreten'**
  String get joinCommunity;

  /// No description provided for @identityVerified.
  ///
  /// In de, this message translates to:
  /// **'Verifiziert'**
  String get identityVerified;

  /// No description provided for @verifiedByAdmin.
  ///
  /// In de, this message translates to:
  /// **'Verifiziert durch Admin'**
  String get verifiedByAdmin;

  /// No description provided for @nostrVerified.
  ///
  /// In de, this message translates to:
  /// **'Nostr verifiziert'**
  String get nostrVerified;

  /// No description provided for @profileNickname.
  ///
  /// In de, this message translates to:
  /// **'Nickname'**
  String get profileNickname;

  /// No description provided for @profileChooseHomeMeetup.
  ///
  /// In de, this message translates to:
  /// **'Wähle dein Home-Meetup'**
  String get profileChooseHomeMeetup;

  /// No description provided for @profileYourIdentity.
  ///
  /// In de, this message translates to:
  /// **'Deine Identität'**
  String get profileYourIdentity;

  /// No description provided for @profileNostrKey.
  ///
  /// In de, this message translates to:
  /// **'Nostr Schlüssel'**
  String get profileNostrKey;

  /// No description provided for @profileKeyActive.
  ///
  /// In de, this message translates to:
  /// **'Schlüssel aktiv'**
  String get profileKeyActive;

  /// No description provided for @requiredField.
  ///
  /// In de, this message translates to:
  /// **'Pflichtfeld — bitte ausfüllen'**
  String get requiredField;

  /// No description provided for @requiredHomeMeetup.
  ///
  /// In de, this message translates to:
  /// **'Pflichtfeld — bitte wähle dein Home-Meetup'**
  String get requiredHomeMeetup;

  /// No description provided for @fillRequired.
  ///
  /// In de, this message translates to:
  /// **'Bitte ausfüllen: {fields}'**
  String fillRequired(String fields);

  /// No description provided for @identityGenerateKey.
  ///
  /// In de, this message translates to:
  /// **'Neuen Schlüssel erstellen'**
  String get identityGenerateKey;

  /// No description provided for @identityConnectAmber.
  ///
  /// In de, this message translates to:
  /// **'Mit Amber verbinden'**
  String get identityConnectAmber;

  /// No description provided for @identityImportNsec.
  ///
  /// In de, this message translates to:
  /// **'Bestehenden nsec importieren'**
  String get identityImportNsec;

  /// No description provided for @amberConnected.
  ///
  /// In de, this message translates to:
  /// **'Mit Amber verbunden! Dein nsec bleibt in Amber.'**
  String get amberConnected;

  /// No description provided for @amberNotFound.
  ///
  /// In de, this message translates to:
  /// **'Amber nicht gefunden'**
  String get amberNotFound;

  /// No description provided for @amberCancelled.
  ///
  /// In de, this message translates to:
  /// **'Verbindung in Amber abgebrochen.'**
  String get amberCancelled;

  /// No description provided for @walletTitle.
  ///
  /// In de, this message translates to:
  /// **'Badge Wallet'**
  String get walletTitle;

  /// No description provided for @badgesCount.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =0{Keine Badges} =1{1 Badge} other{{count} Badges}}'**
  String badgesCount(int count);

  /// No description provided for @eventInDays.
  ///
  /// In de, this message translates to:
  /// **'in {days, plural, =0{heute} =1{1 Tag} other{{days} Tagen}}'**
  String eventInDays(int days);

  /// No description provided for @tileTrustScore.
  ///
  /// In de, this message translates to:
  /// **'Trust Score'**
  String get tileTrustScore;

  /// No description provided for @tileReputation.
  ///
  /// In de, this message translates to:
  /// **'Reputation'**
  String get tileReputation;

  /// No description provided for @tileReputationShare.
  ///
  /// In de, this message translates to:
  /// **'QR teilen'**
  String get tileReputationShare;

  /// No description provided for @tileReputationCheck.
  ///
  /// In de, this message translates to:
  /// **'Prüfen'**
  String get tileReputationCheck;

  /// No description provided for @tileCommunity.
  ///
  /// In de, this message translates to:
  /// **'Community'**
  String get tileCommunity;

  /// No description provided for @tileCommunityPortal.
  ///
  /// In de, this message translates to:
  /// **'Portal'**
  String get tileCommunityPortal;

  /// No description provided for @tileEvents.
  ///
  /// In de, this message translates to:
  /// **'Events'**
  String get tileEvents;

  /// No description provided for @tileEventsCalendar.
  ///
  /// In de, this message translates to:
  /// **'Kalender'**
  String get tileEventsCalendar;

  /// No description provided for @tileShoutout.
  ///
  /// In de, this message translates to:
  /// **'Shoutout'**
  String get tileShoutout;

  /// No description provided for @tileShoutoutSend.
  ///
  /// In de, this message translates to:
  /// **'Senden'**
  String get tileShoutoutSend;

  /// No description provided for @tilePodcast.
  ///
  /// In de, this message translates to:
  /// **'Podcast'**
  String get tilePodcast;

  /// No description provided for @tilePodcastListen.
  ///
  /// In de, this message translates to:
  /// **'Anhören'**
  String get tilePodcastListen;

  /// No description provided for @tileNostr.
  ///
  /// In de, this message translates to:
  /// **'Nostr'**
  String get tileNostr;

  /// No description provided for @tileNostrCommunity.
  ///
  /// In de, this message translates to:
  /// **'Community'**
  String get tileNostrCommunity;

  /// No description provided for @tileOrganizer.
  ///
  /// In de, this message translates to:
  /// **'Organisator'**
  String get tileOrganizer;

  /// No description provided for @tileOrganizerPanel.
  ///
  /// In de, this message translates to:
  /// **'Admin-Panel'**
  String get tileOrganizerPanel;

  /// No description provided for @tileOrganizerNew.
  ///
  /// In de, this message translates to:
  /// **'Neu via Trust Score'**
  String get tileOrganizerNew;

  /// No description provided for @tileWot.
  ///
  /// In de, this message translates to:
  /// **'WoT'**
  String get tileWot;

  /// No description provided for @tileWotSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Web of Trust'**
  String get tileWotSubtitle;

  /// No description provided for @homeMeetupLabel.
  ///
  /// In de, this message translates to:
  /// **'HOME MEETUP'**
  String get homeMeetupLabel;

  /// No description provided for @homeMeetupChoose.
  ///
  /// In de, this message translates to:
  /// **'Wähle deinen Stammtisch'**
  String get homeMeetupChoose;

  /// No description provided for @homeMeetupChooseSub.
  ///
  /// In de, this message translates to:
  /// **'Dein regelmäßiges Meetup auswählen'**
  String get homeMeetupChooseSub;

  /// No description provided for @homeMeetupBadges.
  ///
  /// In de, this message translates to:
  /// **'{count} Badges'**
  String homeMeetupBadges(int count);

  /// No description provided for @homeMeetupToday.
  ///
  /// In de, this message translates to:
  /// **'Heute!'**
  String get homeMeetupToday;

  /// No description provided for @homeMeetupTomorrow.
  ///
  /// In de, this message translates to:
  /// **'Morgen'**
  String get homeMeetupTomorrow;

  /// No description provided for @homeMeetupInDays.
  ///
  /// In de, this message translates to:
  /// **'in {days} Tagen'**
  String homeMeetupInDays(int days);

  /// No description provided for @homeMeetupNoDate.
  ///
  /// In de, this message translates to:
  /// **'Kein Termin geplant'**
  String get homeMeetupNoDate;

  /// No description provided for @homeMeetupNextEvent.
  ///
  /// In de, this message translates to:
  /// **'Nächstes Meetup'**
  String get homeMeetupNextEvent;

  /// No description provided for @homeMeetupNoneSoon.
  ///
  /// In de, this message translates to:
  /// **'Kein Termin in Sicht.\nWird Zeit, das zu ändern!'**
  String get homeMeetupNoneSoon;

  /// No description provided for @homeMeetupSelectFirst.
  ///
  /// In de, this message translates to:
  /// **'Erst Home Meetup\nwählen!'**
  String get homeMeetupSelectFirst;

  /// No description provided for @btnEvents.
  ///
  /// In de, this message translates to:
  /// **'EVENTS'**
  String get btnEvents;

  /// No description provided for @statusLive.
  ///
  /// In de, this message translates to:
  /// **'LIVE'**
  String get statusLive;

  /// No description provided for @statusMeetupActive.
  ///
  /// In de, this message translates to:
  /// **'Meetup aktiv'**
  String get statusMeetupActive;

  /// No description provided for @loading.
  ///
  /// In de, this message translates to:
  /// **'Lade...'**
  String get loading;

  /// No description provided for @organizerPromoted.
  ///
  /// In de, this message translates to:
  /// **'Du bist jetzt ORGANISATOR!'**
  String get organizerPromoted;

  /// No description provided for @resetTitle.
  ///
  /// In de, this message translates to:
  /// **'App zurücksetzen?'**
  String get resetTitle;

  /// No description provided for @resetBody.
  ///
  /// In de, this message translates to:
  /// **'Alle Badges und dein Profil werden gelöscht.'**
  String get resetBody;

  /// No description provided for @resetCancel.
  ///
  /// In de, this message translates to:
  /// **'Abbruch'**
  String get resetCancel;

  /// No description provided for @resetConfirm.
  ///
  /// In de, this message translates to:
  /// **'LÖSCHEN'**
  String get resetConfirm;

  /// No description provided for @settingsSectionBackup.
  ///
  /// In de, this message translates to:
  /// **'DATENSICHERUNG'**
  String get settingsSectionBackup;

  /// No description provided for @settingsSectionLanguage.
  ///
  /// In de, this message translates to:
  /// **'SPRACHE'**
  String get settingsSectionLanguage;

  /// No description provided for @settingsSectionNostr.
  ///
  /// In de, this message translates to:
  /// **'NOSTR-NETZWERK'**
  String get settingsSectionNostr;

  /// No description provided for @settingsSectionControl.
  ///
  /// In de, this message translates to:
  /// **'BEDIENUNG'**
  String get settingsSectionControl;

  /// No description provided for @settingsSectionAccount.
  ///
  /// In de, this message translates to:
  /// **'ACCOUNT'**
  String get settingsSectionAccount;

  /// No description provided for @settingsBackup.
  ///
  /// In de, this message translates to:
  /// **'Backup erstellen'**
  String get settingsBackup;

  /// No description provided for @settingsBackupSub.
  ///
  /// In de, this message translates to:
  /// **'Sichere deinen Account'**
  String get settingsBackupSub;

  /// No description provided for @settingsLanguageTitle.
  ///
  /// In de, this message translates to:
  /// **'Sprache'**
  String get settingsLanguageTitle;

  /// No description provided for @settingsLanguageChoose.
  ///
  /// In de, this message translates to:
  /// **'Sprache wählen'**
  String get settingsLanguageChoose;

  /// No description provided for @settingsRelays.
  ///
  /// In de, this message translates to:
  /// **'Nostr-Relays'**
  String get settingsRelays;

  /// No description provided for @settingsRelaysSub.
  ///
  /// In de, this message translates to:
  /// **'Relays konfigurieren'**
  String get settingsRelaysSub;

  /// No description provided for @settingsHaptic.
  ///
  /// In de, this message translates to:
  /// **'Vibrationsfeedback'**
  String get settingsHaptic;

  /// No description provided for @settingsHapticOn.
  ///
  /// In de, this message translates to:
  /// **'Aktiv'**
  String get settingsHapticOn;

  /// No description provided for @settingsHapticOff.
  ///
  /// In de, this message translates to:
  /// **'Deaktiviert'**
  String get settingsHapticOff;

  /// No description provided for @settingsReset.
  ///
  /// In de, this message translates to:
  /// **'App zurücksetzen'**
  String get settingsReset;

  /// No description provided for @settingsResetSub.
  ///
  /// In de, this message translates to:
  /// **'Löscht Profil und Badges'**
  String get settingsResetSub;
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
      <String>['de', 'en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
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
