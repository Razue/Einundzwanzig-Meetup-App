// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Einundzwanzig Meetup';

  @override
  String get navHome => 'Home';

  @override
  String get navWallet => 'Wallet';

  @override
  String get navEvents => 'Events';

  @override
  String get navProfile => 'Profil';

  @override
  String get actionSave => 'Speichern';

  @override
  String get actionCancel => 'Abbrechen';

  @override
  String get actionConfirm => 'Bestätigen';

  @override
  String get actionDelete => 'Löschen';

  @override
  String get actionContinue => 'Weiter';

  @override
  String get actionBack => 'Zurück';

  @override
  String get actionClose => 'Schließen';

  @override
  String get actionRetry => 'Erneut versuchen';

  @override
  String get actionOk => 'OK';

  @override
  String get actionUnderstood => 'Verstanden';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsLanguage => 'Sprache';

  @override
  String get settingsLanguageSystem => 'System';

  @override
  String get trustScore => 'Trust Score';

  @override
  String get reputation => 'Reputation';

  @override
  String get reputationShareQr => 'QR teilen';

  @override
  String get community => 'Community';

  @override
  String get communityPortal => 'Portal';

  @override
  String get homeMeetup => 'Home Meetup';

  @override
  String get shoutout => 'Shoutout';

  @override
  String get joinCommunity => 'Community betreten';

  @override
  String get identityVerified => 'Verifiziert';

  @override
  String get verifiedByAdmin => 'Verifiziert durch Admin';

  @override
  String get nostrVerified => 'Nostr verifiziert';

  @override
  String get profileNickname => 'Nickname';

  @override
  String get profileChooseHomeMeetup => 'Wähle dein Home-Meetup';

  @override
  String get profileYourIdentity => 'Deine Identität';

  @override
  String get profileNostrKey => 'Nostr Schlüssel';

  @override
  String get profileKeyActive => 'Schlüssel aktiv';

  @override
  String get requiredField => 'Pflichtfeld — bitte ausfüllen';

  @override
  String get requiredHomeMeetup => 'Pflichtfeld — bitte wähle dein Home-Meetup';

  @override
  String fillRequired(String fields) {
    return 'Bitte ausfüllen: $fields';
  }

  @override
  String get identityGenerateKey => 'Neuen Schlüssel erstellen';

  @override
  String get identityConnectAmber => 'Mit Amber verbinden';

  @override
  String get identityImportNsec => 'Bestehenden nsec importieren';

  @override
  String get amberConnected =>
      'Mit Amber verbunden! Dein nsec bleibt in Amber.';

  @override
  String get amberNotFound => 'Amber nicht gefunden';

  @override
  String get amberCancelled => 'Verbindung in Amber abgebrochen.';

  @override
  String get walletTitle => 'Badge Wallet';

  @override
  String badgesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Badges',
      one: '1 Badge',
      zero: 'Keine Badges',
    );
    return '$_temp0';
  }

  @override
  String eventInDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days Tagen',
      one: '1 Tag',
      zero: 'heute',
    );
    return 'in $_temp0';
  }
}
