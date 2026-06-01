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

  @override
  String get tileTrustScore => 'Trust Score';

  @override
  String get tileReputation => 'Reputation';

  @override
  String get tileReputationShare => 'Share QR';

  @override
  String get tileReputationCheck => 'Check';

  @override
  String get tileCommunity => 'Community';

  @override
  String get tileCommunityPortal => 'Portal';

  @override
  String get tileEvents => 'Events';

  @override
  String get tileEventsCalendar => 'Calendar';

  @override
  String get tileShoutout => 'Shoutout';

  @override
  String get tileShoutoutSend => 'Send';

  @override
  String get tilePodcast => 'Podcast';

  @override
  String get tilePodcastListen => 'Listen';

  @override
  String get tileNostr => 'Nostr';

  @override
  String get tileNostrCommunity => 'Community';

  @override
  String get tileOrganizer => 'Organizer';

  @override
  String get tileOrganizerPanel => 'Admin panel';

  @override
  String get tileOrganizerNew => 'New via Trust Score';

  @override
  String get tileWot => 'WoT';

  @override
  String get tileWotSubtitle => 'Web of Trust';

  @override
  String get homeMeetupLabel => 'HOME MEETUP';

  @override
  String get homeMeetupChoose => 'Choose your meetup';

  @override
  String get homeMeetupChooseSub => 'Select your regular meetup';

  @override
  String homeMeetupBadges(int count) {
    return '$count badges';
  }

  @override
  String get homeMeetupToday => 'Today!';

  @override
  String get homeMeetupTomorrow => 'Tomorrow';

  @override
  String homeMeetupInDays(int days) {
    return 'in $days days';
  }

  @override
  String get homeMeetupNoDate => 'No date scheduled';

  @override
  String get homeMeetupNextEvent => 'Next meetup';

  @override
  String get homeMeetupNoneSoon => 'No date in sight.\nTime to change that!';

  @override
  String get homeMeetupSelectFirst => 'Choose home meetup\nfirst!';

  @override
  String get btnEvents => 'EVENTS';

  @override
  String get statusLive => 'LIVE';

  @override
  String get statusMeetupActive => 'Meetup active';

  @override
  String get loading => 'Loading...';

  @override
  String get organizerPromoted => 'You are now an ORGANIZER!';

  @override
  String get resetTitle => 'Reset app?';

  @override
  String get resetBody => 'All badges and your profile will be deleted.';

  @override
  String get resetCancel => 'Cancel';

  @override
  String get resetConfirm => 'DELETE';

  @override
  String get settingsSectionBackup => 'BACKUP';

  @override
  String get settingsSectionLanguage => 'LANGUAGE';

  @override
  String get settingsSectionNostr => 'NOSTR NETWORK';

  @override
  String get settingsSectionControl => 'CONTROLS';

  @override
  String get settingsSectionAccount => 'ACCOUNT';

  @override
  String get settingsBackup => 'Create backup';

  @override
  String get settingsBackupSub => 'Secure your account';

  @override
  String get settingsLanguageTitle => 'Language';

  @override
  String get settingsLanguageChoose => 'Choose language';

  @override
  String get settingsRelays => 'Nostr relays';

  @override
  String get settingsRelaysSub => 'Configure relays';

  @override
  String get settingsHaptic => 'Haptic feedback';

  @override
  String get settingsHapticOn => 'On';

  @override
  String get settingsHapticOff => 'Off';

  @override
  String get settingsReset => 'Reset app';

  @override
  String get settingsResetSub => 'Deletes profile and badges';
}
