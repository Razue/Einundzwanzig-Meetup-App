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
  String get profileNostrKey => 'NOSTR KEY';

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

  @override
  String get introTagline => 'YOUR BITCOIN COMMUNITY';

  @override
  String get introJoin => 'JOIN COMMUNITY';

  @override
  String get introLoadBackup => 'LOAD BACKUP';

  @override
  String get introSetIdentity => 'Please set up your identity first.';

  @override
  String get navWalletTab => 'Wallet';

  @override
  String get navProfileTab => 'Profile';

  @override
  String get scanBadge => 'Scan badge';

  @override
  String get scanBadgeSub => 'QR code or NFC tag from the meetup';

  @override
  String get scanReputation => 'Check reputation';

  @override
  String get scanReputationSub => 'Verify another person\'s Trust Score';

  @override
  String get calendarTitle => 'MEETUP EVENTS';

  @override
  String get calendarSearch => 'Search (e.g. Munich, Bitcoin...)';

  @override
  String get calendarNoEvents => 'No events found.';

  @override
  String get sectionDescription => 'DESCRIPTION';

  @override
  String get sectionLocation => 'LOCATION';

  @override
  String get sectionDates => 'DATES';

  @override
  String get sectionLinks => 'LINKS';

  @override
  String get meetupRoute => 'Route';

  @override
  String get meetupNoDatesCal => 'No dates in the calendar right now.';

  @override
  String get errorOpenLink => 'Couldn\'t open link';

  @override
  String get walletNoBadges => 'No badges collected yet';

  @override
  String get walletNoBadgesSub =>
      'Visit meetups and scan NFC tags to collect badges!';

  @override
  String get walletShareReputation => 'SHARE REPUTATION';

  @override
  String get walletShowQr => 'Show QR code';

  @override
  String get walletShowQrSub => 'For scanning on site';

  @override
  String get walletExportJson => 'Export as JSON';

  @override
  String get walletExportJsonSub => 'Signed export with Schnorr proof';

  @override
  String get walletShareText => 'Share as text';

  @override
  String get walletShareTextSub => 'Readable by anyone (copied on the web)';

  @override
  String get walletShareTitle => 'Share reputation';

  @override
  String get walletJsonCopied => 'JSON data copied to clipboard';

  @override
  String get walletReputationCopied => 'Reputation copied to clipboard';

  @override
  String get cancel => 'Cancel';

  @override
  String get badgeDetailsTitle => 'Badge details';

  @override
  String get badgeShare => 'Share badge';

  @override
  String get badgeShareCaps => 'SHARE BADGE';

  @override
  String get badgeClose => 'CLOSE';

  @override
  String get badgeProofTitle => 'Cryptographic proof';

  @override
  String get badgeProofOfAttendance => 'PROOF OF ATTENDANCE';

  @override
  String get badgeProofDesc =>
      'This badge cryptographically confirms you were physically present.';

  @override
  String get badgeMeetup => 'Meetup';

  @override
  String get badgeMeetupDate => 'Meetup date';

  @override
  String get badgeMeetupId => 'Meetup ID';

  @override
  String get badgeOrganizerNpub => 'Organizer (npub)';

  @override
  String get badgeSignatureType => 'Signature type';

  @override
  String get badgeTransmission => 'Transmission';

  @override
  String get badgeTimestamp => 'Timestamp';

  @override
  String get badgeScanTime => 'Scan time';

  @override
  String get badgeVerificationHash => 'VERIFICATION HASH';

  @override
  String get badgeClaimBinding => 'Claim binding';

  @override
  String get badgeBound => 'Bound ✓';

  @override
  String get badgeNotBound => 'Not bound';

  @override
  String get badgeClaimedLater => 'Claimed later';

  @override
  String get badgeNote => 'Note';

  @override
  String get badgeNoSignature => 'No signature';

  @override
  String get badgeHashCopied => 'Hash copied';

  @override
  String get badgeInfoCopied => 'Badge info copied to clipboard';

  @override
  String get badgeNfcTag => 'NFC tag';

  @override
  String get badgeRollingQr => 'Rolling QR code';

  @override
  String get levelNew => 'NEW';

  @override
  String get levelStarter => 'STARTER';

  @override
  String get levelActive => 'ACTIVE';

  @override
  String get levelEstablished => 'ESTABLISHED';

  @override
  String get levelVeteran => 'VETERAN';

  @override
  String get reputationTitle => 'REPUTATION';

  @override
  String get reputationNoBadges => 'NO BADGES YET';

  @override
  String get reputationNoProofs => 'No cryptographic proofs yet';

  @override
  String get reputationBuildHint1 => 'Visit a meetup and scan a badge to ';

  @override
  String get reputationBuildHint2 => 'build your reputation.';

  @override
  String get reputationScanQr => 'SCAN QR CODE';

  @override
  String get reputationShareImage => 'SHARE QR AS IMAGE';

  @override
  String get reputationUpdateRelays => 'UPDATE ON RELAYS';

  @override
  String get reputationPublishing => 'PUBLISHING...';

  @override
  String get reputationBadges => 'Badges';

  @override
  String get reputationMeetups => 'Meetups';

  @override
  String get reputationSigners => 'Signers';

  @override
  String get reputationBound => 'Bound';

  @override
  String get reputationSchnorrSigned => 'Schnorr-signed';

  @override
  String get reputationSignedNoId => 'Signed (no identity)';

  @override
  String get reputationNoIdentity =>
      'No identity linked. Add Telegram or Nostr in your profile.';

  @override
  String get reputationCheck => 'Check reputation';

  @override
  String get reputationVerified => 'My verified meetup reputation';

  @override
  String get reputationCodeFrom => 'Reputation code from';

  @override
  String get portalDiscover => 'DISCOVER';

  @override
  String get portalQuickAccess => 'QUICK ACCESS';

  @override
  String get portalPodcastMedia => 'PODCAST & MEDIA';

  @override
  String get portalSocialNetworks => 'SOCIAL NETWORKS';

  @override
  String get portalAssociation => 'ASSOCIATION';

  @override
  String get portalProfile => 'Your profile & badges';

  @override
  String get portalMeetupMap => 'Meetup map';

  @override
  String get portalMeetupMapSub => 'Meetups near you';

  @override
  String get portalBeginnerPath => 'The Path (beginners)';

  @override
  String get portalShoutoutSend => 'Send shoutout';

  @override
  String get portalMembership => 'Become a member';

  @override
  String get portalSoundboard => 'Soundboard';

  @override
  String get portalClipsSounds => 'Clips & sounds';

  @override
  String get portalInterviews => 'Interviews';

  @override
  String get portalMediaArticles => 'Media & articles';

  @override
  String get portalMerch => 'Merch & Bitcoin products';

  @override
  String get portalShop => 'Shop';

  @override
  String get portalDonate => 'Donate';

  @override
  String get portalContact => 'Contact';

  @override
  String get portalPrivacy => 'Privacy';

  @override
  String get portalStatutes => 'Statutes (PDF)';

  @override
  String get portalAboutAssoc => 'About the association';

  @override
  String get portalOpen => 'Open portal';

  @override
  String get portalTagline => 'for bullish Bitcoiners.';

  @override
  String get portalInfotainment => 'Toxic-maximalist infotainment';

  @override
  String get portalPodcast => 'Podcast';

  @override
  String get portalProfile2 => 'Portal';

  @override
  String get profileTitle => 'YOUR PROFILE';

  @override
  String get profileEditTitle => 'EDIT PROFILE';

  @override
  String get profileSave => 'SAVE PROFILE';

  @override
  String get profileIntro => 'Choose a nickname and your home meetup.';

  @override
  String get profileNicknameMin => 'At least 2 characters';

  @override
  String get profileNicknameReq => 'Required field — please fill in';

  @override
  String get profileNicknameAnon =>
      'Please choose your own nickname (not \'Anon\')';

  @override
  String get profileHomeMeetup => 'Home meetup';

  @override
  String get profileHomeMeetupDash => 'Home meetup';

  @override
  String get profileChooseMeetup => 'Choose your home meetup';

  @override
  String get profileMeetupReq => 'Required — please choose your home meetup';

  @override
  String get profileSearchCity => 'Search city...';

  @override
  String get profileIdentity => 'YOUR IDENTITY';

  @override
  String get profileStrengthen => 'STRENGTHEN IDENTITY';

  @override
  String get profileStrengthenDesc =>
      'Link platforms and prove your humanity to raise your Trust Score.';

  @override
  String get profileLinkPlatforms => 'Link platforms';

  @override
  String get profilePlatformsSub => 'Telegram, X, classifieds';

  @override
  String get profileProofHumanity => 'Proof of Humanity';

  @override
  String get profileZapCheck => 'Zapped once? Check now';

  @override
  String get profileLightningActive => 'Lightning proof active';

  @override
  String get profileVerified => 'VERIFIED';

  @override
  String get profileNostrKeyShort => 'Nostr';

  @override
  String get profileNoKey => 'No Nostr key yet';

  @override
  String get profileKeyActiveCaps => 'KEY ACTIVE';

  @override
  String get profileCreateKey => 'CREATE NOSTR KEY';

  @override
  String get profileCreateNewKey => 'CREATE NEW KEY';

  @override
  String get profileCreating => 'CREATING...';

  @override
  String get profileNoNostrNeeded =>
      'You don\'t need a Nostr account. The app creates a key for you — takes a second.';

  @override
  String get profileKeyDesc =>
      'Your cryptographic key — used to sign badges and verify your reputation.';

  @override
  String get profileConnectAmber => 'CONNECT WITH AMBER';

  @override
  String get profileAmberDesc =>
      'Amber is a separate signer for Android that keeps your private ';

  @override
  String get profileAmberConnected =>
      'Connected with Amber! Your nsec stays in Amber.';

  @override
  String get profileAmberNotFound => 'Amber not found';

  @override
  String get profileAmberInstall =>
      'Key stored securely. Install Amber (e.g. via F-Droid ';

  @override
  String get profileAmberRetry => 'or the Zapstore) and try again.';

  @override
  String get profileAmberAborted => 'Connection aborted in Amber.';

  @override
  String get profileImportNsec => 'IMPORT EXISTING NSEC';

  @override
  String get profileImportNsecShort => 'IMPORT NSEC';

  @override
  String get profileImport => 'IMPORT';

  @override
  String get profileEnterNsec =>
      'Enter your private Nostr key (starts with nsec1...):';

  @override
  String get profileKeyImported => 'Key imported!';

  @override
  String get profileShowNsecQ => 'SHOW NSEC?';

  @override
  String get profileShowNsecWarn =>
      'Your private key will be shown. Make sure nobody is looking at your screen!';

  @override
  String get profileShow => 'SHOW';

  @override
  String get profileCopy => 'COPY';

  @override
  String get profileSecureKey => 'SECURE YOUR KEY!';

  @override
  String get profileSaveKeyDesc =>
      'This is your private key. Store it in a safe place! ';

  @override
  String get profileKeyNotShownAgain => 'This key will NOT be shown again!';

  @override
  String get profileKeySecured => 'I\'VE SECURED IT';

  @override
  String get profileNpubCopied => 'npub copied!';

  @override
  String get profileNsecCopied => 'nsec copied! Save it securely now.';

  @override
  String get profileNsecNeverLeaves => 'Your nsec never leaves your device.';

  @override
  String get profileWhoHasKey => 'Whoever has this key HAS your identity.';

  @override
  String get profileBackupNsec =>
      'Important: back up your nsec! If you lose your device, your key is gone.';

  @override
  String get profileNewKeypairDesc =>
      'A new key pair will be created. Your private key (nsec) is stored securely on your device.\n\n';

  @override
  String get profileEdit => 'Edit';

  @override
  String get profileEditLoseStatus => 'EDIT (lose status)';

  @override
  String get profileWarning => 'Warning!';

  @override
  String get profileEditWarnDesc =>
      'If you edit, you lose your \'Verified\' status and must be re-approved.';

  @override
  String get dialogCancel => 'CANCEL';

  @override
  String get dialogCancelMixed => 'Cancel';

  @override
  String get dialogCreate => 'CREATE';

  @override
  String errorGeneric(String msg) {
    return 'Error: $msg';
  }

  @override
  String errorAmber(String msg) {
    return 'Amber error: $msg';
  }

  @override
  String profileFillIn(Object fields) {
    return 'Please fill in: $fields';
  }
}
