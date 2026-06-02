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
  /// **'NOSTR SCHLÜSSEL'**
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

  /// No description provided for @introTagline.
  ///
  /// In de, this message translates to:
  /// **'DEINE BITCOIN COMMUNITY'**
  String get introTagline;

  /// No description provided for @introJoin.
  ///
  /// In de, this message translates to:
  /// **'COMMUNITY BETRETEN'**
  String get introJoin;

  /// No description provided for @introLoadBackup.
  ///
  /// In de, this message translates to:
  /// **'BACKUP LADEN'**
  String get introLoadBackup;

  /// No description provided for @introSetIdentity.
  ///
  /// In de, this message translates to:
  /// **'Bitte lege zuerst deine Identität fest.'**
  String get introSetIdentity;

  /// No description provided for @navWalletTab.
  ///
  /// In de, this message translates to:
  /// **'Wallet'**
  String get navWalletTab;

  /// No description provided for @navProfileTab.
  ///
  /// In de, this message translates to:
  /// **'Profil'**
  String get navProfileTab;

  /// No description provided for @scanBadge.
  ///
  /// In de, this message translates to:
  /// **'Badge scannen'**
  String get scanBadge;

  /// No description provided for @scanBadgeSub.
  ///
  /// In de, this message translates to:
  /// **'QR-Code oder NFC-Tag vom Meetup'**
  String get scanBadgeSub;

  /// No description provided for @scanReputation.
  ///
  /// In de, this message translates to:
  /// **'Reputation prüfen'**
  String get scanReputation;

  /// No description provided for @scanReputationSub.
  ///
  /// In de, this message translates to:
  /// **'Trust Score einer anderen Person verifizieren'**
  String get scanReputationSub;

  /// No description provided for @calendarTitle.
  ///
  /// In de, this message translates to:
  /// **'MEETUP TERMINE'**
  String get calendarTitle;

  /// No description provided for @calendarSearch.
  ///
  /// In de, this message translates to:
  /// **'Suche (z.B. München, Bitcoin...)'**
  String get calendarSearch;

  /// No description provided for @calendarNoEvents.
  ///
  /// In de, this message translates to:
  /// **'Keine Termine gefunden.'**
  String get calendarNoEvents;

  /// No description provided for @sectionDescription.
  ///
  /// In de, this message translates to:
  /// **'BESCHREIBUNG'**
  String get sectionDescription;

  /// No description provided for @sectionLocation.
  ///
  /// In de, this message translates to:
  /// **'STANDORT'**
  String get sectionLocation;

  /// No description provided for @sectionDates.
  ///
  /// In de, this message translates to:
  /// **'TERMINE'**
  String get sectionDates;

  /// No description provided for @sectionLinks.
  ///
  /// In de, this message translates to:
  /// **'LINKS'**
  String get sectionLinks;

  /// No description provided for @meetupRoute.
  ///
  /// In de, this message translates to:
  /// **'Route'**
  String get meetupRoute;

  /// No description provided for @meetupNoDatesCal.
  ///
  /// In de, this message translates to:
  /// **'Aktuell keine Termine im Kalender.'**
  String get meetupNoDatesCal;

  /// No description provided for @errorOpenLink.
  ///
  /// In de, this message translates to:
  /// **'Konnte Link nicht öffnen'**
  String get errorOpenLink;

  /// No description provided for @walletNoBadges.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Badges gesammelt'**
  String get walletNoBadges;

  /// No description provided for @walletNoBadgesSub.
  ///
  /// In de, this message translates to:
  /// **'Besuche Meetups und scanne NFC-Tags um Badges zu sammeln!'**
  String get walletNoBadgesSub;

  /// No description provided for @walletShareReputation.
  ///
  /// In de, this message translates to:
  /// **'REPUTATION TEILEN'**
  String get walletShareReputation;

  /// No description provided for @walletShowQr.
  ///
  /// In de, this message translates to:
  /// **'QR-Code anzeigen'**
  String get walletShowQr;

  /// No description provided for @walletShowQrSub.
  ///
  /// In de, this message translates to:
  /// **'Zum Scannen vor Ort'**
  String get walletShowQrSub;

  /// No description provided for @walletExportJson.
  ///
  /// In de, this message translates to:
  /// **'Als JSON exportieren'**
  String get walletExportJson;

  /// No description provided for @walletExportJsonSub.
  ///
  /// In de, this message translates to:
  /// **'Signierter Export mit Schnorr-Beweis'**
  String get walletExportJsonSub;

  /// No description provided for @walletShareText.
  ///
  /// In de, this message translates to:
  /// **'Als Text teilen'**
  String get walletShareText;

  /// No description provided for @walletShareTextSub.
  ///
  /// In de, this message translates to:
  /// **'Lesbar für alle (wird im Web kopiert)'**
  String get walletShareTextSub;

  /// No description provided for @walletShareTitle.
  ///
  /// In de, this message translates to:
  /// **'Reputation teilen'**
  String get walletShareTitle;

  /// No description provided for @walletJsonCopied.
  ///
  /// In de, this message translates to:
  /// **'JSON-Daten in Zwischenablage kopiert'**
  String get walletJsonCopied;

  /// No description provided for @walletReputationCopied.
  ///
  /// In de, this message translates to:
  /// **'Reputation in Zwischenablage kopiert'**
  String get walletReputationCopied;

  /// No description provided for @cancel.
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get cancel;

  /// No description provided for @badgeDetailsTitle.
  ///
  /// In de, this message translates to:
  /// **'Badge-Details'**
  String get badgeDetailsTitle;

  /// No description provided for @badgeShare.
  ///
  /// In de, this message translates to:
  /// **'Badge teilen'**
  String get badgeShare;

  /// No description provided for @badgeShareCaps.
  ///
  /// In de, this message translates to:
  /// **'BADGE TEILEN'**
  String get badgeShareCaps;

  /// No description provided for @badgeClose.
  ///
  /// In de, this message translates to:
  /// **'SCHLIESSEN'**
  String get badgeClose;

  /// No description provided for @badgeProofTitle.
  ///
  /// In de, this message translates to:
  /// **'Kryptographischer Beweis'**
  String get badgeProofTitle;

  /// No description provided for @badgeProofOfAttendance.
  ///
  /// In de, this message translates to:
  /// **'PROOF OF ATTENDANCE'**
  String get badgeProofOfAttendance;

  /// No description provided for @badgeProofDesc.
  ///
  /// In de, this message translates to:
  /// **'Dieses Badge bestätigt kryptografisch, dass du physisch vor Ort warst.'**
  String get badgeProofDesc;

  /// No description provided for @badgeMeetup.
  ///
  /// In de, this message translates to:
  /// **'Meetup'**
  String get badgeMeetup;

  /// No description provided for @badgeMeetupDate.
  ///
  /// In de, this message translates to:
  /// **'Meetup-Datum'**
  String get badgeMeetupDate;

  /// No description provided for @badgeMeetupId.
  ///
  /// In de, this message translates to:
  /// **'Meetup-ID'**
  String get badgeMeetupId;

  /// No description provided for @badgeOrganizerNpub.
  ///
  /// In de, this message translates to:
  /// **'Organisator (npub)'**
  String get badgeOrganizerNpub;

  /// No description provided for @badgeSignatureType.
  ///
  /// In de, this message translates to:
  /// **'Signaturtyp'**
  String get badgeSignatureType;

  /// No description provided for @badgeTransmission.
  ///
  /// In de, this message translates to:
  /// **'Übertragungsweg'**
  String get badgeTransmission;

  /// No description provided for @badgeTimestamp.
  ///
  /// In de, this message translates to:
  /// **'Zeitstempel'**
  String get badgeTimestamp;

  /// No description provided for @badgeScanTime.
  ///
  /// In de, this message translates to:
  /// **'Scan-Zeitpunkt'**
  String get badgeScanTime;

  /// No description provided for @badgeVerificationHash.
  ///
  /// In de, this message translates to:
  /// **'VERIFIKATIONS-HASH'**
  String get badgeVerificationHash;

  /// No description provided for @badgeClaimBinding.
  ///
  /// In de, this message translates to:
  /// **'Claim-Binding'**
  String get badgeClaimBinding;

  /// No description provided for @badgeBound.
  ///
  /// In de, this message translates to:
  /// **'Gebunden ✓'**
  String get badgeBound;

  /// No description provided for @badgeNotBound.
  ///
  /// In de, this message translates to:
  /// **'Nicht gebunden'**
  String get badgeNotBound;

  /// No description provided for @badgeClaimedLater.
  ///
  /// In de, this message translates to:
  /// **'Nachträglich geclaimed'**
  String get badgeClaimedLater;

  /// No description provided for @badgeNote.
  ///
  /// In de, this message translates to:
  /// **'Hinweis'**
  String get badgeNote;

  /// No description provided for @badgeNoSignature.
  ///
  /// In de, this message translates to:
  /// **'Keine Signatur'**
  String get badgeNoSignature;

  /// No description provided for @badgeHashCopied.
  ///
  /// In de, this message translates to:
  /// **'Hash kopiert'**
  String get badgeHashCopied;

  /// No description provided for @badgeInfoCopied.
  ///
  /// In de, this message translates to:
  /// **'Badge-Info in Zwischenablage kopiert'**
  String get badgeInfoCopied;

  /// No description provided for @badgeNfcTag.
  ///
  /// In de, this message translates to:
  /// **'NFC-Tag'**
  String get badgeNfcTag;

  /// No description provided for @badgeRollingQr.
  ///
  /// In de, this message translates to:
  /// **'Rolling QR-Code'**
  String get badgeRollingQr;

  /// No description provided for @levelNew.
  ///
  /// In de, this message translates to:
  /// **'NEU'**
  String get levelNew;

  /// No description provided for @levelStarter.
  ///
  /// In de, this message translates to:
  /// **'STARTER'**
  String get levelStarter;

  /// No description provided for @levelActive.
  ///
  /// In de, this message translates to:
  /// **'AKTIV'**
  String get levelActive;

  /// No description provided for @levelEstablished.
  ///
  /// In de, this message translates to:
  /// **'ETABLIERT'**
  String get levelEstablished;

  /// No description provided for @levelVeteran.
  ///
  /// In de, this message translates to:
  /// **'VETERAN'**
  String get levelVeteran;

  /// No description provided for @reputationTitle.
  ///
  /// In de, this message translates to:
  /// **'REPUTATION'**
  String get reputationTitle;

  /// No description provided for @reputationNoBadges.
  ///
  /// In de, this message translates to:
  /// **'NOCH KEINE BADGES'**
  String get reputationNoBadges;

  /// No description provided for @reputationNoProofs.
  ///
  /// In de, this message translates to:
  /// **'Noch keine kryptographischen Beweise'**
  String get reputationNoProofs;

  /// No description provided for @reputationBuildHint1.
  ///
  /// In de, this message translates to:
  /// **'Besuche ein Meetup und scanne einen Badge um '**
  String get reputationBuildHint1;

  /// No description provided for @reputationBuildHint2.
  ///
  /// In de, this message translates to:
  /// **'deine Reputation aufzubauen.'**
  String get reputationBuildHint2;

  /// No description provided for @reputationScanQr.
  ///
  /// In de, this message translates to:
  /// **'QR-CODE SCANNEN'**
  String get reputationScanQr;

  /// No description provided for @reputationShareImage.
  ///
  /// In de, this message translates to:
  /// **'QR ALS BILD TEILEN'**
  String get reputationShareImage;

  /// No description provided for @reputationUpdateRelays.
  ///
  /// In de, this message translates to:
  /// **'AUF RELAYS AKTUALISIEREN'**
  String get reputationUpdateRelays;

  /// No description provided for @reputationPublishing.
  ///
  /// In de, this message translates to:
  /// **'PUBLIZIERE...'**
  String get reputationPublishing;

  /// No description provided for @reputationBadges.
  ///
  /// In de, this message translates to:
  /// **'Badges'**
  String get reputationBadges;

  /// No description provided for @reputationMeetups.
  ///
  /// In de, this message translates to:
  /// **'Meetups'**
  String get reputationMeetups;

  /// No description provided for @reputationSigners.
  ///
  /// In de, this message translates to:
  /// **'Signer'**
  String get reputationSigners;

  /// No description provided for @reputationBound.
  ///
  /// In de, this message translates to:
  /// **'Gebunden'**
  String get reputationBound;

  /// No description provided for @reputationSchnorrSigned.
  ///
  /// In de, this message translates to:
  /// **'Schnorr-signiert'**
  String get reputationSchnorrSigned;

  /// No description provided for @reputationSignedNoId.
  ///
  /// In de, this message translates to:
  /// **'Signiert (ohne Identität)'**
  String get reputationSignedNoId;

  /// No description provided for @reputationNoIdentity.
  ///
  /// In de, this message translates to:
  /// **'Keine Identität verknüpft. Ergänze Telegram oder Nostr in deinem Profil.'**
  String get reputationNoIdentity;

  /// No description provided for @reputationCheck.
  ///
  /// In de, this message translates to:
  /// **'Reputation prüfen'**
  String get reputationCheck;

  /// No description provided for @reputationVerified.
  ///
  /// In de, this message translates to:
  /// **'Meine verifizierte Meetup-Reputation'**
  String get reputationVerified;

  /// No description provided for @reputationCodeFrom.
  ///
  /// In de, this message translates to:
  /// **'Reputationscode von'**
  String get reputationCodeFrom;

  /// No description provided for @portalDiscover.
  ///
  /// In de, this message translates to:
  /// **'ENTDECKEN'**
  String get portalDiscover;

  /// No description provided for @portalQuickAccess.
  ///
  /// In de, this message translates to:
  /// **'SCHNELLZUGRIFF'**
  String get portalQuickAccess;

  /// No description provided for @portalPodcastMedia.
  ///
  /// In de, this message translates to:
  /// **'PODCAST & MEDIA'**
  String get portalPodcastMedia;

  /// No description provided for @portalSocialNetworks.
  ///
  /// In de, this message translates to:
  /// **'SOZIALE NETZWERKE'**
  String get portalSocialNetworks;

  /// No description provided for @portalAssociation.
  ///
  /// In de, this message translates to:
  /// **'VEREIN'**
  String get portalAssociation;

  /// No description provided for @portalProfile.
  ///
  /// In de, this message translates to:
  /// **'Dein Profil & Badges'**
  String get portalProfile;

  /// No description provided for @portalMeetupMap.
  ///
  /// In de, this message translates to:
  /// **'Meetup-Karte'**
  String get portalMeetupMap;

  /// No description provided for @portalMeetupMapSub.
  ///
  /// In de, this message translates to:
  /// **'Treffen in deiner Nähe'**
  String get portalMeetupMapSub;

  /// No description provided for @portalBeginnerPath.
  ///
  /// In de, this message translates to:
  /// **'Der Weg (Einsteiger)'**
  String get portalBeginnerPath;

  /// No description provided for @portalShoutoutSend.
  ///
  /// In de, this message translates to:
  /// **'Shoutout senden'**
  String get portalShoutoutSend;

  /// No description provided for @portalMembership.
  ///
  /// In de, this message translates to:
  /// **'Mitglied werden'**
  String get portalMembership;

  /// No description provided for @portalSoundboard.
  ///
  /// In de, this message translates to:
  /// **'Soundboard'**
  String get portalSoundboard;

  /// No description provided for @portalClipsSounds.
  ///
  /// In de, this message translates to:
  /// **'Clips & Sounds'**
  String get portalClipsSounds;

  /// No description provided for @portalInterviews.
  ///
  /// In de, this message translates to:
  /// **'Interviews'**
  String get portalInterviews;

  /// No description provided for @portalMediaArticles.
  ///
  /// In de, this message translates to:
  /// **'Media & Artikel'**
  String get portalMediaArticles;

  /// No description provided for @portalMerch.
  ///
  /// In de, this message translates to:
  /// **'Merch & Bitcoin-Produkte'**
  String get portalMerch;

  /// No description provided for @portalShop.
  ///
  /// In de, this message translates to:
  /// **'Shop'**
  String get portalShop;

  /// No description provided for @portalDonate.
  ///
  /// In de, this message translates to:
  /// **'Spenden'**
  String get portalDonate;

  /// No description provided for @portalContact.
  ///
  /// In de, this message translates to:
  /// **'Kontakt'**
  String get portalContact;

  /// No description provided for @portalPrivacy.
  ///
  /// In de, this message translates to:
  /// **'Datenschutz'**
  String get portalPrivacy;

  /// No description provided for @portalStatutes.
  ///
  /// In de, this message translates to:
  /// **'Satzung (PDF)'**
  String get portalStatutes;

  /// No description provided for @portalAboutAssoc.
  ///
  /// In de, this message translates to:
  /// **'Über den Verein'**
  String get portalAboutAssoc;

  /// No description provided for @portalOpen.
  ///
  /// In de, this message translates to:
  /// **'Portal öffnen'**
  String get portalOpen;

  /// No description provided for @portalTagline.
  ///
  /// In de, this message translates to:
  /// **'für bullishe Bitcoiner.'**
  String get portalTagline;

  /// No description provided for @portalInfotainment.
  ///
  /// In de, this message translates to:
  /// **'Toximalistisches Infotainment'**
  String get portalInfotainment;

  /// No description provided for @portalPodcast.
  ///
  /// In de, this message translates to:
  /// **'Podcast'**
  String get portalPodcast;

  /// No description provided for @portalProfile2.
  ///
  /// In de, this message translates to:
  /// **'Portal'**
  String get portalProfile2;

  /// No description provided for @profileTitle.
  ///
  /// In de, this message translates to:
  /// **'DEIN PROFIL'**
  String get profileTitle;

  /// No description provided for @profileEditTitle.
  ///
  /// In de, this message translates to:
  /// **'PROFIL BEARBEITEN'**
  String get profileEditTitle;

  /// No description provided for @profileSave.
  ///
  /// In de, this message translates to:
  /// **'PROFIL SPEICHERN'**
  String get profileSave;

  /// No description provided for @profileIntro.
  ///
  /// In de, this message translates to:
  /// **'Wähle einen Nickname und dein Home-Meetup.'**
  String get profileIntro;

  /// No description provided for @profileNicknameMin.
  ///
  /// In de, this message translates to:
  /// **'Mindestens 2 Zeichen'**
  String get profileNicknameMin;

  /// No description provided for @profileNicknameReq.
  ///
  /// In de, this message translates to:
  /// **'Pflichtfeld — bitte ausfüllen'**
  String get profileNicknameReq;

  /// No description provided for @profileNicknameAnon.
  ///
  /// In de, this message translates to:
  /// **'Bitte wähle einen eigenen Nickname (nicht \'Anon\')'**
  String get profileNicknameAnon;

  /// No description provided for @profileHomeMeetup.
  ///
  /// In de, this message translates to:
  /// **'Home Meetup'**
  String get profileHomeMeetup;

  /// No description provided for @profileHomeMeetupDash.
  ///
  /// In de, this message translates to:
  /// **'Home-Meetup'**
  String get profileHomeMeetupDash;

  /// No description provided for @profileChooseMeetup.
  ///
  /// In de, this message translates to:
  /// **'Wähle dein Home-Meetup'**
  String get profileChooseMeetup;

  /// No description provided for @profileMeetupReq.
  ///
  /// In de, this message translates to:
  /// **'Pflichtfeld — bitte wähle dein Home-Meetup'**
  String get profileMeetupReq;

  /// No description provided for @profileSearchCity.
  ///
  /// In de, this message translates to:
  /// **'Stadt suchen...'**
  String get profileSearchCity;

  /// No description provided for @profileIdentity.
  ///
  /// In de, this message translates to:
  /// **'DEINE IDENTITÄT'**
  String get profileIdentity;

  /// No description provided for @profileStrengthen.
  ///
  /// In de, this message translates to:
  /// **'IDENTITÄT STÄRKEN'**
  String get profileStrengthen;

  /// No description provided for @profileStrengthenDesc.
  ///
  /// In de, this message translates to:
  /// **'Verknüpfe Plattformen und beweise deine Menschlichkeit um deinen Trust Score zu erhöhen.'**
  String get profileStrengthenDesc;

  /// No description provided for @profileLinkPlatforms.
  ///
  /// In de, this message translates to:
  /// **'Plattformen verknüpfen'**
  String get profileLinkPlatforms;

  /// No description provided for @profilePlatformsSub.
  ///
  /// In de, this message translates to:
  /// **'Telegram, X, Kleinanzeigen'**
  String get profilePlatformsSub;

  /// No description provided for @profileProofHumanity.
  ///
  /// In de, this message translates to:
  /// **'Proof of Humanity'**
  String get profileProofHumanity;

  /// No description provided for @profileZapCheck.
  ///
  /// In de, this message translates to:
  /// **'Einmal gezappt? Jetzt prüfen'**
  String get profileZapCheck;

  /// No description provided for @profileLightningActive.
  ///
  /// In de, this message translates to:
  /// **'Lightning-Beweis aktiv'**
  String get profileLightningActive;

  /// No description provided for @profileVerified.
  ///
  /// In de, this message translates to:
  /// **'VERIFIZIERT'**
  String get profileVerified;

  /// No description provided for @profileNostrKeyShort.
  ///
  /// In de, this message translates to:
  /// **'Nostr'**
  String get profileNostrKeyShort;

  /// No description provided for @profileNoKey.
  ///
  /// In de, this message translates to:
  /// **'Noch kein Nostr-Key vorhanden'**
  String get profileNoKey;

  /// No description provided for @profileKeyActiveCaps.
  ///
  /// In de, this message translates to:
  /// **'SCHLÜSSEL AKTIV'**
  String get profileKeyActiveCaps;

  /// No description provided for @profileCreateKey.
  ///
  /// In de, this message translates to:
  /// **'NOSTR KEY ERSTELLEN'**
  String get profileCreateKey;

  /// No description provided for @profileCreateNewKey.
  ///
  /// In de, this message translates to:
  /// **'NEUEN KEY ERSTELLEN'**
  String get profileCreateNewKey;

  /// No description provided for @profileCreating.
  ///
  /// In de, this message translates to:
  /// **'WIRD ERSTELLT...'**
  String get profileCreating;

  /// No description provided for @profileNoNostrNeeded.
  ///
  /// In de, this message translates to:
  /// **'Du brauchst kein Nostr-Konto. Die App erstellt dir einen Schlüssel — das dauert eine Sekunde.'**
  String get profileNoNostrNeeded;

  /// No description provided for @profileKeyDesc.
  ///
  /// In de, this message translates to:
  /// **'Dein kryptografischer Schlüssel — damit werden Badges signiert und deine Reputation verifiziert.'**
  String get profileKeyDesc;

  /// No description provided for @profileConnectAmber.
  ///
  /// In de, this message translates to:
  /// **'MIT AMBER VERBINDEN'**
  String get profileConnectAmber;

  /// No description provided for @profileAmberDesc.
  ///
  /// In de, this message translates to:
  /// **'Amber ist ein separater Signer für Android, der deinen privaten '**
  String get profileAmberDesc;

  /// No description provided for @profileAmberConnected.
  ///
  /// In de, this message translates to:
  /// **'Mit Amber verbunden! Dein nsec bleibt in Amber.'**
  String get profileAmberConnected;

  /// No description provided for @profileAmberNotFound.
  ///
  /// In de, this message translates to:
  /// **'Amber nicht gefunden'**
  String get profileAmberNotFound;

  /// No description provided for @profileAmberInstall.
  ///
  /// In de, this message translates to:
  /// **'Schlüssel sicher verwahrt. Installiere Amber (z.B. über F-Droid '**
  String get profileAmberInstall;

  /// No description provided for @profileAmberRetry.
  ///
  /// In de, this message translates to:
  /// **'oder den Zapstore) und versuche es erneut.'**
  String get profileAmberRetry;

  /// No description provided for @profileAmberAborted.
  ///
  /// In de, this message translates to:
  /// **'Verbindung in Amber abgebrochen.'**
  String get profileAmberAborted;

  /// No description provided for @profileImportNsec.
  ///
  /// In de, this message translates to:
  /// **'BESTEHENDEN NSEC IMPORTIEREN'**
  String get profileImportNsec;

  /// No description provided for @profileImportNsecShort.
  ///
  /// In de, this message translates to:
  /// **'NSEC IMPORTIEREN'**
  String get profileImportNsecShort;

  /// No description provided for @profileImport.
  ///
  /// In de, this message translates to:
  /// **'IMPORTIEREN'**
  String get profileImport;

  /// No description provided for @profileEnterNsec.
  ///
  /// In de, this message translates to:
  /// **'Gib deinen privaten Nostr-Schlüssel ein (beginnt mit nsec1...):'**
  String get profileEnterNsec;

  /// No description provided for @profileKeyImported.
  ///
  /// In de, this message translates to:
  /// **'Key importiert!'**
  String get profileKeyImported;

  /// No description provided for @profileShowNsecQ.
  ///
  /// In de, this message translates to:
  /// **'NSEC ANZEIGEN?'**
  String get profileShowNsecQ;

  /// No description provided for @profileShowNsecWarn.
  ///
  /// In de, this message translates to:
  /// **'Dein privater Schlüssel wird angezeigt. Stelle sicher, dass niemand auf deinen Bildschirm schaut!'**
  String get profileShowNsecWarn;

  /// No description provided for @profileShow.
  ///
  /// In de, this message translates to:
  /// **'ANZEIGEN'**
  String get profileShow;

  /// No description provided for @profileCopy.
  ///
  /// In de, this message translates to:
  /// **'KOPIEREN'**
  String get profileCopy;

  /// No description provided for @profileSecureKey.
  ///
  /// In de, this message translates to:
  /// **'SICHERE DEINEN KEY!'**
  String get profileSecureKey;

  /// No description provided for @profileSaveKeyDesc.
  ///
  /// In de, this message translates to:
  /// **'Dies ist dein privater Schlüssel. Speichere ihn an einem sicheren Ort! '**
  String get profileSaveKeyDesc;

  /// No description provided for @profileKeyNotShownAgain.
  ///
  /// In de, this message translates to:
  /// **'Dieser Key wird NICHT nochmal angezeigt!'**
  String get profileKeyNotShownAgain;

  /// No description provided for @profileKeySecured.
  ///
  /// In de, this message translates to:
  /// **'ICH HAB IHN GESICHERT'**
  String get profileKeySecured;

  /// No description provided for @profileNpubCopied.
  ///
  /// In de, this message translates to:
  /// **'npub kopiert!'**
  String get profileNpubCopied;

  /// No description provided for @profileNsecCopied.
  ///
  /// In de, this message translates to:
  /// **'nsec kopiert! Jetzt sicher abspeichern.'**
  String get profileNsecCopied;

  /// No description provided for @profileNsecNeverLeaves.
  ///
  /// In de, this message translates to:
  /// **'Dein nsec verlässt niemals dein Gerät.'**
  String get profileNsecNeverLeaves;

  /// No description provided for @profileWhoHasKey.
  ///
  /// In de, this message translates to:
  /// **'Wer diesen Key hat, HAT deine Identität.'**
  String get profileWhoHasKey;

  /// No description provided for @profileBackupNsec.
  ///
  /// In de, this message translates to:
  /// **'Wichtig: Sichere deinen nsec! Wenn du dein Gerät verlierst, ist dein Key weg.'**
  String get profileBackupNsec;

  /// No description provided for @profileNewKeypairDesc.
  ///
  /// In de, this message translates to:
  /// **'Es wird ein neues Schlüsselpaar erstellt. Dein privater Schlüssel (nsec) wird sicher auf deinem Gerät gespeichert.\n\n'**
  String get profileNewKeypairDesc;

  /// No description provided for @profileEdit.
  ///
  /// In de, this message translates to:
  /// **'Bearbeiten'**
  String get profileEdit;

  /// No description provided for @profileEditLoseStatus.
  ///
  /// In de, this message translates to:
  /// **'BEARBEITEN (Status verlieren)'**
  String get profileEditLoseStatus;

  /// No description provided for @profileWarning.
  ///
  /// In de, this message translates to:
  /// **'Achtung!'**
  String get profileWarning;

  /// No description provided for @profileEditWarnDesc.
  ///
  /// In de, this message translates to:
  /// **'Wenn du bearbeitest, verlierst du deinen \'Verifiziert\'-Status und musst neu freigeschaltet werden.'**
  String get profileEditWarnDesc;

  /// No description provided for @dialogCancel.
  ///
  /// In de, this message translates to:
  /// **'ABBRECHEN'**
  String get dialogCancel;

  /// No description provided for @dialogCancelMixed.
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get dialogCancelMixed;

  /// No description provided for @dialogCreate.
  ///
  /// In de, this message translates to:
  /// **'ERSTELLEN'**
  String get dialogCreate;

  /// No description provided for @errorGeneric.
  ///
  /// In de, this message translates to:
  /// **'Fehler: {msg}'**
  String errorGeneric(String msg);

  /// No description provided for @errorAmber.
  ///
  /// In de, this message translates to:
  /// **'Amber-Fehler: {msg}'**
  String errorAmber(String msg);

  /// No description provided for @profileFillIn.
  ///
  /// In de, this message translates to:
  /// **'Bitte ausfüllen: {fields}'**
  String profileFillIn(Object fields);

  /// No description provided for @backupEncryptTitle.
  ///
  /// In de, this message translates to:
  /// **'Backup verschlüsseln'**
  String get backupEncryptTitle;

  /// No description provided for @backupDecryptTitle.
  ///
  /// In de, this message translates to:
  /// **'Backup entschlüsseln'**
  String get backupDecryptTitle;

  /// No description provided for @backupExportDesc.
  ///
  /// In de, this message translates to:
  /// **'Vergib ein Passwort, um deinen privaten Schlüssel (nsec) im Backup zu schützen.\n\n⚠️ Wenn du dieses Passwort vergisst, ist das Backup UNWIEDERBRINGLICH verloren!'**
  String get backupExportDesc;

  /// No description provided for @backupImportDesc.
  ///
  /// In de, this message translates to:
  /// **'Dieses Backup ist verschlüsselt. Bitte gib das Passwort ein.'**
  String get backupImportDesc;

  /// No description provided for @backupPassword.
  ///
  /// In de, this message translates to:
  /// **'Passwort'**
  String get backupPassword;

  /// No description provided for @backupPasswordConfirm.
  ///
  /// In de, this message translates to:
  /// **'Passwort bestätigen'**
  String get backupPasswordConfirm;

  /// No description provided for @backupPasswordEmpty.
  ///
  /// In de, this message translates to:
  /// **'Passwort darf nicht leer sein'**
  String get backupPasswordEmpty;

  /// No description provided for @backupPasswordMin.
  ///
  /// In de, this message translates to:
  /// **'Mindestens 8 Zeichen'**
  String get backupPasswordMin;

  /// No description provided for @backupPasswordMismatch.
  ///
  /// In de, this message translates to:
  /// **'Passwörter stimmen nicht überein'**
  String get backupPasswordMismatch;

  /// No description provided for @backupEncryptSave.
  ///
  /// In de, this message translates to:
  /// **'Verschlüsseln & Speichern'**
  String get backupEncryptSave;

  /// No description provided for @backupDecryptLoad.
  ///
  /// In de, this message translates to:
  /// **'Entschlüsseln & Laden'**
  String get backupDecryptLoad;

  /// No description provided for @backupShareTitle.
  ///
  /// In de, this message translates to:
  /// **'Einundzwanzig App Backup (Verschlüsselt)'**
  String get backupShareTitle;

  /// No description provided for @backupShareText.
  ///
  /// In de, this message translates to:
  /// **'Dein verschlüsseltes Backup. Halte dein Passwort bereit, um es wiederherzustellen.'**
  String get backupShareText;

  /// No description provided for @backupError.
  ///
  /// In de, this message translates to:
  /// **'Fehler beim Backup: {msg}'**
  String backupError(String msg);

  /// No description provided for @backupCorrupt.
  ///
  /// In de, this message translates to:
  /// **'Backup-Datei ist beschädigt (Formatfehler).'**
  String get backupCorrupt;

  /// No description provided for @backupWrongPassword.
  ///
  /// In de, this message translates to:
  /// **'Falsches Passwort oder Datei beschädigt!'**
  String get backupWrongPassword;

  /// No description provided for @backupNotValid.
  ///
  /// In de, this message translates to:
  /// **'Datei ist kein gültiges Backup oder das falsche Format.'**
  String get backupNotValid;

  /// No description provided for @backupNotEinundzwanzig.
  ///
  /// In de, this message translates to:
  /// **'Datei ist kein gültiges Einundzwanzig Backup.'**
  String get backupNotEinundzwanzig;

  /// No description provided for @backupLoaded.
  ///
  /// In de, this message translates to:
  /// **'✅ Backup geladen! {items} wiederhergestellt.'**
  String backupLoaded(Object items);

  /// No description provided for @backupImportFailed.
  ///
  /// In de, this message translates to:
  /// **'Import fehlgeschlagen: {msg}'**
  String backupImportFailed(String msg);

  /// No description provided for @qrScanTitle.
  ///
  /// In de, this message translates to:
  /// **'REPUTATION PRÜFEN'**
  String get qrScanTitle;

  /// No description provided for @qrResultTitle.
  ///
  /// In de, this message translates to:
  /// **'ERGEBNIS'**
  String get qrResultTitle;

  /// No description provided for @qrScanHint.
  ///
  /// In de, this message translates to:
  /// **'Scanne einen Einundzwanzig\nReputation QR-Code'**
  String get qrScanHint;

  /// No description provided for @qrLoadFromGallery.
  ///
  /// In de, this message translates to:
  /// **'QR AUS GALERIE LADEN'**
  String get qrLoadFromGallery;

  /// No description provided for @qrBack.
  ///
  /// In de, this message translates to:
  /// **'ZURÜCK'**
  String get qrBack;

  /// No description provided for @qrNoCodeInImage.
  ///
  /// In de, this message translates to:
  /// **'Kein QR-Code im Bild gefunden'**
  String get qrNoCodeInImage;

  /// No description provided for @qrNotEinundzwanzig.
  ///
  /// In de, this message translates to:
  /// **'QR-Code gefunden, aber kein Einundzwanzig-Format'**
  String get qrNotEinundzwanzig;

  /// No description provided for @qrVerified.
  ///
  /// In de, this message translates to:
  /// **'VERIFIZIERT'**
  String get qrVerified;

  /// No description provided for @qrVerifiedV1.
  ///
  /// In de, this message translates to:
  /// **'VERIFIZIERT (v1)'**
  String get qrVerifiedV1;

  /// No description provided for @qrVerifiedV2.
  ///
  /// In de, this message translates to:
  /// **'VERIFIZIERT (v2)'**
  String get qrVerifiedV2;

  /// No description provided for @qrSigInvalid.
  ///
  /// In de, this message translates to:
  /// **'SIGNATUR UNGÜLTIG'**
  String get qrSigInvalid;

  /// No description provided for @qrFormatUnknown.
  ///
  /// In de, this message translates to:
  /// **'FORMAT UNBEKANNT'**
  String get qrFormatUnknown;

  /// No description provided for @qrReadError.
  ///
  /// In de, this message translates to:
  /// **'LESEFEHLER'**
  String get qrReadError;

  /// No description provided for @qrV2Subtitle.
  ///
  /// In de, this message translates to:
  /// **'Legacy-Signatur gültig — kein Badge-Proof'**
  String get qrV2Subtitle;

  /// No description provided for @qrV1Subtitle.
  ///
  /// In de, this message translates to:
  /// **'Älteres Format — keine Identitätsbindung'**
  String get qrV1Subtitle;

  /// No description provided for @qrCantRead.
  ///
  /// In de, this message translates to:
  /// **'QR-Code konnte nicht gelesen werden.'**
  String get qrCantRead;

  /// No description provided for @qrProcessError.
  ///
  /// In de, this message translates to:
  /// **'Fehler beim Verarbeiten: {msg}'**
  String qrProcessError(String msg);

  /// No description provided for @qrSectionIdentity.
  ///
  /// In de, this message translates to:
  /// **'IDENTITÄT'**
  String get qrSectionIdentity;

  /// No description provided for @qrNoIdentity.
  ///
  /// In de, this message translates to:
  /// **'KEINE IDENTITÄT'**
  String get qrNoIdentity;

  /// No description provided for @qrNoVerifiableIdentity.
  ///
  /// In de, this message translates to:
  /// **'Keine verifizierbare Identität.'**
  String get qrNoVerifiableIdentity;

  /// No description provided for @qrSectionLightning.
  ///
  /// In de, this message translates to:
  /// **'LIGHTNING'**
  String get qrSectionLightning;

  /// No description provided for @qrSectionSocial.
  ///
  /// In de, this message translates to:
  /// **'SOZIALES NETZWERK'**
  String get qrSectionSocial;

  /// No description provided for @qrSectionPlatforms.
  ///
  /// In de, this message translates to:
  /// **'VERKNÜPFTE PLATTFORMEN'**
  String get qrSectionPlatforms;

  /// No description provided for @qrSectionMeetups.
  ///
  /// In de, this message translates to:
  /// **'BESUCHTE MEETUPS'**
  String get qrSectionMeetups;

  /// No description provided for @qrHumanVerified.
  ///
  /// In de, this message translates to:
  /// **'Mensch verifiziert'**
  String get qrHumanVerified;

  /// No description provided for @qrLightningActive.
  ///
  /// In de, this message translates to:
  /// **'Lightning-Beweis aktiv'**
  String get qrLightningActive;

  /// No description provided for @qrNoLightning.
  ///
  /// In de, this message translates to:
  /// **'Kein Lightning-Beweis gefunden'**
  String get qrNoLightning;

  /// No description provided for @qrNoZap.
  ///
  /// In de, this message translates to:
  /// **'Keine Zap-Aktivität'**
  String get qrNoZap;

  /// No description provided for @qrNip05Invalid.
  ///
  /// In de, this message translates to:
  /// **'NIP-05 ungültig'**
  String get qrNip05Invalid;

  /// No description provided for @qrYouFollow.
  ///
  /// In de, this message translates to:
  /// **'Du folgst'**
  String get qrYouFollow;

  /// No description provided for @qrFollowsYou.
  ///
  /// In de, this message translates to:
  /// **'Folgt dir'**
  String get qrFollowsYou;

  /// No description provided for @qrMutualFollow.
  ///
  /// In de, this message translates to:
  /// **'Gegenseitiger Follow'**
  String get qrMutualFollow;

  /// No description provided for @qrNoDirectFollow.
  ///
  /// In de, this message translates to:
  /// **'Kein direkter Follow'**
  String get qrNoDirectFollow;

  /// No description provided for @qrDirectConnection.
  ///
  /// In de, this message translates to:
  /// **'Direkte Verbindung'**
  String get qrDirectConnection;

  /// No description provided for @qrBidirectional.
  ///
  /// In de, this message translates to:
  /// **'Direkte bidirektionale Verbindung'**
  String get qrBidirectional;

  /// No description provided for @qrOneWay.
  ///
  /// In de, this message translates to:
  /// **'Einseitige Verbindung'**
  String get qrOneWay;

  /// No description provided for @qrViaContacts.
  ///
  /// In de, this message translates to:
  /// **'Über gemeinsame Kontakte'**
  String get qrViaContacts;

  /// No description provided for @qrStrongOverlap.
  ///
  /// In de, this message translates to:
  /// **'Starke Netzwerk-Überlappung'**
  String get qrStrongOverlap;

  /// No description provided for @qrPartiallyConnected.
  ///
  /// In de, this message translates to:
  /// **'Teilweise verbunden'**
  String get qrPartiallyConnected;

  /// No description provided for @qrNoOverlap.
  ///
  /// In de, this message translates to:
  /// **'Keine Überlappung'**
  String get qrNoOverlap;

  /// No description provided for @qrEndorsement.
  ///
  /// In de, this message translates to:
  /// **'Endorsement von bekannten Admins'**
  String get qrEndorsement;

  /// No description provided for @qrSigVerified.
  ///
  /// In de, this message translates to:
  /// **'Signatur verifiziert'**
  String get qrSigVerified;

  /// No description provided for @qrAnalyzingNetwork.
  ///
  /// In de, this message translates to:
  /// **'Analysiere Netzwerk...'**
  String get qrAnalyzingNetwork;

  /// No description provided for @qrCheckingLightning.
  ///
  /// In de, this message translates to:
  /// **'Prüfe Lightning...'**
  String get qrCheckingLightning;

  /// No description provided for @qrCheckingNip05.
  ///
  /// In de, this message translates to:
  /// **'Prüfe NIP-05...'**
  String get qrCheckingNip05;

  /// No description provided for @qrStatBadges.
  ///
  /// In de, this message translates to:
  /// **'Badges'**
  String get qrStatBadges;

  /// No description provided for @qrStatMeetups.
  ///
  /// In de, this message translates to:
  /// **'Meetups'**
  String get qrStatMeetups;

  /// No description provided for @qrStatSigners.
  ///
  /// In de, this message translates to:
  /// **'Signer'**
  String get qrStatSigners;

  /// No description provided for @qrStatBound.
  ///
  /// In de, this message translates to:
  /// **'Gebunden'**
  String get qrStatBound;

  /// No description provided for @qrStatDays.
  ///
  /// In de, this message translates to:
  /// **'Tage'**
  String get qrStatDays;

  /// No description provided for @qrLabelNickname.
  ///
  /// In de, this message translates to:
  /// **'Nickname'**
  String get qrLabelNickname;

  /// No description provided for @qrLabelTwitter.
  ///
  /// In de, this message translates to:
  /// **'Twitter/X'**
  String get qrLabelTwitter;

  /// No description provided for @qrPlatformOther.
  ///
  /// In de, this message translates to:
  /// **'Andere'**
  String get qrPlatformOther;

  /// No description provided for @qrLinked.
  ///
  /// In de, this message translates to:
  /// **'Verknüpft'**
  String get qrLinked;

  /// No description provided for @qrSigVerifiedShort.
  ///
  /// In de, this message translates to:
  /// **'Signatur verifiziert'**
  String get qrSigVerifiedShort;

  /// No description provided for @qrLinkedShort.
  ///
  /// In de, this message translates to:
  /// **'Verknüpft'**
  String get qrLinkedShort;

  /// No description provided for @nfcDisabled.
  ///
  /// In de, this message translates to:
  /// **'NFC ist deaktiviert'**
  String get nfcDisabled;

  /// No description provided for @nfcDisabledHint.
  ///
  /// In de, this message translates to:
  /// **'NFC ist deaktiviert. Bitte einschalten.'**
  String get nfcDisabledHint;

  /// No description provided for @nfcUnavailable.
  ///
  /// In de, this message translates to:
  /// **'NFC nicht verfügbar'**
  String get nfcUnavailable;

  /// No description provided for @nfcOpenSettings.
  ///
  /// In de, this message translates to:
  /// **'EINSTELLUNGEN ÖFFNEN'**
  String get nfcOpenSettings;

  /// No description provided for @nfcEnableHint.
  ///
  /// In de, this message translates to:
  /// **'Bitte aktiviere NFC in deinen Geräteeinstellungen, '**
  String get nfcEnableHint;

  /// No description provided for @nfcSettingsAndroid.
  ///
  /// In de, this message translates to:
  /// **'Android: Einstellungen → Verbindungen → NFC'**
  String get nfcSettingsAndroid;

  /// No description provided for @nfcSettingsIos.
  ///
  /// In de, this message translates to:
  /// **'iOS: Einstellungen → NFC'**
  String get nfcSettingsIos;

  /// No description provided for @verifyScanBadge.
  ///
  /// In de, this message translates to:
  /// **'BADGE SCANNEN'**
  String get verifyScanBadge;

  /// No description provided for @verifyScanNfc.
  ///
  /// In de, this message translates to:
  /// **'NFC TAG SCANNEN'**
  String get verifyScanNfc;

  /// No description provided for @verifyScanQr.
  ///
  /// In de, this message translates to:
  /// **'QR SCANNEN'**
  String get verifyScanQr;

  /// No description provided for @verifyScanQrCaps.
  ///
  /// In de, this message translates to:
  /// **'QR-CODE SCANNEN'**
  String get verifyScanQrCaps;

  /// No description provided for @verifyReadyToScan.
  ///
  /// In de, this message translates to:
  /// **'Bereit zum Scannen'**
  String get verifyReadyToScan;

  /// No description provided for @verifyWaitingNfc.
  ///
  /// In de, this message translates to:
  /// **'Warte auf NFC Tag...'**
  String get verifyWaitingNfc;

  /// No description provided for @verifyCheckingNfc.
  ///
  /// In de, this message translates to:
  /// **'Prüfe NFC...'**
  String get verifyCheckingNfc;

  /// No description provided for @verifyScanInstruction.
  ///
  /// In de, this message translates to:
  /// **'Scanne den NFC-Tag oder QR-Code\ndes Meetup-Organisators.'**
  String get verifyScanInstruction;

  /// No description provided for @verifyScanQrInstruction.
  ///
  /// In de, this message translates to:
  /// **'Scanne den QR-Code\ndes Meetup-Organisators'**
  String get verifyScanQrInstruction;

  /// No description provided for @verifyNoNfcDevice.
  ///
  /// In de, this message translates to:
  /// **'Dieses Gerät hat kein NFC. Nutze den QR-Scanner.'**
  String get verifyNoNfcDevice;

  /// No description provided for @verifyNoNfcLong.
  ///
  /// In de, this message translates to:
  /// **'Dieses Gerät unterstützt kein NFC.\n\n'**
  String get verifyNoNfcLong;

  /// No description provided for @verifyUseQrInstead.
  ///
  /// In de, this message translates to:
  /// **'Nutze stattdessen den QR-Code-Scanner, '**
  String get verifyUseQrInstead;

  /// No description provided for @verifyToGetBadge.
  ///
  /// In de, this message translates to:
  /// **'um dein Badge zu erhalten.'**
  String get verifyToGetBadge;

  /// No description provided for @verifyAskScan.
  ///
  /// In de, this message translates to:
  /// **'Bitte lass einen Teilnehmer deinen Tag scannen.'**
  String get verifyAskScan;

  /// No description provided for @verifyCantSelfBadge.
  ///
  /// In de, this message translates to:
  /// **'Du kannst dir nicht selbst ein Badge geben.\n'**
  String get verifyCantSelfBadge;

  /// No description provided for @verifyBadgeFound.
  ///
  /// In de, this message translates to:
  /// **'BADGE GEFUNDEN'**
  String get verifyBadgeFound;

  /// No description provided for @verifyAlreadyCollected.
  ///
  /// In de, this message translates to:
  /// **'BEREITS GESAMMELT'**
  String get verifyAlreadyCollected;

  /// No description provided for @verifyAddToWallet.
  ///
  /// In de, this message translates to:
  /// **'ZUR WALLET HINZUFÜGEN'**
  String get verifyAddToWallet;

  /// No description provided for @verifyVerifiedAdmin.
  ///
  /// In de, this message translates to:
  /// **'Verifizierter Admin'**
  String get verifyVerifiedAdmin;

  /// No description provided for @verifyUnknownMeetup.
  ///
  /// In de, this message translates to:
  /// **'Unbekanntes Meetup'**
  String get verifyUnknownMeetup;

  /// No description provided for @verifyNoExpiry.
  ///
  /// In de, this message translates to:
  /// **'Kein Ablauf'**
  String get verifyNoExpiry;

  /// No description provided for @writerReadyToWrite.
  ///
  /// In de, this message translates to:
  /// **'Bereit zum Schreiben'**
  String get writerReadyToWrite;

  /// No description provided for @writerNoNfcDevice.
  ///
  /// In de, this message translates to:
  /// **'Dieses Gerät hat kein NFC. Nutze Rolling QR-Codes.'**
  String get writerNoNfcDevice;

  /// No description provided for @writerUseRollingQr.
  ///
  /// In de, this message translates to:
  /// **'Du kannst stattdessen Rolling QR-Codes '**
  String get writerUseRollingQr;

  /// No description provided for @writerForYourMeetup.
  ///
  /// In de, this message translates to:
  /// **'für dein Meetup verwenden.'**
  String get writerForYourMeetup;

  /// No description provided for @writerSelectHomeFirst.
  ///
  /// In de, this message translates to:
  /// **'Bitte erst ein Home-Meetup im Profil auswählen'**
  String get writerSelectHomeFirst;

  /// No description provided for @writerYourHomeMeetup.
  ///
  /// In de, this message translates to:
  /// **'DEIN HOME-MEETUP'**
  String get writerYourHomeMeetup;

  /// No description provided for @writerCreateTag.
  ///
  /// In de, this message translates to:
  /// **'TAG ERSTELLEN'**
  String get writerCreateTag;

  /// No description provided for @writerCreateMeetupTag.
  ///
  /// In de, this message translates to:
  /// **'MEETUP TAG ERSTELLEN'**
  String get writerCreateMeetupTag;

  /// No description provided for @writerMeetupTag.
  ///
  /// In de, this message translates to:
  /// **'MEETUP TAG'**
  String get writerMeetupTag;

  /// No description provided for @writerSuccess.
  ///
  /// In de, this message translates to:
  /// **'ERFOLG!'**
  String get writerSuccess;

  /// No description provided for @writerValid6h.
  ///
  /// In de, this message translates to:
  /// **'Gültig für 6 Stunden'**
  String get writerValid6h;

  /// No description provided for @writerHoldTag.
  ///
  /// In de, this message translates to:
  /// **'Halte Tag an das Gerät...'**
  String get writerHoldTag;

  /// No description provided for @writerHoldTagInstruction.
  ///
  /// In de, this message translates to:
  /// **'Halte einen NFC Tag an das Gerät.\nTeilnehmer scannen diesen Tag um ein Badge zu sammeln.'**
  String get writerHoldTagInstruction;

  /// No description provided for @writerFormatting.
  ///
  /// In de, this message translates to:
  /// **'Formatiere leeren Tag...'**
  String get writerFormatting;

  /// No description provided for @writerFormatFailed.
  ///
  /// In de, this message translates to:
  /// **'Formatierung fehlgeschlagen'**
  String get writerFormatFailed;

  /// No description provided for @writerLoadingSession.
  ///
  /// In de, this message translates to:
  /// **'Lade Session-Daten...'**
  String get writerLoadingSession;

  /// No description provided for @writerJumpToQr.
  ///
  /// In de, this message translates to:
  /// **'Springe zum QR-Code...'**
  String get writerJumpToQr;

  /// No description provided for @writerNoNdef.
  ///
  /// In de, this message translates to:
  /// **'Kein NDEF Format möglich'**
  String get writerNoNdef;

  /// No description provided for @writerTagReadOnly.
  ///
  /// In de, this message translates to:
  /// **'Tag ist schreibgeschützt'**
  String get writerTagReadOnly;

  /// No description provided for @writerCanOverwrite.
  ///
  /// In de, this message translates to:
  /// **'Tag kann danach überschrieben werden'**
  String get writerCanOverwrite;

  /// No description provided for @writerTagLost.
  ///
  /// In de, this message translates to:
  /// **'Tag verloren während dem Schreiben'**
  String get writerTagLost;

  /// No description provided for @writerTagRemovedEarly.
  ///
  /// In de, this message translates to:
  /// **'Tag zu früh entfernt — halte ihn ruhig 2–3 Sekunden ans Gerät'**
  String get writerTagRemovedEarly;

  /// No description provided for @writerUseNtag215.
  ///
  /// In de, this message translates to:
  /// **'Verwende einen NTAG215 (504B) oder größer.'**
  String get writerUseNtag215;

  /// No description provided for @writerToWriteTag.
  ///
  /// In de, this message translates to:
  /// **'um den Tag zu beschreiben.\n\n'**
  String get writerToWriteTag;

  /// No description provided for @verifyMsgLocation.
  ///
  /// In de, this message translates to:
  /// **'Ort: {name}'**
  String verifyMsgLocation(String name);

  /// No description provided for @verifyMsgBlock.
  ///
  /// In de, this message translates to:
  /// **'Block: {height}'**
  String verifyMsgBlock(Object height);

  /// No description provided for @verifyMsgSignedBy.
  ///
  /// In de, this message translates to:
  /// **'Signiert von: {signer}'**
  String verifyMsgSignedBy(String signer);

  /// No description provided for @verifyMsgProof.
  ///
  /// In de, this message translates to:
  /// **'Beweis: Schnorr (BIP-340)'**
  String get verifyMsgProof;

  /// No description provided for @verifyMsgTagExpiry.
  ///
  /// In de, this message translates to:
  /// **'Tag-Ablauf: {expiry}'**
  String verifyMsgTagExpiry(String expiry);

  /// No description provided for @verifyAlreadyToday.
  ///
  /// In de, this message translates to:
  /// **'Bereits gesammelt\n\nHeute hast du bereits ein Badge von:\n{name}'**
  String verifyAlreadyToday(String name);

  /// No description provided for @wotTitle.
  ///
  /// In de, this message translates to:
  /// **'WEB OF TRUST'**
  String get wotTitle;

  /// No description provided for @wotActiveOrganizers.
  ///
  /// In de, this message translates to:
  /// **'AKTIVE ORGANISATOREN'**
  String get wotActiveOrganizers;

  /// No description provided for @wotActiveOrganizer.
  ///
  /// In de, this message translates to:
  /// **'AKTIVER ORGANISATOR'**
  String get wotActiveOrganizer;

  /// No description provided for @wotActiveWarnings.
  ///
  /// In de, this message translates to:
  /// **'AKTIVE WARNUNGEN'**
  String get wotActiveWarnings;

  /// No description provided for @wotActiveWarning.
  ///
  /// In de, this message translates to:
  /// **'Aktive Warnung'**
  String get wotActiveWarning;

  /// No description provided for @wotMyStatus.
  ///
  /// In de, this message translates to:
  /// **'DEIN STATUS'**
  String get wotMyStatus;

  /// No description provided for @wotMyVouches.
  ///
  /// In de, this message translates to:
  /// **'DEINE BÜRGSCHAFTEN'**
  String get wotMyVouches;

  /// No description provided for @wotWhoYouVouchFor.
  ///
  /// In de, this message translates to:
  /// **'FÜR WEN DU BÜRGST'**
  String get wotWhoYouVouchFor;

  /// No description provided for @wotWhoVouchesForYou.
  ///
  /// In de, this message translates to:
  /// **'WER BÜRGT FÜR DICH'**
  String get wotWhoVouchesForYou;

  /// No description provided for @wotWeightedReporting.
  ///
  /// In de, this message translates to:
  /// **'GEWICHTETES MELDESYSTEM'**
  String get wotWeightedReporting;

  /// No description provided for @wotRestore.
  ///
  /// In de, this message translates to:
  /// **'WIEDERHERSTELLEN'**
  String get wotRestore;

  /// No description provided for @wotRevokeAll.
  ///
  /// In de, this message translates to:
  /// **'ALLE WIDERRUFEN'**
  String get wotRevokeAll;

  /// No description provided for @wotPublishNostr.
  ///
  /// In de, this message translates to:
  /// **'AUF NOSTR PUBLISHEN'**
  String get wotPublishNostr;

  /// No description provided for @wotVouch.
  ///
  /// In de, this message translates to:
  /// **'BÜRGEN'**
  String get wotVouch;

  /// No description provided for @wotVouchVerb.
  ///
  /// In de, this message translates to:
  /// **'VERBÜRGEN'**
  String get wotVouchVerb;

  /// No description provided for @wotReportNpub.
  ///
  /// In de, this message translates to:
  /// **'NPUB MELDEN'**
  String get wotReportNpub;

  /// No description provided for @wotScanNpub.
  ///
  /// In de, this message translates to:
  /// **'NPUB SCANNEN'**
  String get wotScanNpub;

  /// No description provided for @wotPublishRevocation.
  ///
  /// In de, this message translates to:
  /// **'WIDERRUF PUBLISHEN'**
  String get wotPublishRevocation;

  /// No description provided for @wotSigningPublishing.
  ///
  /// In de, this message translates to:
  /// **'SIGNIERE & PUBLIZIERE...'**
  String get wotSigningPublishing;

  /// No description provided for @wotSyncNetwork.
  ///
  /// In de, this message translates to:
  /// **'Netzwerk synchronisieren'**
  String get wotSyncNetwork;

  /// No description provided for @wotBootstrapPhase.
  ///
  /// In de, this message translates to:
  /// **'Bootstrap-Phase'**
  String get wotBootstrapPhase;

  /// No description provided for @wotDecentralized.
  ///
  /// In de, this message translates to:
  /// **'Dezentral (Web of Trust)'**
  String get wotDecentralized;

  /// No description provided for @wotMinVouches.
  ///
  /// In de, this message translates to:
  /// **'Min. Bürgen'**
  String get wotMinVouches;

  /// No description provided for @wotDistrustThreshold.
  ///
  /// In de, this message translates to:
  /// **'Distrust-Schwelle'**
  String get wotDistrustThreshold;

  /// No description provided for @wotNotEnoughVouchers.
  ///
  /// In de, this message translates to:
  /// **'NOCH NICHT GENUG BÜRGEN'**
  String get wotNotEnoughVouchers;

  /// No description provided for @wotVouchers.
  ///
  /// In de, this message translates to:
  /// **'Bürgen'**
  String get wotVouchers;

  /// No description provided for @wotNoVouchersYet.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Bürgen'**
  String get wotNoVouchersYet;

  /// No description provided for @wotNobodyYet.
  ///
  /// In de, this message translates to:
  /// **'Noch niemand'**
  String get wotNobodyYet;

  /// No description provided for @wotNotSuspendedWatch.
  ///
  /// In de, this message translates to:
  /// **'Noch nicht suspendiert, aber du solltest aufpassen.'**
  String get wotNotSuspendedWatch;

  /// No description provided for @wotNoReports.
  ///
  /// In de, this message translates to:
  /// **'Keine Meldungen'**
  String get wotNoReports;

  /// No description provided for @wotNoActiveAdmins.
  ///
  /// In de, this message translates to:
  /// **'Keine aktiven Admins'**
  String get wotNoActiveAdmins;

  /// No description provided for @wotNoCleanNetwork.
  ///
  /// In de, this message translates to:
  /// **'Aktuell gibt es keine offenen Warnungen\nim Netzwerk. Alles sauber.'**
  String get wotNoCleanNetwork;

  /// No description provided for @wotNoOrganizersEnough.
  ///
  /// In de, this message translates to:
  /// **'Das Netzwerk hat noch keine Organisatoren mit genug Bürgschaften.'**
  String get wotNoOrganizersEnough;

  /// No description provided for @wotNoVouchesFound.
  ///
  /// In de, this message translates to:
  /// **'Keine publizierten Bürgschaften auf den Relays gefunden.'**
  String get wotNoVouchesFound;

  /// No description provided for @wotTapPlusFirst.
  ///
  /// In de, this message translates to:
  /// **'Tippe auf + um deinen ersten Ritterschlag\nzu vergeben.'**
  String get wotTapPlusFirst;

  /// No description provided for @wotAskOthersVouch.
  ///
  /// In de, this message translates to:
  /// **'Bitte andere Organisatoren, für dich zu bürgen.\n'**
  String get wotAskOthersVouch;

  /// No description provided for @wotNoDataLoaded.
  ///
  /// In de, this message translates to:
  /// **'Netzwerk-Daten konnten nicht geladen werden.\nZiehe zum Aktualisieren nach unten.'**
  String get wotNoDataLoaded;

  /// No description provided for @wotNoRelay.
  ///
  /// In de, this message translates to:
  /// **'Kein Relay erreichbar — später erneut versuchen.'**
  String get wotNoRelay;

  /// No description provided for @wotRevokeAllTitle.
  ///
  /// In de, this message translates to:
  /// **'ALLE BÜRGSCHAFTEN WIDERRUFEN?'**
  String get wotRevokeAllTitle;

  /// No description provided for @wotRevokeVouchTitle.
  ///
  /// In de, this message translates to:
  /// **'BÜRGSCHAFT ENTZIEHEN?'**
  String get wotRevokeVouchTitle;

  /// No description provided for @wotWithdrawVouch.
  ///
  /// In de, this message translates to:
  /// **'Bürgschaft entziehen'**
  String get wotWithdrawVouch;

  /// No description provided for @wotVouchWithdrawn.
  ///
  /// In de, this message translates to:
  /// **'Bürgschaft entzogen. Vergiss nicht zu publishen.'**
  String get wotVouchWithdrawn;

  /// No description provided for @wotVouchGiven.
  ///
  /// In de, this message translates to:
  /// **'Ritterschlag vergeben! Vergiss nicht zu publishen.'**
  String get wotVouchGiven;

  /// No description provided for @wotAllRevoked.
  ///
  /// In de, this message translates to:
  /// **'Alle Bürgschaften wurden im Netzwerk widerrufen.'**
  String get wotAllRevoked;

  /// No description provided for @wotReasonRequired.
  ///
  /// In de, this message translates to:
  /// **'Grund (Pflicht)'**
  String get wotReasonRequired;

  /// No description provided for @wotNpubRequired.
  ///
  /// In de, this message translates to:
  /// **'npub (Pflicht)'**
  String get wotNpubRequired;

  /// No description provided for @wotNameAlias.
  ///
  /// In de, this message translates to:
  /// **'Name / Alias (optional)'**
  String get wotNameAlias;

  /// No description provided for @wotMeetupExample.
  ///
  /// In de, this message translates to:
  /// **'Meetup (z.B. München)'**
  String get wotMeetupExample;

  /// No description provided for @wotReasonExample.
  ///
  /// In de, this message translates to:
  /// **'z.B. Fälscht Badges, kein echtes Meetup...'**
  String get wotReasonExample;

  /// No description provided for @wotNpubReasonRequired.
  ///
  /// In de, this message translates to:
  /// **'npub und Grund sind Pflicht.'**
  String get wotNpubReasonRequired;

  /// No description provided for @wotScanInstruction.
  ///
  /// In de, this message translates to:
  /// **'Scanne den Nostr-QR-Code (npub)\ndes Organisators.'**
  String get wotScanInstruction;

  /// No description provided for @wotVouchExplain.
  ///
  /// In de, this message translates to:
  /// **'Du bürgst mit deiner eigenen Reputation für diesen Organisator.'**
  String get wotVouchExplain;

  /// No description provided for @wotEachVouchPersonal.
  ///
  /// In de, this message translates to:
  /// **'Jede Bürgschaft ist dein persönliches Vertrauens-Votum — '**
  String get wotEachVouchPersonal;

  /// No description provided for @wotAfterPublishAll.
  ///
  /// In de, this message translates to:
  /// **'nach dem Publishen sieht das gesamte Netzwerk, für wen du stehst.'**
  String get wotAfterPublishAll;

  /// No description provided for @wotWhoYouVouchExplain.
  ///
  /// In de, this message translates to:
  /// **'Hier siehst du, für wen DU bürgst. '**
  String get wotWhoYouVouchExplain;

  /// No description provided for @wotPublishUpdated.
  ///
  /// In de, this message translates to:
  /// **'Publishe danach deine aktualisierte Liste, '**
  String get wotPublishUpdated;

  /// No description provided for @wotSoNetworkKnows.
  ///
  /// In de, this message translates to:
  /// **'damit das Netzwerk davon erfährt.'**
  String get wotSoNetworkKnows;

  /// No description provided for @wotSingleReportNoWeight.
  ///
  /// In de, this message translates to:
  /// **'Eine einzelne Meldung hat kein Gewicht — '**
  String get wotSingleReportNoWeight;

  /// No description provided for @wotOnlyMultipleIndep.
  ///
  /// In de, this message translates to:
  /// **'erst wenn mehrere unabhängige Organisatoren '**
  String get wotOnlyMultipleIndep;

  /// No description provided for @wotWarnSuspend.
  ///
  /// In de, this message translates to:
  /// **'warnen, wird jemand suspendiert. '**
  String get wotWarnSuspend;

  /// No description provided for @wotNobodyAlonePower.
  ///
  /// In de, this message translates to:
  /// **'Niemand hat allein Macht über andere.'**
  String get wotNobodyAlonePower;

  /// No description provided for @wotYourReportAlone.
  ///
  /// In de, this message translates to:
  /// **'Deine Meldung allein hat kein Gewicht. Erst wenn '**
  String get wotYourReportAlone;

  /// No description provided for @wotOrgsWarnSuspended.
  ///
  /// In de, this message translates to:
  /// **'Organisatoren warnen, wird der npub suspendiert.'**
  String get wotOrgsWarnSuspended;

  /// No description provided for @wotRevokeAllBody.
  ///
  /// In de, this message translates to:
  /// **'Dies publiziert eine leere Liste auf Nostr und widerruft damit ALLE '**
  String get wotRevokeAllBody;

  /// No description provided for @wotFromOtherOrgs.
  ///
  /// In de, this message translates to:
  /// **'von anderen Organisatoren.'**
  String get wotFromOtherOrgs;

  /// No description provided for @wotRestoreExplain.
  ///
  /// In de, this message translates to:
  /// **'Bürgschaften liegen signiert auf Nostr. „Wiederherstellen\" holt '**
  String get wotRestoreExplain;

  /// No description provided for @wotRestoreListBack.
  ///
  /// In de, this message translates to:
  /// **'deine Liste nach einer Neuinstallation oder einem Backup-Wechsel zurück.'**
  String get wotRestoreListBack;

  /// No description provided for @wotVouchesSignedOnNostr.
  ///
  /// In de, this message translates to:
  /// **'deine Bürgschaften im Netzwerk — auch solche, die lokal nicht mehr '**
  String get wotVouchesSignedOnNostr;

  /// No description provided for @wotVisibleLocally.
  ///
  /// In de, this message translates to:
  /// **'sichtbar sind.\n\nNutze das, wenn du nach einer Neuinstallation deine '**
  String get wotVisibleLocally;

  /// No description provided for @wotCantResolveOld.
  ///
  /// In de, this message translates to:
  /// **'alten Bürgschaften nicht mehr auflösen kannst.'**
  String get wotCantResolveOld;

  /// No description provided for @wotRemovedFromList.
  ///
  /// In de, this message translates to:
  /// **'wird von deiner Vouching-Liste entfernt.\n\n'**
  String get wotRemovedFromList;

  /// No description provided for @wotSuspendedByNetwork.
  ///
  /// In de, this message translates to:
  /// **'durch das Netzwerk suspendiert. Überprüfe deine Bürgschaften.'**
  String get wotSuspendedByNetwork;

  /// No description provided for @wotErrorLoading.
  ///
  /// In de, this message translates to:
  /// **'Fehler beim Laden: {msg}'**
  String wotErrorLoading(String msg);

  /// No description provided for @wotSyncFailed.
  ///
  /// In de, this message translates to:
  /// **'Sync fehlgeschlagen: {msg}'**
  String wotSyncFailed(String msg);

  /// No description provided for @wotRevocationFailed.
  ///
  /// In de, this message translates to:
  /// **'Widerruf fehlgeschlagen: {msg}'**
  String wotRevocationFailed(String msg);

  /// No description provided for @wotRestoreFailed.
  ///
  /// In de, this message translates to:
  /// **'Wiederherstellung fehlgeschlagen: {msg}'**
  String wotRestoreFailed(String msg);

  /// No description provided for @wotVouchesRestored.
  ///
  /// In de, this message translates to:
  /// **'{count} Bürgschaften von Nostr wiederhergestellt.'**
  String wotVouchesRestored(Object count);

  /// No description provided for @wotNetworkHealth.
  ///
  /// In de, this message translates to:
  /// **'NETZWERK {label}'**
  String wotNetworkHealth(String label);

  /// No description provided for @wotVouchProgress.
  ///
  /// In de, this message translates to:
  /// **'{count} / {total} Bürgen'**
  String wotVouchProgress(Object count, Object total);

  /// No description provided for @wotReportsCount.
  ///
  /// In de, this message translates to:
  /// **'{count} Meldungen'**
  String wotReportsCount(Object count);

  /// No description provided for @wotNeedMoreVouches.
  ///
  /// In de, this message translates to:
  /// **'Du brauchst noch {count} Bürgschaften '**
  String wotNeedMoreVouches(Object count);

  /// No description provided for @wotVouchesRequired.
  ///
  /// In de, this message translates to:
  /// **'{count} / {total} benötigt'**
  String wotVouchesRequired(Object count, Object total);

  /// No description provided for @wotSuspensionProgress.
  ///
  /// In de, this message translates to:
  /// **'{count} / {total} Suspendierung'**
  String wotSuspensionProgress(Object count, Object total);

  /// No description provided for @wotLiability.
  ///
  /// In de, this message translates to:
  /// **'HAFTUNG: {count} suspendiert'**
  String wotLiability(Object count);

  /// No description provided for @wotWarningCount.
  ///
  /// In de, this message translates to:
  /// **'WARNUNG: {count} gemeldet'**
  String wotWarningCount(Object count);

  /// No description provided for @wotYourNpub.
  ///
  /// In de, this message translates to:
  /// **'Dein npub: {npub}'**
  String wotYourNpub(String npub);

  /// No description provided for @wotLiabilityBody.
  ///
  /// In de, this message translates to:
  /// **'Du bürgst für {names} — diese npubs sind durch das Netzwerk suspendiert. Überprüfe deine Bürgschaften.'**
  String wotLiabilityBody(String names);

  /// No description provided for @wotWarningBody.
  ///
  /// In de, this message translates to:
  /// **'Für {names} gibt es Meldungen. '**
  String wotWarningBody(String names);

  /// No description provided for @wotVotes.
  ///
  /// In de, this message translates to:
  /// **'Stimmen'**
  String get wotVotes;

  /// No description provided for @wotSuspended.
  ///
  /// In de, this message translates to:
  /// **'Suspendiert'**
  String get wotSuspended;

  /// No description provided for @wotReportNoWeightThreshold.
  ///
  /// In de, this message translates to:
  /// **'Deine Meldung allein hat kein Gewicht. Erst wenn {count} unabhängige Organisatoren warnen, wird der npub suspendiert.'**
  String wotReportNoWeightThreshold(Object count);

  /// No description provided for @wotPublishedLive.
  ///
  /// In de, this message translates to:
  /// **'Dein Web of Trust ist live ({count} Relays)!'**
  String wotPublishedLive(Object count);

  /// No description provided for @wotReportPublished.
  ///
  /// In de, this message translates to:
  /// **'Meldung publiziert an {count} Relays.'**
  String wotReportPublished(Object count);

  /// No description provided for @wotErrorShort.
  ///
  /// In de, this message translates to:
  /// **'Fehler: {msg}'**
  String wotErrorShort(String msg);

  /// No description provided for @wotOffline.
  ///
  /// In de, this message translates to:
  /// **'Offline'**
  String get wotOffline;

  /// No description provided for @wotActive.
  ///
  /// In de, this message translates to:
  /// **'Aktive'**
  String get wotActive;

  /// No description provided for @wotPhase.
  ///
  /// In de, this message translates to:
  /// **'Phase'**
  String get wotPhase;

  /// No description provided for @wotPhaseDecentralized.
  ///
  /// In de, this message translates to:
  /// **'Dezentral'**
  String get wotPhaseDecentralized;

  /// No description provided for @wotPhaseBootstrap.
  ///
  /// In de, this message translates to:
  /// **'Bootstrap'**
  String get wotPhaseBootstrap;

  /// No description provided for @wotReportsLabel.
  ///
  /// In de, this message translates to:
  /// **'Meldungen'**
  String get wotReportsLabel;

  /// No description provided for @wotVouchersLabel.
  ///
  /// In de, this message translates to:
  /// **'BÜRGEN:'**
  String get wotVouchersLabel;

  /// No description provided for @writerTagTooSmall.
  ///
  /// In de, this message translates to:
  /// **'Tag zu klein! Daten: {data}B, Tag: {max}B.\n'**
  String writerTagTooSmall(Object data, Object max);

  /// No description provided for @writerTagWritten.
  ///
  /// In de, this message translates to:
  /// **'✅ MEETUP TAG geschrieben!\n\n'**
  String get writerTagWritten;

  /// No description provided for @writerCompactSize.
  ///
  /// In de, this message translates to:
  /// **'📦 {size}B (kompakt)\n'**
  String writerCompactSize(Object size);

  /// No description provided for @writerValidHours.
  ///
  /// In de, this message translates to:
  /// **'⏱️ Gültig für {hours}h\n\n'**
  String writerValidHours(Object hours);

  /// No description provided for @verifyErrNoNdef.
  ///
  /// In de, this message translates to:
  /// **'✗ Kein NDEF Tag'**
  String get verifyErrNoNdef;

  /// No description provided for @verifyErrTagEmpty.
  ///
  /// In de, this message translates to:
  /// **'✗ Tag ist leer'**
  String get verifyErrTagEmpty;

  /// No description provided for @verifyErrPayloadEmpty.
  ///
  /// In de, this message translates to:
  /// **'✗ Payload leer'**
  String get verifyErrPayloadEmpty;

  /// No description provided for @verifyErrInvalidFormat.
  ///
  /// In de, this message translates to:
  /// **'✗ Ungültiges Format'**
  String get verifyErrInvalidFormat;

  /// No description provided for @verifyErrInvalidTag.
  ///
  /// In de, this message translates to:
  /// **'✗ Ungültiger Tag: {msg}'**
  String verifyErrInvalidTag(String msg);

  /// No description provided for @verifyErrReadError.
  ///
  /// In de, this message translates to:
  /// **'✗ Lesefehler: {msg}'**
  String verifyErrReadError(String msg);

  /// No description provided for @verifyErrNfcError.
  ///
  /// In de, this message translates to:
  /// **'✗ NFC Fehler: {msg}'**
  String verifyErrNfcError(String msg);

  /// No description provided for @verifyErrQrExpired.
  ///
  /// In de, this message translates to:
  /// **'✗ QR-Code abgelaufen!\n{msg}\n\nBitte direkt am Bildschirm des Organisators scannen.'**
  String verifyErrQrExpired(String msg);

  /// No description provided for @verifyErrPrefix.
  ///
  /// In de, this message translates to:
  /// **'✗ {msg}'**
  String verifyErrPrefix(String msg);

  /// No description provided for @writerStartError.
  ///
  /// In de, this message translates to:
  /// **'❌ Start Fehler: {msg}'**
  String writerStartError(String msg);

  /// No description provided for @writerFitsNtag215.
  ///
  /// In de, this message translates to:
  /// **'~{size}B — passt auf NTAG215 (492B)'**
  String writerFitsNtag215(Object size);

  /// No description provided for @writerNoHomeMeetup.
  ///
  /// In de, this message translates to:
  /// **'⚠️ Kein Home-Meetup gesetzt'**
  String get writerNoHomeMeetup;

  /// No description provided for @writerHomeMeetupNotFound.
  ///
  /// In de, this message translates to:
  /// **'⚠️ Home-Meetup nicht gefunden'**
  String get writerHomeMeetupNotFound;

  /// No description provided for @writerNoActiveSession.
  ///
  /// In de, this message translates to:
  /// **'❌ Keine aktive Meetup-Session gefunden. Bitte starte das Meetup neu.'**
  String get writerNoActiveSession;

  /// No description provided for @admMyWebOfTrust.
  ///
  /// In de, this message translates to:
  /// **'MEIN WEB OF TRUST'**
  String get admMyWebOfTrust;

  /// No description provided for @admMyDelegations.
  ///
  /// In de, this message translates to:
  /// **'DEINE DELEGATIONEN'**
  String get admMyDelegations;

  /// No description provided for @admCoAdminKnight.
  ///
  /// In de, this message translates to:
  /// **'CO-ADMIN RITTERN'**
  String get admCoAdminKnight;

  /// No description provided for @admKnighthood.
  ///
  /// In de, this message translates to:
  /// **'RITTERSCHLAG'**
  String get admKnighthood;

  /// No description provided for @admRemove.
  ///
  /// In de, this message translates to:
  /// **'ENTFERNEN'**
  String get admRemove;

  /// No description provided for @admCancel.
  ///
  /// In de, this message translates to:
  /// **'ABBRECHEN'**
  String get admCancel;

  /// No description provided for @admRevokeTrust.
  ///
  /// In de, this message translates to:
  /// **'VERTRAUEN ENTZIEHEN?'**
  String get admRevokeTrust;

  /// No description provided for @admRevokeTrustShort.
  ///
  /// In de, this message translates to:
  /// **'Vertrauen entziehen'**
  String get admRevokeTrustShort;

  /// No description provided for @admSyncWot.
  ///
  /// In de, this message translates to:
  /// **'Web of Trust synchronisieren'**
  String get admSyncWot;

  /// No description provided for @admNobodyDelegated.
  ///
  /// In de, this message translates to:
  /// **'Du hast noch niemanden delegiert.'**
  String get admNobodyDelegated;

  /// No description provided for @admTapKnighthood.
  ///
  /// In de, this message translates to:
  /// **'Tippe unten auf \'RITTERSCHLAG\',\num einem neuen Organisator in deinem\nMeetup das Vertrauen auszusprechen.'**
  String get admTapKnighthood;

  /// No description provided for @admVouchNewExplain.
  ///
  /// In de, this message translates to:
  /// **'Du bürgst mit deiner eigenen Reputation für diesen neuen Organisator.'**
  String get admVouchNewExplain;

  /// No description provided for @admScanNewOrg.
  ///
  /// In de, this message translates to:
  /// **'Scanne den Nostr-QR-Code (npub) des neuen Organisators.'**
  String get admScanNewOrg;

  /// No description provided for @admNetworkLearnsKnight.
  ///
  /// In de, this message translates to:
  /// **'Das Netzwerk erfährt erst von deinen neuen Co-Admins,\nwenn du deine Signatur auf Nostr veröffentlichst.'**
  String get admNetworkLearnsKnight;

  /// No description provided for @admMustRepublish.
  ///
  /// In de, this message translates to:
  /// **'Du musst die Liste danach neu publishen, damit das Netzwerk davon erfährt.'**
  String get admMustRepublish;

  /// No description provided for @admPublishEmptyRevoke.
  ///
  /// In de, this message translates to:
  /// **'Publiziere eine leere Liste um alle Delegationen\nim Netzwerk zu widerrufen.'**
  String get admPublishEmptyRevoke;

  /// No description provided for @admRestoreListBack.
  ///
  /// In de, this message translates to:
  /// **'deine Liste nach einer Neuinstallation zurück.'**
  String get admRestoreListBack;

  /// No description provided for @admSigningSending.
  ///
  /// In de, this message translates to:
  /// **'Signiere und sende an Nostr...'**
  String get admSigningSending;

  /// No description provided for @admRestoringVouches.
  ///
  /// In de, this message translates to:
  /// **'Stelle meine Bürgschaften von Nostr wieder her...'**
  String get admRestoringVouches;

  /// No description provided for @admSyncingWot.
  ///
  /// In de, this message translates to:
  /// **'Synchronisiere Web of Trust...'**
  String get admSyncingWot;

  /// No description provided for @admRevokingAll.
  ///
  /// In de, this message translates to:
  /// **'Widerrufe alle Bürgschaften...'**
  String get admRevokingAll;

  /// No description provided for @admRevokeTrustBody.
  ///
  /// In de, this message translates to:
  /// **'Möchtest du {name} das Vertrauen als Admin für {meetup} entziehen?\n\n'**
  String admRevokeTrustBody(String name, String meetup);

  /// No description provided for @admRestoreExplain.
  ///
  /// In de, this message translates to:
  /// **'Bürgschaften liegen signiert auf Nostr. „Wiederherstellen\" holt '**
  String get admRestoreExplain;

  /// No description provided for @admVouchedCount.
  ///
  /// In de, this message translates to:
  /// **'Du hast dich für {count} Organisatoren verbürgt.'**
  String admVouchedCount(Object count);

  /// No description provided for @admCoAdminAdded.
  ///
  /// In de, this message translates to:
  /// **'✅ Co-Admin hinzugefügt! Vergiss nicht zu publishen.'**
  String get admCoAdminAdded;

  /// No description provided for @apMeetupSession.
  ///
  /// In de, this message translates to:
  /// **'MEETUP SESSION'**
  String get apMeetupSession;

  /// No description provided for @apSessionRunning.
  ///
  /// In de, this message translates to:
  /// **'SESSION LÄUFT'**
  String get apSessionRunning;

  /// No description provided for @apOpenActiveMeetup.
  ///
  /// In de, this message translates to:
  /// **'AKTIVES MEETUP ÖFFNEN'**
  String get apOpenActiveMeetup;

  /// No description provided for @apStartMeetup.
  ///
  /// In de, this message translates to:
  /// **'MEETUP STARTEN'**
  String get apStartMeetup;

  /// No description provided for @apEndMeetupEarly.
  ///
  /// In de, this message translates to:
  /// **'Meetup vorzeitig beenden'**
  String get apEndMeetupEarly;

  /// No description provided for @apNetwork.
  ///
  /// In de, this message translates to:
  /// **'NETZWERK'**
  String get apNetwork;

  /// No description provided for @apOrganizer.
  ///
  /// In de, this message translates to:
  /// **'ORGANISATOR'**
  String get apOrganizer;

  /// No description provided for @apWebOfTrust.
  ///
  /// In de, this message translates to:
  /// **'WEB OF TRUST'**
  String get apWebOfTrust;

  /// No description provided for @apHowItWorks.
  ///
  /// In de, this message translates to:
  /// **'SO FUNKTIONIERT\'S'**
  String get apHowItWorks;

  /// No description provided for @apManageVouches.
  ///
  /// In de, this message translates to:
  /// **'Bürgschaften verwalten, Netzwerk-Status, Meldungen'**
  String get apManageVouches;

  /// No description provided for @apNewMeetupQ.
  ///
  /// In de, this message translates to:
  /// **'Neues Meetup starten?'**
  String get apNewMeetupQ;

  /// No description provided for @apSessionEndQ.
  ///
  /// In de, this message translates to:
  /// **'Session beenden?'**
  String get apSessionEndQ;

  /// No description provided for @apCancel.
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get apCancel;

  /// No description provided for @apStart.
  ///
  /// In de, this message translates to:
  /// **'Starten'**
  String get apStart;

  /// No description provided for @apEnd.
  ///
  /// In de, this message translates to:
  /// **'Beenden'**
  String get apEnd;

  /// No description provided for @apSeedAdmin.
  ///
  /// In de, this message translates to:
  /// **'Seed Admin'**
  String get apSeedAdmin;

  /// No description provided for @apViaTrustScore.
  ///
  /// In de, this message translates to:
  /// **'Via Trust Score'**
  String get apViaTrustScore;

  /// No description provided for @apNewMeetupBody.
  ///
  /// In de, this message translates to:
  /// **'Dies erstellt eine eindeutige Signatur (Blockzeit) für die nächsten 6 Stunden. In dieser Zeit ist die Erstellung neuer Sessions gesperrt.'**
  String get apNewMeetupBody;

  /// No description provided for @apSessionEndBody.
  ///
  /// In de, this message translates to:
  /// **'Damit sperrst du die aktuelle Blockzeit. Du kannst danach eine neue Session starten.'**
  String get apSessionEndBody;

  /// No description provided for @apGeneratesProof.
  ///
  /// In de, this message translates to:
  /// **'Generiert einen neuen kryptographischen Beweis für die nächsten 6 Stunden.'**
  String get apGeneratesProof;

  /// No description provided for @humTitle.
  ///
  /// In de, this message translates to:
  /// **'PROOF OF HUMANITY'**
  String get humTitle;

  /// No description provided for @humVerified.
  ///
  /// In de, this message translates to:
  /// **'MENSCH VERIFIZIERT'**
  String get humVerified;

  /// No description provided for @humNotVerified.
  ///
  /// In de, this message translates to:
  /// **'NICHT VERIFIZIERT'**
  String get humNotVerified;

  /// No description provided for @humVerifiedSub.
  ///
  /// In de, this message translates to:
  /// **'Du bist als Mensch verifiziert'**
  String get humVerifiedSub;

  /// No description provided for @humLightningActive.
  ///
  /// In de, this message translates to:
  /// **'Lightning-Beweis aktiv'**
  String get humLightningActive;

  /// No description provided for @humCheckNow.
  ///
  /// In de, this message translates to:
  /// **'JETZT PRÜFEN'**
  String get humCheckNow;

  /// No description provided for @humCheckAgain.
  ///
  /// In de, this message translates to:
  /// **'ERNEUT PRÜFEN'**
  String get humCheckAgain;

  /// No description provided for @humCheckAgainShort.
  ///
  /// In de, this message translates to:
  /// **'Erneut prüfen'**
  String get humCheckAgainShort;

  /// No description provided for @humSearchingRelays.
  ///
  /// In de, this message translates to:
  /// **'SUCHE AUF RELAYS...'**
  String get humSearchingRelays;

  /// No description provided for @humHowTitle.
  ///
  /// In de, this message translates to:
  /// **'WIE FUNKTIONIERT DAS?'**
  String get humHowTitle;

  /// No description provided for @humIntro1.
  ///
  /// In de, this message translates to:
  /// **'Beweise, dass du ein Mensch bist — indem du nachweist, '**
  String get humIntro1;

  /// No description provided for @humIntro2.
  ///
  /// In de, this message translates to:
  /// **'dass du eine echte Lightning-Wallet besitzt und '**
  String get humIntro2;

  /// No description provided for @humIntro3.
  ///
  /// In de, this message translates to:
  /// **'schon einmal jemanden auf Nostr gezappt hast.'**
  String get humIntro3;

  /// No description provided for @humExplain1.
  ///
  /// In de, this message translates to:
  /// **'Bots haben keine Lightning-Wallets. Eine einzige echte '**
  String get humExplain1;

  /// No description provided for @humExplain2.
  ///
  /// In de, this message translates to:
  /// **'Zahlung beweist, dass du ein Mensch mit einer echten '**
  String get humExplain2;

  /// No description provided for @humExplain3.
  ///
  /// In de, this message translates to:
  /// **'Wallet bist — ohne persönliche Daten preiszugeben.'**
  String get humExplain3;

  /// No description provided for @humStep1.
  ///
  /// In de, this message translates to:
  /// **'Du zappst irgendjemanden auf Nostr'**
  String get humStep1;

  /// No description provided for @humStep2.
  ///
  /// In de, this message translates to:
  /// **'Der Zap erzeugt ein Receipt auf Relays'**
  String get humStep2;

  /// No description provided for @humStep3.
  ///
  /// In de, this message translates to:
  /// **'Die App findet dein Receipt'**
  String get humStep3;

  /// No description provided for @humStepInstruction.
  ///
  /// In de, this message translates to:
  /// **'Egal wen, egal wieviel Sats. Nutze dafür einen Nostr-Client wie Damus, Amethyst oder Primal.'**
  String get humStepInstruction;

  /// No description provided for @humCheckInstruction.
  ///
  /// In de, this message translates to:
  /// **'Drücke den Prüfen-Button und die App sucht auf Nostr-Relays nach deinem Zap.'**
  String get humCheckInstruction;

  /// No description provided for @humZapReturn.
  ///
  /// In de, this message translates to:
  /// **'Zappe irgendjemanden und komm zurück'**
  String get humZapReturn;

  /// No description provided for @humCryptoProof.
  ///
  /// In de, this message translates to:
  /// **'Das ist ein kryptographischer Beweis, dass du eine echte Lightning-Zahlung geleistet hast.'**
  String get humCryptoProof;

  /// No description provided for @humProofInEvent1.
  ///
  /// In de, this message translates to:
  /// **'auf dem Nostr-Netzwerk geleistet. Dieser Beweis ist in deinem '**
  String get humProofInEvent1;

  /// No description provided for @humProofPrivacy.
  ///
  /// In de, this message translates to:
  /// **'Der Beweis wird in dein Reputation-Event aufgenommen. Kein Betrag oder Empfänger wird gespeichert.'**
  String get humProofPrivacy;

  /// No description provided for @humReputationSaved.
  ///
  /// In de, this message translates to:
  /// **'Reputation-Event gespeichert.'**
  String get humReputationSaved;

  /// No description provided for @humPaidOn.
  ///
  /// In de, this message translates to:
  /// **'Du hast am {date} eine Lightning-Zahlung '**
  String humPaidOn(String date);

  /// No description provided for @humLastCheck.
  ///
  /// In de, this message translates to:
  /// **'Letzte Prüfung: {time}'**
  String humLastCheck(String time);

  /// No description provided for @ppTitle.
  ///
  /// In de, this message translates to:
  /// **'PLATTFORM-VERKNÜPFUNG'**
  String get ppTitle;

  /// No description provided for @ppPlatform.
  ///
  /// In de, this message translates to:
  /// **'PLATTFORM'**
  String get ppPlatform;

  /// No description provided for @ppUsername.
  ///
  /// In de, this message translates to:
  /// **'BENUTZERNAME'**
  String get ppUsername;

  /// No description provided for @ppActiveLinks.
  ///
  /// In de, this message translates to:
  /// **'AKTIVE VERKNÜPFUNGEN'**
  String get ppActiveLinks;

  /// No description provided for @ppLinkPlatform.
  ///
  /// In de, this message translates to:
  /// **'PLATTFORM VERKNÜPFEN'**
  String get ppLinkPlatform;

  /// No description provided for @ppCreateLink.
  ///
  /// In de, this message translates to:
  /// **'VERKNÜPFUNG ERSTELLEN'**
  String get ppCreateLink;

  /// No description provided for @ppAnotherPlatform.
  ///
  /// In de, this message translates to:
  /// **'WEITERE PLATTFORM'**
  String get ppAnotherPlatform;

  /// No description provided for @ppShareOnPlatform.
  ///
  /// In de, this message translates to:
  /// **'AUF PLATTFORM TEILEN'**
  String get ppShareOnPlatform;

  /// No description provided for @ppUnlinkQ.
  ///
  /// In de, this message translates to:
  /// **'VERKNÜPFUNG AUFHEBEN?'**
  String get ppUnlinkQ;

  /// No description provided for @ppRevoke.
  ///
  /// In de, this message translates to:
  /// **'WIDERRUFEN'**
  String get ppRevoke;

  /// No description provided for @ppCancel.
  ///
  /// In de, this message translates to:
  /// **'ABBRECHEN'**
  String get ppCancel;

  /// No description provided for @ppYourUsername.
  ///
  /// In de, this message translates to:
  /// **'Dein Benutzername'**
  String get ppYourUsername;

  /// No description provided for @ppPlatformName.
  ///
  /// In de, this message translates to:
  /// **'Name der Plattform'**
  String get ppPlatformName;

  /// No description provided for @ppIntro.
  ///
  /// In de, this message translates to:
  /// **'Verknüpfe deinen Account mit einer Plattform. Der Beweis wird automatisch in deinen Reputation-QR eingebettet.'**
  String get ppIntro;

  /// No description provided for @ppLinkSaved.
  ///
  /// In de, this message translates to:
  /// **'Verknüpfung gespeichert! Wird automatisch in deinen Reputation-QR eingebettet.'**
  String get ppLinkSaved;

  /// No description provided for @ppMustUpdate.
  ///
  /// In de, this message translates to:
  /// **'Du musst dein Reputation-Event danach aktualisieren.'**
  String get ppMustUpdate;

  /// No description provided for @ppUnlinkBody1.
  ///
  /// In de, this message translates to:
  /// **'Die Plattform-Verknüpfung für \"'**
  String get ppUnlinkBody1;

  /// No description provided for @ppUnlinkBody2.
  ///
  /// In de, this message translates to:
  /// **'wird gelöscht.\n\n'**
  String get ppUnlinkBody2;

  /// No description provided for @ppUnlinkBody.
  ///
  /// In de, this message translates to:
  /// **'Die Plattform-Verknüpfung für \"{username}\" auf {platform} wird gelöscht.\n\nDu musst dein Reputation-Event danach aktualisieren.'**
  String ppUnlinkBody(String username, String platform);

  /// No description provided for @ppCreated.
  ///
  /// In de, this message translates to:
  /// **'Erstellt: {date}'**
  String ppCreated(String date);

  /// No description provided for @ppRevokeTooltip.
  ///
  /// In de, this message translates to:
  /// **'Widerrufen'**
  String get ppRevokeTooltip;

  /// No description provided for @rqTitle.
  ///
  /// In de, this message translates to:
  /// **'MEETUP QR-CODE'**
  String get rqTitle;

  /// No description provided for @rqActive.
  ///
  /// In de, this message translates to:
  /// **'AKTIV'**
  String get rqActive;

  /// No description provided for @rqCodeRenewing.
  ///
  /// In de, this message translates to:
  /// **'Code erneuert sich...'**
  String get rqCodeRenewing;

  /// No description provided for @rqNextCodeIn.
  ///
  /// In de, this message translates to:
  /// **'Nächster Code in'**
  String get rqNextCodeIn;

  /// No description provided for @rqEndSession.
  ///
  /// In de, this message translates to:
  /// **'Session beenden'**
  String get rqEndSession;

  /// No description provided for @rqEndSessionQ.
  ///
  /// In de, this message translates to:
  /// **'Session beenden?'**
  String get rqEndSessionQ;

  /// No description provided for @rqEnd.
  ///
  /// In de, this message translates to:
  /// **'BEENDEN'**
  String get rqEnd;

  /// No description provided for @rqEndSessionBody.
  ///
  /// In de, this message translates to:
  /// **'Eine beendete Session sperrt diese Blockzeit. Du kannst danach eine neue Session starten.'**
  String get rqEndSessionBody;

  /// No description provided for @rqNoActiveSession.
  ///
  /// In de, this message translates to:
  /// **'KEINE AKTIVE SESSION'**
  String get rqNoActiveSession;

  /// No description provided for @rqNoSessionBody.
  ///
  /// In de, this message translates to:
  /// **'Es läuft aktuell keine Meetup-Session.\nBitte starte das Meetup im Admin Panel neu.'**
  String get rqNoSessionBody;

  /// No description provided for @rqBackToAdmin.
  ///
  /// In de, this message translates to:
  /// **'ZURÜCK ZUM ADMIN PANEL'**
  String get rqBackToAdmin;

  /// No description provided for @rsTitle.
  ///
  /// In de, this message translates to:
  /// **'NOSTR-RELAYS'**
  String get rsTitle;

  /// No description provided for @rsDefaultRelays.
  ///
  /// In de, this message translates to:
  /// **'DEFAULT-RELAYS'**
  String get rsDefaultRelays;

  /// No description provided for @rsCustomRelays.
  ///
  /// In de, this message translates to:
  /// **'EIGENE RELAYS'**
  String get rsCustomRelays;

  /// No description provided for @rsAddRelay.
  ///
  /// In de, this message translates to:
  /// **'RELAY HINZUFÜGEN'**
  String get rsAddRelay;

  /// No description provided for @rsAdd.
  ///
  /// In de, this message translates to:
  /// **'HINZUFÜGEN'**
  String get rsAdd;

  /// No description provided for @rsNoRelaysActive.
  ///
  /// In de, this message translates to:
  /// **'Keine Relays aktiv!'**
  String get rsNoRelaysActive;

  /// No description provided for @rsNoCustomRelays.
  ///
  /// In de, this message translates to:
  /// **'Keine eigenen Relays konfiguriert.'**
  String get rsNoCustomRelays;

  /// No description provided for @rsAllRelaysInfo.
  ///
  /// In de, this message translates to:
  /// **'Die App nutzt alle aktiven Relays gleichzeitig für maximale Erreichbarkeit.'**
  String get rsAllRelaysInfo;

  /// No description provided for @rsRelaysIntro.
  ///
  /// In de, this message translates to:
  /// **'Relays verteilen deine Reputation im Nostr-Netzwerk. '**
  String get rsRelaysIntro;

  /// No description provided for @rsRelayPlaceholder.
  ///
  /// In de, this message translates to:
  /// **'wss://mein-relay.de'**
  String get rsRelayPlaceholder;

  /// No description provided for @rdScanAdminTag.
  ///
  /// In de, this message translates to:
  /// **'ADMIN TAG SCANNEN'**
  String get rdScanAdminTag;

  /// No description provided for @rdAnon.
  ///
  /// In de, this message translates to:
  /// **'ANON'**
  String get rdAnon;

  /// No description provided for @rdCollectBadge.
  ///
  /// In de, this message translates to:
  /// **'BADGE ABHOLEN'**
  String get rdCollectBadge;

  /// No description provided for @rdYourReputation.
  ///
  /// In de, this message translates to:
  /// **'DEINE REPUTATION'**
  String get rdYourReputation;

  /// No description provided for @rdEditIdentity.
  ///
  /// In de, this message translates to:
  /// **'Identität bearbeiten'**
  String get rdEditIdentity;

  /// No description provided for @rdLinkingIdentity.
  ///
  /// In de, this message translates to:
  /// **'Identität verknüpfen...'**
  String get rdLinkingIdentity;

  /// No description provided for @rdNostrVerified.
  ///
  /// In de, this message translates to:
  /// **'NOSTR VERIFIED'**
  String get rdNostrVerified;

  /// No description provided for @rdNoBadges.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Badges gesammelt.\nGeh zu einem Meetup!'**
  String get rdNoBadges;

  /// No description provided for @rdSelfSovereign.
  ///
  /// In de, this message translates to:
  /// **'Self-Sovereign: Diese App läuft ohne Server. Deine Badges gehören nur dir und sind auf diesem Gerät gespeichert.'**
  String get rdSelfSovereign;

  /// No description provided for @rdVerifiedByAdmin.
  ///
  /// In de, this message translates to:
  /// **'VERIFIZIERT DURCH ADMIN'**
  String get rdVerifiedByAdmin;

  /// No description provided for @rqRemainingTime.
  ///
  /// In de, this message translates to:
  /// **'Restzeit: {time}\n\n'**
  String rqRemainingTime(String time);

  /// No description provided for @rqSessionRemaining.
  ///
  /// In de, this message translates to:
  /// **'Session: {time}'**
  String rqSessionRemaining(String time);

  /// No description provided for @rvTitle.
  ///
  /// In de, this message translates to:
  /// **'REPUTATION PRÜFEN'**
  String get rvTitle;

  /// No description provided for @rvChecking.
  ///
  /// In de, this message translates to:
  /// **'PRÜFE...'**
  String get rvChecking;

  /// No description provided for @rvFullyVerified.
  ///
  /// In de, this message translates to:
  /// **'VOLLSTÄNDIG VERIFIZIERT'**
  String get rvFullyVerified;

  /// No description provided for @rvPartiallyVerified.
  ///
  /// In de, this message translates to:
  /// **'TEILWEISE VERIFIZIERT'**
  String get rvPartiallyVerified;

  /// No description provided for @rvSignatureOnly.
  ///
  /// In de, this message translates to:
  /// **'NUR SIGNATUR GEPRÜFT'**
  String get rvSignatureOnly;

  /// No description provided for @rvInvalid.
  ///
  /// In de, this message translates to:
  /// **'UNGÜLTIG'**
  String get rvInvalid;

  /// No description provided for @rvConfirmedInEvent.
  ///
  /// In de, this message translates to:
  /// **'Im Event bestätigt'**
  String get rvConfirmedInEvent;

  /// No description provided for @rvPlatformProof.
  ///
  /// In de, this message translates to:
  /// **'Plattform-Proof'**
  String get rvPlatformProof;

  /// No description provided for @rvIntro1.
  ///
  /// In de, this message translates to:
  /// **'Füge den Verify-String oder npub einer Person ein, '**
  String get rvIntro1;

  /// No description provided for @rvIntro2.
  ///
  /// In de, this message translates to:
  /// **'um ihre Reputation über alle Beweis-Layer zu prüfen.'**
  String get rvIntro2;

  /// No description provided for @rvCheckingSignature.
  ///
  /// In de, this message translates to:
  /// **'Prüfe Signatur...'**
  String get rvCheckingSignature;

  /// No description provided for @rvCheckingNostr.
  ///
  /// In de, this message translates to:
  /// **'Analysiere Nostr-Netzwerk...'**
  String get rvCheckingNostr;

  /// No description provided for @rvCheckingLightning.
  ///
  /// In de, this message translates to:
  /// **'Prüfe Lightning-Aktivität...'**
  String get rvCheckingLightning;

  /// No description provided for @rvCheckingNip05.
  ///
  /// In de, this message translates to:
  /// **'Prüfe NIP-05...'**
  String get rvCheckingNip05;

  /// No description provided for @msSelectMeetup.
  ///
  /// In de, this message translates to:
  /// **'MEETUP AUSWÄHLEN'**
  String get msSelectMeetup;

  /// No description provided for @msSearchMeetup.
  ///
  /// In de, this message translates to:
  /// **'Meetup suchen...'**
  String get msSearchMeetup;

  /// No description provided for @mlTitle.
  ///
  /// In de, this message translates to:
  /// **'MEETUPS'**
  String get mlTitle;

  /// No description provided for @mlRetry.
  ///
  /// In de, this message translates to:
  /// **'Erneut versuchen'**
  String get mlRetry;

  /// No description provided for @mlLoadError.
  ///
  /// In de, this message translates to:
  /// **'Fehler beim Laden'**
  String get mlLoadError;

  /// No description provided for @mlNoMeetupsFound.
  ///
  /// In de, this message translates to:
  /// **'Keine Meetups gefunden.'**
  String get mlNoMeetupsFound;

  /// No description provided for @mlNoMeetupFor.
  ///
  /// In de, this message translates to:
  /// **'Kein Meetup für \"{query}\"'**
  String mlNoMeetupFor(String query);

  /// No description provided for @cmRequestSent.
  ///
  /// In de, this message translates to:
  /// **'ANFRAGE GESENDET 🚀'**
  String get cmRequestSent;

  /// No description provided for @cmDateTime.
  ///
  /// In de, this message translates to:
  /// **'DATUM & UHRZEIT'**
  String get cmDateTime;

  /// No description provided for @cmFoundBase.
  ///
  /// In de, this message translates to:
  /// **'GRÜNDE EINE BASIS.'**
  String get cmFoundBase;

  /// No description provided for @cmLocation.
  ///
  /// In de, this message translates to:
  /// **'LOCATION / ORT'**
  String get cmLocation;

  /// No description provided for @cmCityName.
  ///
  /// In de, this message translates to:
  /// **'NAME DER STADT'**
  String get cmCityName;

  /// No description provided for @cmTelegramGroup.
  ///
  /// In de, this message translates to:
  /// **'TELEGRAM GRUPPE (OPTIONAL)'**
  String get cmTelegramGroup;

  /// No description provided for @cmNewMeetup.
  ///
  /// In de, this message translates to:
  /// **'NEUES MEETUP'**
  String get cmNewMeetup;

  /// No description provided for @cmDateExample.
  ///
  /// In de, this message translates to:
  /// **'z.B. 21. Mai, 19:00'**
  String get cmDateExample;

  /// No description provided for @cmCityExample.
  ///
  /// In de, this message translates to:
  /// **'z.B. Frankfurt'**
  String get cmCityExample;

  /// No description provided for @cmLocationExample.
  ///
  /// In de, this message translates to:
  /// **'z.B. Room 77'**
  String get cmLocationExample;

  /// No description provided for @evUpcomingEvents.
  ///
  /// In de, this message translates to:
  /// **'KOMMENDE EVENTS'**
  String get evUpcomingEvents;

  /// No description provided for @evDatesEvents.
  ///
  /// In de, this message translates to:
  /// **'TERMINE & EVENTS'**
  String get evDatesEvents;

  /// No description provided for @evNoMeetupsFound.
  ///
  /// In de, this message translates to:
  /// **'Keine Meetups gefunden'**
  String get evNoMeetupsFound;

  /// No description provided for @evSearchCityCountry.
  ///
  /// In de, this message translates to:
  /// **'Stadt oder Land suchen...'**
  String get evSearchCityCountry;

  /// No description provided for @evIntro.
  ///
  /// In de, this message translates to:
  /// **'Die meisten Einundzwanzig Meetups finden regelmäßig statt. Klick auf ein Meetup für mehr Infos und Termine.'**
  String get evIntro;

  /// No description provided for @rvLabelPlatform.
  ///
  /// In de, this message translates to:
  /// **'Plattform'**
  String get rvLabelPlatform;

  /// No description provided for @rvLabelUsername.
  ///
  /// In de, this message translates to:
  /// **'Username'**
  String get rvLabelUsername;

  /// No description provided for @countryDE.
  ///
  /// In de, this message translates to:
  /// **'Deutschland'**
  String get countryDE;

  /// No description provided for @countryAT.
  ///
  /// In de, this message translates to:
  /// **'Österreich'**
  String get countryAT;

  /// No description provided for @countryCH.
  ///
  /// In de, this message translates to:
  /// **'Schweiz'**
  String get countryCH;

  /// No description provided for @countryES.
  ///
  /// In de, this message translates to:
  /// **'Spanien'**
  String get countryES;

  /// No description provided for @countryNL.
  ///
  /// In de, this message translates to:
  /// **'Niederlande'**
  String get countryNL;

  /// No description provided for @countryIT.
  ///
  /// In de, this message translates to:
  /// **'Italien'**
  String get countryIT;

  /// No description provided for @countryFR.
  ///
  /// In de, this message translates to:
  /// **'Frankreich'**
  String get countryFR;
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
