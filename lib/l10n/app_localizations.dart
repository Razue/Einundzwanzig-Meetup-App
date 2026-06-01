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
