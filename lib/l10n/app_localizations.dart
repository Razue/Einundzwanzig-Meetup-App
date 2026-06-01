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
