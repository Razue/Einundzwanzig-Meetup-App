// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Einundzwanzig Meetup';

  @override
  String get navHome => 'Home';

  @override
  String get navWallet => 'Wallet';

  @override
  String get navEvents => 'Events';

  @override
  String get navProfile => 'Profile';

  @override
  String get actionSave => 'Save';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionConfirm => 'Confirm';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionContinue => 'Continue';

  @override
  String get actionBack => 'Back';

  @override
  String get actionClose => 'Close';

  @override
  String get actionRetry => 'Try again';

  @override
  String get actionOk => 'OK';

  @override
  String get actionUnderstood => 'Got it';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSystem => 'System';

  @override
  String get trustScore => 'Trust Score';

  @override
  String get reputation => 'Reputation';

  @override
  String get reputationShareQr => 'Share QR';

  @override
  String get community => 'Community';

  @override
  String get communityPortal => 'Portal';

  @override
  String get homeMeetup => 'Home Meetup';

  @override
  String get shoutout => 'Shoutout';

  @override
  String get joinCommunity => 'Join the community';

  @override
  String get identityVerified => 'Verified';

  @override
  String get verifiedByAdmin => 'Verified by admin';

  @override
  String get nostrVerified => 'Nostr verified';

  @override
  String get profileNickname => 'Nickname';

  @override
  String get profileChooseHomeMeetup => 'Choose your home meetup';

  @override
  String get profileYourIdentity => 'Your identity';

  @override
  String get profileNostrKey => 'Nostr key';

  @override
  String get profileKeyActive => 'Key active';

  @override
  String get requiredField => 'Required — please fill in';

  @override
  String get requiredHomeMeetup => 'Required — please choose your home meetup';

  @override
  String fillRequired(String fields) {
    return 'Please fill in: $fields';
  }

  @override
  String get identityGenerateKey => 'Create a new key';

  @override
  String get identityConnectAmber => 'Connect with Amber';

  @override
  String get identityImportNsec => 'Import existing nsec';

  @override
  String get amberConnected =>
      'Connected with Amber! Your nsec stays in Amber.';

  @override
  String get amberNotFound => 'Amber not found';

  @override
  String get amberCancelled => 'Connection cancelled in Amber.';

  @override
  String get walletTitle => 'Badge Wallet';

  @override
  String badgesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count badges',
      one: '1 badge',
      zero: 'No badges',
    );
    return '$_temp0';
  }

  @override
  String eventInDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
      zero: 'today',
    );
    return 'in $_temp0';
  }
}
