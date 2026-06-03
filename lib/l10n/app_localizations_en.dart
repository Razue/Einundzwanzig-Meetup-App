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

  @override
  String get backupEncryptTitle => 'Encrypt backup';

  @override
  String get backupDecryptTitle => 'Decrypt backup';

  @override
  String get backupExportDesc =>
      'Set a password to protect your private key (nsec) in the backup.\n\n⚠️ If you forget this password, the backup is IRRECOVERABLY lost!';

  @override
  String get backupImportDesc =>
      'This backup is encrypted. Please enter the password.';

  @override
  String get backupPassword => 'Password';

  @override
  String get backupPasswordConfirm => 'Confirm password';

  @override
  String get backupPasswordEmpty => 'Password cannot be empty';

  @override
  String get backupPasswordMin => 'At least 8 characters';

  @override
  String get backupPasswordMismatch => 'Passwords do not match';

  @override
  String get backupEncryptSave => 'Encrypt & Save';

  @override
  String get backupDecryptLoad => 'Decrypt & Load';

  @override
  String get backupShareTitle => 'Einundzwanzig App Backup (Encrypted)';

  @override
  String get backupShareText =>
      'Your encrypted backup. Keep your password ready to restore it.';

  @override
  String backupError(String msg) {
    return 'Backup error: $msg';
  }

  @override
  String get backupCorrupt => 'Backup file is corrupted (format error).';

  @override
  String get backupWrongPassword => 'Wrong password or file corrupted!';

  @override
  String get backupNotValid => 'File is not a valid backup or wrong format.';

  @override
  String get backupNotEinundzwanzig =>
      'File is not a valid Einundzwanzig backup.';

  @override
  String backupLoaded(Object items) {
    return '✅ Backup loaded! $items restored.';
  }

  @override
  String backupImportFailed(String msg) {
    return 'Import failed: $msg';
  }

  @override
  String get qrScanTitle => 'CHECK REPUTATION';

  @override
  String get qrResultTitle => 'RESULT';

  @override
  String get qrScanHint => 'Scan an Einundzwanzig\nreputation QR code';

  @override
  String get qrLoadFromGallery => 'LOAD QR FROM GALLERY';

  @override
  String get qrBack => 'BACK';

  @override
  String get qrNoCodeInImage => 'No QR code found in image';

  @override
  String get qrNotEinundzwanzig =>
      'QR code found, but not Einundzwanzig format';

  @override
  String get qrVerified => 'VERIFIED';

  @override
  String get qrVerifiedV1 => 'VERIFIED (v1)';

  @override
  String get qrVerifiedV2 => 'VERIFIED (v2)';

  @override
  String get qrSigInvalid => 'SIGNATURE INVALID';

  @override
  String get qrFormatUnknown => 'FORMAT UNKNOWN';

  @override
  String get qrReadError => 'READ ERROR';

  @override
  String get qrV2Subtitle => 'Legacy signature valid — no badge proof';

  @override
  String get qrV1Subtitle => 'Older format — no identity binding';

  @override
  String get qrCantRead => 'QR code could not be read.';

  @override
  String qrProcessError(String msg) {
    return 'Processing error: $msg';
  }

  @override
  String get qrSectionIdentity => 'IDENTITY';

  @override
  String get qrNoIdentity => 'NO IDENTITY';

  @override
  String get qrNoVerifiableIdentity => 'No verifiable identity.';

  @override
  String get qrSectionLightning => 'LIGHTNING';

  @override
  String get qrSectionSocial => 'SOCIAL NETWORK';

  @override
  String get qrSectionPlatforms => 'LINKED PLATFORMS';

  @override
  String get qrSectionMeetups => 'VISITED MEETUPS';

  @override
  String get qrHumanVerified => 'Human verified';

  @override
  String get qrLightningActive => 'Lightning proof active';

  @override
  String get qrNoLightning => 'No Lightning proof found';

  @override
  String get qrNoZap => 'No zap activity';

  @override
  String get qrNip05Invalid => 'NIP-05 invalid';

  @override
  String get qrYouFollow => 'You follow';

  @override
  String get qrFollowsYou => 'Follows you';

  @override
  String get qrMutualFollow => 'Mutual follow';

  @override
  String get qrNoDirectFollow => 'No direct follow';

  @override
  String get qrDirectConnection => 'Direct connection';

  @override
  String get qrBidirectional => 'Direct bidirectional connection';

  @override
  String get qrOneWay => 'One-way connection';

  @override
  String get qrViaContacts => 'Via shared contacts';

  @override
  String get qrStrongOverlap => 'Strong network overlap';

  @override
  String get qrPartiallyConnected => 'Partially connected';

  @override
  String get qrNoOverlap => 'No overlap';

  @override
  String get qrEndorsement => 'Endorsement from known admins';

  @override
  String get qrSigVerified => 'Signature verified';

  @override
  String get qrAnalyzingNetwork => 'Analyzing network...';

  @override
  String get qrCheckingLightning => 'Checking Lightning...';

  @override
  String get qrCheckingNip05 => 'Checking NIP-05...';

  @override
  String get qrStatBadges => 'Badges';

  @override
  String get qrStatMeetups => 'Meetups';

  @override
  String get qrStatSigners => 'Signers';

  @override
  String get qrStatBound => 'Bound';

  @override
  String get qrStatDays => 'Days';

  @override
  String get qrLabelNickname => 'Nickname';

  @override
  String get qrLabelTwitter => 'Twitter/X';

  @override
  String get qrPlatformOther => 'Other';

  @override
  String get qrLinked => 'Linked';

  @override
  String get qrSigVerifiedShort => 'Signature verified';

  @override
  String get qrLinkedShort => 'Linked';

  @override
  String get nfcDisabled => 'NFC is disabled';

  @override
  String get nfcDisabledHint => 'NFC is disabled. Please turn it on.';

  @override
  String get nfcUnavailable => 'NFC unavailable';

  @override
  String get nfcOpenSettings => 'OPEN SETTINGS';

  @override
  String get nfcEnableHint => 'Please enable NFC in your device settings ';

  @override
  String get nfcSettingsAndroid => 'Android: Settings → Connections → NFC';

  @override
  String get nfcSettingsIos => 'iOS: Settings → NFC';

  @override
  String get verifyScanBadge => 'SCAN BADGE';

  @override
  String get verifyScanNfc => 'SCAN NFC TAG';

  @override
  String get verifyScanQr => 'SCAN QR';

  @override
  String get verifyScanQrCaps => 'SCAN QR CODE';

  @override
  String get verifyReadyToScan => 'Ready to scan';

  @override
  String get verifyWaitingNfc => 'Waiting for NFC tag...';

  @override
  String get verifyCheckingNfc => 'Checking NFC...';

  @override
  String get verifyScanInstruction =>
      'Scan the NFC tag or QR code\nof the meetup organizer.';

  @override
  String get verifyScanQrInstruction =>
      'Scan the QR code\nof the meetup organizer';

  @override
  String get verifyNoNfcDevice => 'This device has no NFC. Use the QR scanner.';

  @override
  String get verifyNoNfcLong => 'This device does not support NFC.\n\n';

  @override
  String get verifyUseQrInstead => 'Use the QR code scanner instead ';

  @override
  String get verifyToGetBadge => 'to get your badge.';

  @override
  String get verifyAskScan => 'Please let a participant scan your tag.';

  @override
  String get verifyCantSelfBadge => 'You cannot give yourself a badge.\n';

  @override
  String get verifyBadgeFound => 'BADGE FOUND';

  @override
  String get verifyAlreadyCollected => 'ALREADY COLLECTED';

  @override
  String get verifyAddToWallet => 'ADD TO WALLET';

  @override
  String get verifyVerifiedAdmin => 'Verified admin';

  @override
  String get verifyUnknownMeetup => 'Unknown meetup';

  @override
  String get verifyNoExpiry => 'No expiry';

  @override
  String get writerReadyToWrite => 'Ready to write';

  @override
  String get writerNoNfcDevice =>
      'This device has no NFC. Use rolling QR codes.';

  @override
  String get writerUseRollingQr => 'You can use rolling QR codes instead ';

  @override
  String get writerForYourMeetup => 'for your meetup.';

  @override
  String get writerSelectHomeFirst =>
      'Please select a home meetup in your profile first';

  @override
  String get writerYourHomeMeetup => 'YOUR HOME MEETUP';

  @override
  String get writerCreateTag => 'CREATE TAG';

  @override
  String get writerCreateMeetupTag => 'CREATE MEETUP TAG';

  @override
  String get writerMeetupTag => 'MEETUP TAG';

  @override
  String get writerSuccess => 'SUCCESS!';

  @override
  String get writerValid6h => 'Valid for 6 hours';

  @override
  String get writerHoldTag => 'Hold tag to the device...';

  @override
  String get writerHoldTagInstruction =>
      'Hold an NFC tag to the device.\nParticipants scan this tag to collect a badge.';

  @override
  String get writerFormatting => 'Formatting empty tag...';

  @override
  String get writerFormatFailed => 'Formatting failed';

  @override
  String get writerLoadingSession => 'Loading session data...';

  @override
  String get writerJumpToQr => 'Jumping to QR code...';

  @override
  String get writerNoNdef => 'NDEF format not possible';

  @override
  String get writerTagReadOnly => 'Tag is read-only';

  @override
  String get writerCanOverwrite => 'Tag can be overwritten afterwards';

  @override
  String get writerTagLost => 'Tag lost during writing';

  @override
  String get writerTagRemovedEarly =>
      'Tag removed too early — hold it steady for 2–3 seconds';

  @override
  String get writerUseNtag215 => 'Use an NTAG215 (504B) or larger.';

  @override
  String get writerToWriteTag => 'to write the tag.\n\n';

  @override
  String verifyMsgLocation(String name) {
    return 'Location: $name';
  }

  @override
  String verifyMsgBlock(Object height) {
    return 'Block: $height';
  }

  @override
  String verifyMsgSignedBy(String signer) {
    return 'Signed by: $signer';
  }

  @override
  String get verifyMsgProof => 'Proof: Schnorr (BIP-340)';

  @override
  String verifyMsgTagExpiry(String expiry) {
    return 'Tag expiry: $expiry';
  }

  @override
  String verifyAlreadyToday(String name) {
    return 'Already collected\n\nYou already have a badge today from:\n$name';
  }

  @override
  String get wotTitle => 'WEB OF TRUST';

  @override
  String get wotActiveOrganizers => 'ACTIVE ORGANIZERS';

  @override
  String get wotActiveOrganizer => 'ACTIVE ORGANIZER';

  @override
  String get wotActiveWarnings => 'ACTIVE WARNINGS';

  @override
  String get wotActiveWarning => 'Active warning';

  @override
  String get wotMyStatus => 'YOUR STATUS';

  @override
  String get wotMyVouches => 'YOUR VOUCHES';

  @override
  String get wotWhoYouVouchFor => 'WHO YOU VOUCH FOR';

  @override
  String get wotWhoVouchesForYou => 'WHO VOUCHES FOR YOU';

  @override
  String get wotWeightedReporting => 'WEIGHTED REPORTING SYSTEM';

  @override
  String get wotRestore => 'RESTORE';

  @override
  String get wotRevokeAll => 'REVOKE ALL';

  @override
  String get wotPublishNostr => 'PUBLISH TO NOSTR';

  @override
  String get wotVouch => 'VOUCH';

  @override
  String get wotVouchVerb => 'VOUCH';

  @override
  String get wotReportNpub => 'REPORT NPUB';

  @override
  String get wotScanNpub => 'SCAN NPUB';

  @override
  String get wotPublishRevocation => 'PUBLISH REVOCATION';

  @override
  String get wotSigningPublishing => 'SIGNING & PUBLISHING...';

  @override
  String get wotSyncNetwork => 'Sync network';

  @override
  String get wotBootstrapPhase => 'Bootstrap phase';

  @override
  String get wotDecentralized => 'Decentralized (Web of Trust)';

  @override
  String get wotMinVouches => 'Min. vouchers';

  @override
  String get wotDistrustThreshold => 'Distrust threshold';

  @override
  String get wotNotEnoughVouchers => 'NOT ENOUGH VOUCHERS YET';

  @override
  String get wotVouchers => 'Vouchers';

  @override
  String get wotNoVouchersYet => 'No vouchers yet';

  @override
  String get wotNobodyYet => 'Nobody yet';

  @override
  String get wotNotSuspendedWatch =>
      'Not suspended yet, but you should watch out.';

  @override
  String get wotNoReports => 'No reports';

  @override
  String get wotNoActiveAdmins => 'No active admins';

  @override
  String get wotNoCleanNetwork =>
      'There are currently no open warnings\nin the network. All clean.';

  @override
  String get wotNoOrganizersEnough =>
      'The network has no organizers with enough vouches yet.';

  @override
  String get wotNoVouchesFound => 'No published vouches found on the relays.';

  @override
  String get wotTapPlusFirst => 'Tap + to give your first vouch.';

  @override
  String get wotAskOthersVouch => 'Ask other organizers to vouch for you.\n';

  @override
  String get wotNoDataLoaded =>
      'Network data could not be loaded.\nPull down to refresh.';

  @override
  String get wotNoRelay => 'No relay reachable — try again later.';

  @override
  String get wotRevokeAllTitle => 'REVOKE ALL VOUCHES?';

  @override
  String get wotRevokeVouchTitle => 'WITHDRAW VOUCH?';

  @override
  String get wotWithdrawVouch => 'Withdraw vouch';

  @override
  String get wotVouchWithdrawn => 'Vouch withdrawn. Don\'t forget to publish.';

  @override
  String get wotVouchGiven => 'Vouch given! Don\'t forget to publish.';

  @override
  String get wotAllRevoked => 'All vouches have been revoked in the network.';

  @override
  String get wotReasonRequired => 'Reason (required)';

  @override
  String get wotNpubRequired => 'npub (required)';

  @override
  String get wotNameAlias => 'Name / alias (optional)';

  @override
  String get wotMeetupExample => 'Meetup (e.g. Munich)';

  @override
  String get wotReasonExample => 'e.g. Forges badges, no real meetup...';

  @override
  String get wotNpubReasonRequired => 'npub and reason are required.';

  @override
  String get wotScanInstruction =>
      'Scan the Nostr QR code (npub)\nof the organizer.';

  @override
  String get wotVouchExplain =>
      'You vouch for this organizer with your own reputation.';

  @override
  String get wotEachVouchPersonal =>
      'Each vouch is your personal vote of trust — ';

  @override
  String get wotAfterPublishAll =>
      'after publishing, the whole network sees who you stand for.';

  @override
  String get wotWhoYouVouchExplain => 'Here you see who YOU vouch for. ';

  @override
  String get wotPublishUpdated => 'Then publish your updated list ';

  @override
  String get wotSoNetworkKnows => 'so the network finds out.';

  @override
  String get wotSingleReportNoWeight => 'A single report has no weight — ';

  @override
  String get wotOnlyMultipleIndep =>
      'only when several independent organizers ';

  @override
  String get wotWarnSuspend => 'warn, someone gets suspended. ';

  @override
  String get wotNobodyAlonePower => 'Nobody alone has power over others.';

  @override
  String get wotYourReportAlone =>
      'Your report alone has no weight. Only when ';

  @override
  String get wotOrgsWarnSuspended =>
      'organizers warn, the npub gets suspended.';

  @override
  String get wotRevokeAllBody =>
      'This publishes an empty list on Nostr, revoking ALL ';

  @override
  String get wotFromOtherOrgs => 'from other organizers.';

  @override
  String get wotRestoreExplain =>
      'Vouches are signed on Nostr. \"Restore\" fetches ';

  @override
  String get wotRestoreListBack =>
      'your list back after a reinstall or backup change.';

  @override
  String get wotVouchesSignedOnNostr =>
      'your vouches in the network — even ones no longer ';

  @override
  String get wotVisibleLocally =>
      'visible locally.\n\nUse this if, after a reinstall, you ';

  @override
  String get wotCantResolveOld => 'can no longer resolve your old vouches.';

  @override
  String get wotRemovedFromList =>
      'will be removed from your vouching list.\n\n';

  @override
  String get wotSuspendedByNetwork =>
      'suspended by the network. Check your vouches.';

  @override
  String wotErrorLoading(String msg) {
    return 'Error loading: $msg';
  }

  @override
  String wotSyncFailed(String msg) {
    return 'Sync failed: $msg';
  }

  @override
  String wotRevocationFailed(String msg) {
    return 'Revocation failed: $msg';
  }

  @override
  String wotRestoreFailed(String msg) {
    return 'Restore failed: $msg';
  }

  @override
  String wotVouchesRestored(Object count) {
    return '$count vouches restored from Nostr.';
  }

  @override
  String wotNetworkHealth(String label) {
    return 'NETWORK $label';
  }

  @override
  String wotVouchProgress(Object count, Object total) {
    return '$count / $total vouchers';
  }

  @override
  String wotReportsCount(Object count) {
    return '$count reports';
  }

  @override
  String wotNeedMoreVouches(Object count) {
    return 'You still need $count more vouches ';
  }

  @override
  String wotVouchesRequired(Object count, Object total) {
    return '$count / $total required';
  }

  @override
  String wotSuspensionProgress(Object count, Object total) {
    return '$count / $total suspension';
  }

  @override
  String wotLiability(Object count) {
    return 'LIABILITY: $count suspended';
  }

  @override
  String wotWarningCount(Object count) {
    return 'WARNING: $count reported';
  }

  @override
  String wotYourNpub(String npub) {
    return 'Your npub: $npub';
  }

  @override
  String wotLiabilityBody(String names) {
    return 'You vouch for $names — these npubs are suspended by the network. Check your vouches.';
  }

  @override
  String wotWarningBody(String names) {
    return 'There are reports for $names. ';
  }

  @override
  String get wotVotes => 'Votes';

  @override
  String get wotSuspended => 'Suspended';

  @override
  String wotReportNoWeightThreshold(Object count) {
    return 'Your report alone has no weight. Only when $count independent organizers warn does the npub get suspended.';
  }

  @override
  String wotPublishedLive(Object count) {
    return 'Your Web of Trust is live ($count relays)!';
  }

  @override
  String wotReportPublished(Object count) {
    return 'Report published to $count relays.';
  }

  @override
  String wotErrorShort(String msg) {
    return 'Error: $msg';
  }

  @override
  String get wotOffline => 'Offline';

  @override
  String get wotActive => 'Active';

  @override
  String get wotPhase => 'Phase';

  @override
  String get wotPhaseDecentralized => 'Decentralized';

  @override
  String get wotPhaseBootstrap => 'Bootstrap';

  @override
  String get wotReportsLabel => 'Reports';

  @override
  String get wotVouchersLabel => 'VOUCHERS:';

  @override
  String writerTagTooSmall(Object data, Object max) {
    return 'Tag too small! Data: ${data}B, tag: ${max}B.\n';
  }

  @override
  String get writerTagWritten => '✅ MEETUP TAG written!\n\n';

  @override
  String writerCompactSize(Object size) {
    return '📦 ${size}B (compact)\n';
  }

  @override
  String writerValidHours(Object hours) {
    return '⏱️ Valid for ${hours}h\n\n';
  }

  @override
  String get verifyErrNoNdef => '✗ No NDEF tag';

  @override
  String get verifyErrTagEmpty => '✗ Tag is empty';

  @override
  String get verifyErrPayloadEmpty => '✗ Payload empty';

  @override
  String get verifyErrInvalidFormat => '✗ Invalid format';

  @override
  String verifyErrInvalidTag(String msg) {
    return '✗ Invalid tag: $msg';
  }

  @override
  String verifyErrReadError(String msg) {
    return '✗ Read error: $msg';
  }

  @override
  String verifyErrNfcError(String msg) {
    return '✗ NFC error: $msg';
  }

  @override
  String verifyErrQrExpired(String msg) {
    return '✗ QR code expired!\n$msg\n\nPlease scan directly on the organizer\'s screen.';
  }

  @override
  String verifyErrPrefix(String msg) {
    return '✗ $msg';
  }

  @override
  String writerStartError(String msg) {
    return '❌ Start error: $msg';
  }

  @override
  String writerFitsNtag215(Object size) {
    return '~${size}B — fits on NTAG215 (492B)';
  }

  @override
  String get writerNoHomeMeetup => '⚠️ No home meetup set';

  @override
  String get writerHomeMeetupNotFound => '⚠️ Home meetup not found';

  @override
  String get writerNoActiveSession =>
      '❌ No active meetup session found. Please restart the meetup.';

  @override
  String get admMyWebOfTrust => 'MY WEB OF TRUST';

  @override
  String get admMyDelegations => 'YOUR DELEGATIONS';

  @override
  String get admCoAdminKnight => 'KNIGHT CO-ADMIN';

  @override
  String get admKnighthood => 'KNIGHTHOOD';

  @override
  String get admRemove => 'REMOVE';

  @override
  String get admCancel => 'CANCEL';

  @override
  String get admRevokeTrust => 'WITHDRAW TRUST?';

  @override
  String get admRevokeTrustShort => 'Withdraw trust';

  @override
  String get admSyncWot => 'Sync Web of Trust';

  @override
  String get admNobodyDelegated => 'You haven\'t delegated anyone yet.';

  @override
  String get admTapKnighthood =>
      'Tap \'KNIGHTHOOD\' below\nto extend trust to a new organizer\nin your meetup.';

  @override
  String get admVouchNewExplain =>
      'You vouch for this new organizer with your own reputation.';

  @override
  String get admScanNewOrg => 'Scan the new organizer\'s Nostr QR code (npub).';

  @override
  String get admNetworkLearnsKnight =>
      'The network only learns of your new co-admins\nonce you publish your signature on Nostr.';

  @override
  String get admMustRepublish =>
      'You must republish the list afterwards so the network finds out.';

  @override
  String get admPublishEmptyRevoke =>
      'Publish an empty list to revoke all delegations\nin the network.';

  @override
  String get admRestoreListBack => 'your list after a reinstall.';

  @override
  String get admSigningSending => 'Signing and sending to Nostr...';

  @override
  String get admRestoringVouches => 'Restoring my vouches from Nostr...';

  @override
  String get admSyncingWot => 'Syncing Web of Trust...';

  @override
  String get admRevokingAll => 'Revoking all vouches...';

  @override
  String admRevokeTrustBody(String name, String meetup) {
    return 'Do you want to withdraw trust as admin for $meetup from $name?\n\n';
  }

  @override
  String get admRestoreExplain =>
      'Vouches are signed on Nostr. \"Restore\" fetches ';

  @override
  String admVouchedCount(Object count) {
    return 'You have vouched for $count organizers.';
  }

  @override
  String get admCoAdminAdded => '✅ Co-admin added! Don\'t forget to publish.';

  @override
  String get apMeetupSession => 'MEETUP SESSION';

  @override
  String get apSessionRunning => 'SESSION RUNNING';

  @override
  String get apOpenActiveMeetup => 'OPEN ACTIVE MEETUP';

  @override
  String get apStartMeetup => 'START MEETUP';

  @override
  String get apEndMeetupEarly => 'End meetup early';

  @override
  String get apNetwork => 'NETWORK';

  @override
  String get apOrganizer => 'ORGANIZER';

  @override
  String get apWebOfTrust => 'WEB OF TRUST';

  @override
  String get apHowItWorks => 'HOW IT WORKS';

  @override
  String get apManageVouches => 'Manage vouches, network status, reports';

  @override
  String get apNewMeetupQ => 'Start new meetup?';

  @override
  String get apSessionEndQ => 'End session?';

  @override
  String get apCancel => 'Cancel';

  @override
  String get apStart => 'Start';

  @override
  String get apEnd => 'End';

  @override
  String get apSeedAdmin => 'Seed Admin';

  @override
  String get apViaTrustScore => 'Via Trust Score';

  @override
  String get apNewMeetupBody =>
      'This creates a unique signature (block time) for the next 6 hours. During this time, creating new sessions is locked.';

  @override
  String get apSessionEndBody =>
      'This locks the current block time. You can start a new session afterwards.';

  @override
  String get apGeneratesProof =>
      'Generates a new cryptographic proof for the next 6 hours.';

  @override
  String get humTitle => 'PROOF OF HUMANITY';

  @override
  String get humVerified => 'HUMAN VERIFIED';

  @override
  String get humNotVerified => 'NOT VERIFIED';

  @override
  String get humVerifiedSub => 'You are verified as human';

  @override
  String get humLightningActive => 'Lightning proof active';

  @override
  String get humCheckNow => 'CHECK NOW';

  @override
  String get humCheckAgain => 'CHECK AGAIN';

  @override
  String get humCheckAgainShort => 'Check again';

  @override
  String get humSearchingRelays => 'SEARCHING RELAYS...';

  @override
  String get humHowTitle => 'HOW DOES IT WORK?';

  @override
  String get humIntro1 => 'Prove you are human — by demonstrating ';

  @override
  String get humIntro2 => 'that you own a real Lightning wallet and ';

  @override
  String get humIntro3 => 'have zapped someone on Nostr before.';

  @override
  String get humExplain1 =>
      'Bots don\'t have Lightning wallets. A single real ';

  @override
  String get humExplain2 => 'payment proves you are a human with a real ';

  @override
  String get humExplain3 => 'wallet — without revealing personal data.';

  @override
  String get humStep1 => 'You zap anyone on Nostr';

  @override
  String get humStep2 => 'The zap creates a receipt on relays';

  @override
  String get humStep3 => 'The app finds your receipt';

  @override
  String get humStepInstruction =>
      'Anyone, any amount of sats. Use a Nostr client like Damus, Amethyst or Primal.';

  @override
  String get humCheckInstruction =>
      'Press the check button and the app searches Nostr relays for your zap.';

  @override
  String get humZapReturn => 'Zap anyone and come back';

  @override
  String get humCryptoProof =>
      'This is a cryptographic proof that you made a real Lightning payment.';

  @override
  String get humProofInEvent1 => 'on the Nostr network. This proof is in your ';

  @override
  String get humProofPrivacy =>
      'The proof is included in your reputation event. No amount or recipient is stored.';

  @override
  String get humReputationSaved => 'Reputation event saved.';

  @override
  String humPaidOn(String date) {
    return 'You made a Lightning payment on $date ';
  }

  @override
  String humLastCheck(String time) {
    return 'Last check: $time';
  }

  @override
  String get ppTitle => 'PLATFORM LINK';

  @override
  String get ppPlatform => 'PLATFORM';

  @override
  String get ppUsername => 'USERNAME';

  @override
  String get ppActiveLinks => 'ACTIVE LINKS';

  @override
  String get ppLinkPlatform => 'LINK PLATFORM';

  @override
  String get ppCreateLink => 'CREATE LINK';

  @override
  String get ppAnotherPlatform => 'ANOTHER PLATFORM';

  @override
  String get ppShareOnPlatform => 'SHARE ON PLATFORM';

  @override
  String get ppUnlinkQ => 'UNLINK?';

  @override
  String get ppRevoke => 'REVOKE';

  @override
  String get ppCancel => 'CANCEL';

  @override
  String get ppYourUsername => 'Your username';

  @override
  String get ppPlatformName => 'Platform name';

  @override
  String get ppIntro =>
      'Link your account with a platform. The proof is automatically embedded in your reputation QR.';

  @override
  String get ppLinkSaved =>
      'Link saved! Automatically embedded in your reputation QR.';

  @override
  String get ppMustUpdate =>
      'You must update your reputation event afterwards.';

  @override
  String get ppUnlinkBody1 => 'The platform link for \"';

  @override
  String get ppUnlinkBody2 => 'will be deleted.\n\n';

  @override
  String ppUnlinkBody(String username, String platform) {
    return 'The platform link for \"$username\" on $platform will be deleted.\n\nYou must update your reputation event afterwards.';
  }

  @override
  String ppCreated(String date) {
    return 'Created: $date';
  }

  @override
  String get ppRevokeTooltip => 'Revoke';

  @override
  String get rqTitle => 'MEETUP QR CODE';

  @override
  String get rqActive => 'ACTIVE';

  @override
  String get rqCodeRenewing => 'Code is renewing...';

  @override
  String get rqNextCodeIn => 'Next code in';

  @override
  String get rqEndSession => 'End session';

  @override
  String get rqEndSessionQ => 'End session?';

  @override
  String get rqEnd => 'END';

  @override
  String get rqEndSessionBody =>
      'An ended session locks this block time. You can start a new session afterwards.';

  @override
  String get rqNoActiveSession => 'NO ACTIVE SESSION';

  @override
  String get rqNoSessionBody =>
      'There is currently no active meetup session.\nPlease restart the meetup in the Admin Panel.';

  @override
  String get rqBackToAdmin => 'BACK TO ADMIN PANEL';

  @override
  String get rsTitle => 'NOSTR RELAYS';

  @override
  String get rsDefaultRelays => 'DEFAULT RELAYS';

  @override
  String get rsCustomRelays => 'CUSTOM RELAYS';

  @override
  String get rsAddRelay => 'ADD RELAY';

  @override
  String get rsAdd => 'ADD';

  @override
  String get rsNoRelaysActive => 'No relays active!';

  @override
  String get rsNoCustomRelays => 'No custom relays configured.';

  @override
  String get rsAllRelaysInfo =>
      'The app uses all active relays simultaneously for maximum reach.';

  @override
  String get rsRelaysIntro =>
      'Relays distribute your reputation across the Nostr network. ';

  @override
  String get rsRelayPlaceholder => 'wss://my-relay.com';

  @override
  String get rdScanAdminTag => 'SCAN ADMIN TAG';

  @override
  String get rdAnon => 'ANON';

  @override
  String get rdCollectBadge => 'COLLECT BADGE';

  @override
  String get rdYourReputation => 'YOUR REPUTATION';

  @override
  String get rdEditIdentity => 'Edit identity';

  @override
  String get rdLinkingIdentity => 'Linking identity...';

  @override
  String get rdNostrVerified => 'NOSTR VERIFIED';

  @override
  String get rdNoBadges => 'No badges collected yet.\nGo to a meetup!';

  @override
  String get rdSelfSovereign =>
      'Self-sovereign: This app runs without a server. Your badges belong only to you and are stored on this device.';

  @override
  String get rdVerifiedByAdmin => 'VERIFIED BY ADMIN';

  @override
  String rqRemainingTime(String time) {
    return 'Remaining time: $time\n\n';
  }

  @override
  String rqSessionRemaining(String time) {
    return 'Session: $time';
  }

  @override
  String get rvTitle => 'CHECK REPUTATION';

  @override
  String get rvChecking => 'CHECKING...';

  @override
  String get rvFullyVerified => 'FULLY VERIFIED';

  @override
  String get rvPartiallyVerified => 'PARTIALLY VERIFIED';

  @override
  String get rvSignatureOnly => 'SIGNATURE ONLY CHECKED';

  @override
  String get rvInvalid => 'INVALID';

  @override
  String get rvConfirmedInEvent => 'Confirmed in event';

  @override
  String get rvPlatformProof => 'Platform proof';

  @override
  String get rvIntro1 => 'Paste a person\'s verify string or npub ';

  @override
  String get rvIntro2 => 'to check their reputation across all proof layers.';

  @override
  String get rvCheckingSignature => 'Checking signature...';

  @override
  String get rvCheckingNostr => 'Analyzing Nostr network...';

  @override
  String get rvCheckingLightning => 'Checking Lightning activity...';

  @override
  String get rvCheckingNip05 => 'Checking NIP-05...';

  @override
  String get msSelectMeetup => 'SELECT MEETUP';

  @override
  String get msSearchMeetup => 'Search meetup...';

  @override
  String get mlTitle => 'MEETUPS';

  @override
  String get mlRetry => 'Retry';

  @override
  String get mlLoadError => 'Error loading';

  @override
  String get mlNoMeetupsFound => 'No meetups found.';

  @override
  String mlNoMeetupFor(String query) {
    return 'No meetup for \"$query\"';
  }

  @override
  String get cmRequestSent => 'REQUEST SENT 🚀';

  @override
  String get cmDateTime => 'DATE & TIME';

  @override
  String get cmFoundBase => 'FOUND A BASE.';

  @override
  String get cmLocation => 'LOCATION';

  @override
  String get cmCityName => 'CITY NAME';

  @override
  String get cmTelegramGroup => 'TELEGRAM GROUP (OPTIONAL)';

  @override
  String get cmNewMeetup => 'NEW MEETUP';

  @override
  String get cmDateExample => 'e.g. May 21, 7:00 PM';

  @override
  String get cmCityExample => 'e.g. Frankfurt';

  @override
  String get cmLocationExample => 'e.g. Room 77';

  @override
  String get evUpcomingEvents => 'UPCOMING EVENTS';

  @override
  String get evDatesEvents => 'DATES & EVENTS';

  @override
  String get evNoMeetupsFound => 'No meetups found';

  @override
  String get evSearchCityCountry => 'Search city or country...';

  @override
  String get evIntro =>
      'Most Einundzwanzig meetups take place regularly. Tap a meetup for more info and dates.';

  @override
  String get rvLabelPlatform => 'Platform';

  @override
  String get rvLabelUsername => 'Username';

  @override
  String get countryDE => 'Germany';

  @override
  String get countryAT => 'Austria';

  @override
  String get countryCH => 'Switzerland';

  @override
  String get countryES => 'Spain';

  @override
  String get countryNL => 'Netherlands';

  @override
  String get countryIT => 'Italy';

  @override
  String get countryFR => 'France';

  @override
  String get siTitle => 'YOUR TRUST SCORE';

  @override
  String get siIntro =>
      'Measures your trustworthiness. Based on cryptographic proofs — nobody can forge it.';

  @override
  String get siIdentityLayer => 'IDENTITY LAYER';

  @override
  String siLinksActive(Object count) {
    return '$count links active';
  }

  @override
  String get siHumanitySub => 'Lightning zap verification';

  @override
  String get siNip05Sub => 'Nostr identity (name@domain)';

  @override
  String get siPlatformActive => 'Platform active';

  @override
  String get siPlatforms => 'Platforms';

  @override
  String get siNoneLinked => 'None linked yet';

  @override
  String get siTrustLevel => 'TRUST LEVEL';

  @override
  String get siLvlNew => 'Starting level. Visit meetups to collect badges.';

  @override
  String get siLvlStarter => 'Your first badges show community participation.';

  @override
  String get siLvlActive =>
      'Regularly active. Different meetups and organizers strengthen your profile.';

  @override
  String get siLvlEstablished =>
      'Trusted member. Well-connected and long-standing.';

  @override
  String get siLvlVeteran => 'Highest level. Reputation proven over months.';

  @override
  String get siCalculation => 'CALCULATION';

  @override
  String get siFacBadges => 'Meetup badges';

  @override
  String get siFacBadgesDesc =>
      'Base value per badge. Well-attended meetups worth more.';

  @override
  String get siFacDiversity => 'Diversity';

  @override
  String get siFacDiversityDesc => 'Different cities/organizers = more points.';

  @override
  String get siFacSigners => 'Signers';

  @override
  String get siFacSignersDesc => 'Independent organizers = higher trust.';

  @override
  String get siFacMaturity => 'Maturity';

  @override
  String get siFacMaturityDesc => 'Account age + regularity = bonus.';

  @override
  String get siFacFrequency => 'Frequency Cap';

  @override
  String get siFacFrequencyDesc => 'Max. 2 badges/week. Anti-farming.';

  @override
  String get siBecomeOrganizer => 'BECOME AN ORGANIZER';

  @override
  String get siBecomeOrgDesc =>
      'Automatic promotion once you have enough Trust Score. Then create your own NFC tags and QR codes.';

  @override
  String siProgressLabel(Object name) {
    return 'PROGRESS ($name)';
  }

  @override
  String get siAlreadyOrganizer => 'You are already an organizer!';

  @override
  String get siIncreaseScore => 'INCREASE SCORE';

  @override
  String get siTip1 => 'Visit different meetups regularly';

  @override
  String get siTip2 => 'Collect badges at meetups in other cities';

  @override
  String get siTip3 => 'Badges from different organizers';

  @override
  String get siTip4 => 'Verify identity with a Lightning zap';

  @override
  String get siTip5 => 'Set up NIP-05';

  @override
  String get siTip6 => 'Link platforms';

  @override
  String siProgressRow(Object label, Object current, Object required) {
    return '$label: $current/$required';
  }

  @override
  String get wotTabNetwork => 'NETWORK';

  @override
  String get wotTabReports => 'REPORTS';

  @override
  String get wotHealthGood => 'HEALTHY';

  @override
  String get wotHealthBuilding => 'BUILDING';

  @override
  String get wotHealthCritical => 'CRITICAL';

  @override
  String get badgeUnknown => 'unknown';

  @override
  String get badgeBlockAtScan => '₿ Block height at scan';

  @override
  String get mwStartMeetup => 'START MEETUP';

  @override
  String get mwStep1Nfc => 'STEP 1: NFC TAG';

  @override
  String get mwNfcIntro1 =>
      'Do you want to place physical NFC tags (NTAG215) for this meetup? ';

  @override
  String get mwNfcIntro2 =>
      'The cryptographic proof (block time & signature) is fixed onto them.';

  @override
  String get mwWriteNfcTag => 'WRITE NFC TAG';

  @override
  String get mwSkipQrOnly => 'SKIP — USE QR ONLY';

  @override
  String repAllBound(Object total) {
    return 'All $total badges bound and verified';
  }

  @override
  String repBoundOf(Object total, Object bound) {
    return '$bound of $total badges identity-bound';
  }

  @override
  String repBoundExtra(Object verified) {
    return ' ($verified cryptographically verified)';
  }

  @override
  String repAllVerified(Object total) {
    return 'All $total badges cryptographically verified (not yet bound)';
  }

  @override
  String repVerifiedSchnorr(Object total, Object verified) {
    return '$verified of $total badges with Schnorr proof';
  }

  @override
  String repPlatformLinksActive(Object count) {
    return '$count platform links active';
  }

  @override
  String homeCouldNotOpen(Object url) {
    return 'Could not open $url';
  }

  @override
  String admWotLive(Object count) {
    return '✅ Your Web of Trust is live ($count relays)!';
  }

  @override
  String get admDelegationSigned =>
      '✅ Your delegation was cryptographically signed and published to the network!';

  @override
  String admWotCurrent(Object count) {
    return '✅ Web of Trust up to date ($count admins verified)';
  }

  @override
  String get admNoVouchesFound => '✅ No published vouches found on the relays';

  @override
  String admVouchesRestored(Object count) {
    return '✅ $count vouches restored';
  }

  @override
  String get admNoRelayReachable => '⚠️ No relay reachable — try again later';

  @override
  String get admAllVouchesRevoked =>
      '✅ All vouches have been revoked in the network';

  @override
  String get apHowStep3 => '3. Each scan = one badge for the participant\n';

  @override
  String get badgeSchnorrSig => 'Schnorr (Nostr v2) ✓';

  @override
  String msHomeMeetupSet(Object city) {
    return '✅ $city set as home meetup';
  }

  @override
  String mvKnownOrganizer(Object name) {
    return '✓ Known organizer: $name';
  }

  @override
  String get mvUnknownSigner =>
      '✗ UNKNOWN SIGNER!\nThis pubkey is not in the admin registry.';

  @override
  String get mvAdminCheckFailed =>
      '! Admin status could not be verified (offline?)';

  @override
  String get mvLegacyBadge => '! Legacy badge (v1) — signer not verifiable';

  @override
  String get mvBadgeBound => '🔗 Badge bound';

  @override
  String get nwSelectHomeMeetup =>
      '❌ Please select a home meetup in your profile first!';

  @override
  String qrUniqueRecipients(Object count) {
    return '$count different recipients';
  }

  @override
  String get apHowStep1 => '1. Start a new meetup (session).\n';

  @override
  String get apHowStep2 => '2. Then write NFC tags or show the QR code.\n';

  @override
  String get apHowStep4 =>
      '4. Badges build reputation → more reputation = new organizers';

  @override
  String get ppHowStep1 => '1. Choose a platform and enter your username\n';

  @override
  String get ppHowStep2 => '2. The app creates a cryptographic proof\n';

  @override
  String get ppHowStep3 =>
      '3. The proof is automatically embedded in your reputation QR\n';

  @override
  String get ppHowStep4 => '4. Others scan your QR and see the verified link';

  @override
  String admErrorEmoji(Object msg) {
    return '❌ Error: $msg';
  }

  @override
  String get admNoNewUpdates => '⚠️ No new updates found';

  @override
  String homeImageLoadError(Object msg) {
    return 'Image could not be loaded: $msg';
  }

  @override
  String qrSentCount(Object count) {
    return '$count sent';
  }

  @override
  String repShareError(Object msg) {
    return 'Error sharing: $msg';
  }

  @override
  String get rqNoHomeMeetup => '⚠️ No home meetup set';

  @override
  String get rqMeetupNotFound => '⚠️ Meetup not found';

  @override
  String get rlWhatMeans => 'What does this mean?';

  @override
  String get rlWhyImportant => 'Why this matters';

  @override
  String get rlWeakLabel => 'Weak profile';

  @override
  String get rlWeakExpl =>
      'Only one proof layer active. This user has few verifiable connections. For larger transactions: caution.';

  @override
  String get rlWeakAdvice =>
      'Ask for more proofs (Lightning, NIP-05) or meet the person in person first.';

  @override
  String get rlLimitedLabel => 'Limited';

  @override
  String get rlLimitedExpl =>
      'There are meetup badges, but no other independent proofs. The user might be real — but confirmation from other layers is missing.';

  @override
  String get rlLimitedAdvice =>
      'OK for tiny amounts. For larger amounts: wait until more layers are active.';

  @override
  String get rlBuildingLabel => 'Building';

  @override
  String get rlBuildingExpl =>
      'Two proof layers active. The user is building reputation but doesn\'t yet have full breadth.';

  @override
  String get rlBuildingAdvice => 'Suitable for moderate transactions.';

  @override
  String get rlConnectedLabel => 'Well connected';

  @override
  String get rlConnectedExpl =>
      'Multiple independent proofs: meetups, Lightning activity and social connections. Hard to fake.';

  @override
  String get rlConnectedAdvice => 'Trustworthy for most transactions.';

  @override
  String get rlSolidLabel => 'Solid';

  @override
  String get rlSolidExpl =>
      'Broad base of proofs. Manipulation would be laborious and expensive.';

  @override
  String get rlSolidAdvice => 'Trustworthy for most purposes.';

  @override
  String get rlDefaultExpl => 'Some proofs present, but room for more.';

  @override
  String get rlDefaultAdvice => 'Use your own judgment.';

  @override
  String get rlMeetupProofs => 'Meetup proofs';

  @override
  String get rlMeetupGood =>
      'Attended different meetups with different organizers. This requires physical presence in multiple places.';

  @override
  String get rlMeetupMoreDiverse => 'More diversity would be more convincing.';

  @override
  String get rlMeetupNone =>
      'No meetup badges present. This user hasn\'t attended an Einundzwanzig meetup yet — or has only recently started using the app.';

  @override
  String get rlAllBound => 'All cryptographically bound';

  @override
  String get rlGoodSpread => 'Good regional spread';

  @override
  String get rlLowSpread => 'Low spread';

  @override
  String rlPhysGoodDiversity(Object count) {
    return 'Has meetup badges, but only from $count organizer(s). More diversity would be more convincing.';
  }

  @override
  String rlBadgeCount(Object count) {
    return '$count badges';
  }

  @override
  String rlBoundOf(Object bound, Object total) {
    return '$bound of $total bound';
  }

  @override
  String rlDiffMeetups(Object count) {
    return '$count different meetups';
  }

  @override
  String rlOrganizers(Object count) {
    return '$count organizers';
  }

  @override
  String get rlConfirmedByDiff => 'Confirmed by different people';

  @override
  String get rlOneOrgOnly =>
      'Only one organizer — little independent confirmation';

  @override
  String rlMemberSince(Object since) {
    return 'Member since $since';
  }

  @override
  String rlDaysCount(Object count) {
    return '$count days';
  }

  @override
  String get rlLightningProof => 'Lightning proof';

  @override
  String get rlLnBoth =>
      'Has made and received real Lightning payments. Bots don\'t have Lightning wallets — a strong authenticity signal.';

  @override
  String get rlLnPaid =>
      'Has paid via Lightning at least once. Basic proof that a real wallet exists.';

  @override
  String get rlLnActiveOnly =>
      'Lightning activity present, but Proof of Humanity not yet active.';

  @override
  String get rlLnNone =>
      'No Lightning activity. This doesn\'t mean the user is fake — maybe they don\'t use Lightning via Nostr. But an important anti-bot signal is missing.';

  @override
  String get rlHumanVerified => 'Human verified';

  @override
  String get rlRealLnPayment => 'Real Lightning payment proven';

  @override
  String rlZapsSent(Object count) {
    return '$count zaps sent';
  }

  @override
  String rlToRecipients(Object count) {
    return 'To $count different recipients';
  }

  @override
  String rlZapsReceived(Object count) {
    return '$count zaps received';
  }

  @override
  String rlFromSenders(Object count) {
    return 'From $count different senders';
  }

  @override
  String rlMonthsActive(Object count) {
    return '$count months active';
  }

  @override
  String get rlSocialTitle => 'Social network';

  @override
  String get rlSocMutualMany =>
      'You know each other on Nostr and share many contacts. Strong connection.';

  @override
  String get rlSocMutual => 'Mutual follow — you know each other on Nostr.';

  @override
  String get rlSocCommon =>
      'Many shared contacts — you move in the same network.';

  @override
  String get rlSocOneSided =>
      'One-sided connection. You know each other vaguely.';

  @override
  String get rlSocOrgFollow =>
      'Known Einundzwanzig organizers follow this user. That\'s a positive signal.';

  @override
  String get rlSocDefault =>
      'There are connections in the Nostr network to this user.';

  @override
  String get rlSocNone =>
      'No connection found in the Nostr network. This could mean: you\'ve never met on Nostr, or the user is very new. Normal for strangers — a warning sign for supposedly familiar faces.';

  @override
  String get rlMutualFollow => 'Mutual follow';

  @override
  String get rlYouFollow => 'You follow';

  @override
  String get rlFollowsYou => 'Follows you';

  @override
  String get rlNoFollow => 'No follow';

  @override
  String get rlKnowOnNostr => 'You know each other on Nostr';

  @override
  String get rlNoDirectConn => 'No direct connection';

  @override
  String rlCommonContacts(Object count) {
    return '$count shared contacts';
  }

  @override
  String get rlSameNetwork => 'Same network';

  @override
  String get rlSomeOverlap => 'Some overlap';

  @override
  String get rlSeparateNetworks => 'Separate networks';

  @override
  String rlOrgsFollow(Object count) {
    return '$count organizers follow';
  }

  @override
  String get rlEndorsement => 'Endorsement from known admins';

  @override
  String get rlIdentityTitle => 'Identity proof';

  @override
  String get rlIdNip05Plat =>
      'Has a NIP-05 address and linked platforms. This ties the Nostr identity to a domain — harder to fake than an anonymous account.';

  @override
  String get rlIdNip05Only =>
      'Has a NIP-05 address. This ties the Nostr identity to a domain — harder to fake than an anonymous account.';

  @override
  String get rlIdPlatOnly =>
      'Linked platform accounts. More platforms = more effort for forgers.';

  @override
  String get rlIdNone =>
      'No internet identification. Completely anonymous. That\'s fine for privacy, but gives fewer trust indicators.';

  @override
  String get rlLinked => 'Linked';

  @override
  String get rlNoIdentification => 'No identification';

  @override
  String get rlAnonymous => 'Anonymous';

  @override
  String get rlActive => '✓ active';

  @override
  String get rlActiveShort => '✓ active';

  @override
  String get rlMissingShort => '— missing';

  @override
  String qrReceivedCount(Object count) {
    return '$count received';
  }

  @override
  String qrUniqueSenders(Object count) {
    return '$count different senders';
  }

  @override
  String rlProofsOfFour(Object count) {
    return '$count / 4 proofs';
  }

  @override
  String get navNearby => 'Nearby';

  @override
  String get nbTitle => 'MEETUPS NEARBY';

  @override
  String get nbRequestingLocation => 'Getting location...';

  @override
  String get nbLoading => 'Loading meetups...';

  @override
  String get nbLocationDenied => 'Location access denied';

  @override
  String get nbLocationDeniedSub =>
      'Without location we show all meetups sorted by date. Enable location in settings to see distances.';

  @override
  String get nbServiceDisabled => 'Location services are disabled';

  @override
  String get nbRetryLocation => 'Try location again';

  @override
  String get nbContinueWithout => 'Continue without location';

  @override
  String get nbNoMeetups => 'No meetups for this period';

  @override
  String get nbNoMeetupsSub => 'Try a different filter or date.';

  @override
  String get nbFilterToday => 'Today';

  @override
  String get nbFilterWeek => 'This week';

  @override
  String get nbFilterUpcoming => 'All upcoming';

  @override
  String get nbFilterAll => 'All';

  @override
  String get nbPickDate => 'Pick date';

  @override
  String nbKmAway(Object km) {
    return '$km km away';
  }

  @override
  String get nbNoDate => 'No date announced';

  @override
  String nbListHeader(Object count) {
    return '$count meetups';
  }

  @override
  String get nbOpenInMaps => 'Open in maps';

  @override
  String get nbYourLocation => 'Your location';

  @override
  String get nbToday => 'Today';

  @override
  String get nbTomorrow => 'Tomorrow';

  @override
  String get nbResetDate => 'Reset filter';

  @override
  String get nbModeHere => 'Here & now';

  @override
  String get nbModePlanned => 'Planned';

  @override
  String get nbRadius => 'Radius';

  @override
  String nbRadiusValue(Object km) {
    return '$km km';
  }

  @override
  String get nbSearchPlace => 'Search place (e.g. Hamburg)';

  @override
  String get nbSearchingPlace => 'Searching places...';

  @override
  String get nbNoPlaceFound => 'No place found';

  @override
  String get nbCenterHere => 'My location';

  @override
  String get nbChangePlace => 'Change place';

  @override
  String get nbDateAny => 'Anytime';

  @override
  String get nbDateSingle => 'Date';

  @override
  String get nbDateRange => 'Range';

  @override
  String get nbPickDay => 'Pick day';

  @override
  String get nbPickRange => 'Pick range';

  @override
  String nbDateFromTo(Object from, Object to) {
    return '$from – $to';
  }

  @override
  String nbResultsHeader(Object count) {
    return '$count meetups in range';
  }

  @override
  String get nbNoneInRadius => 'No meetups in range';

  @override
  String get nbNoneInRadiusSub => 'Increase the radius or change place/date.';

  @override
  String get nbApplySearch => 'Search';

  @override
  String nbMoreDates(Object count) {
    return '+$count more dates';
  }

  @override
  String get nbDirections => 'Directions';

  @override
  String get nbDetails => 'Details';

  @override
  String get settingsSectionProfile => 'Profile';

  @override
  String get settingsProfile => 'Edit profile';

  @override
  String get settingsProfileSub => 'Name, Nostr key & home meetup';

  @override
  String get apCreateEvent => 'Create event';

  @override
  String get apCreateEventSub => 'Add in the portal';

  @override
  String get apCreateEventTitle => 'Create event in portal';

  @override
  String get apCreateEventBody =>
      'Meetup events are managed centrally in the Einundzwanzig portal. The app will now open the portal in your browser — log in there with your Nostr key and add the event. It then appears here in the calendar automatically.';

  @override
  String get apOpenPortal => 'Open portal';

  @override
  String get apNoHomeMeetupSet =>
      'Select your home meetup in your profile first, then you can create events for it.';

  @override
  String get apPortalHint =>
      'Why not directly in the app? The portal is the central source for all events and requires your login. Direct creation from the app is planned once the portal supports it.';

  @override
  String get rcTitle => 'Reputation Profile';

  @override
  String get rcShareImage => 'Share as image';

  @override
  String get rcSaving => 'Creating image...';

  @override
  String rcShareError(Object error) {
    return 'Sharing failed: $error';
  }

  @override
  String get rcShareText => 'My Einundzwanzig Trust Score & Reputation';

  @override
  String get rcLabelScore => 'Trust Score';

  @override
  String get rcLabelLevel => 'Level';

  @override
  String get rcLabelBadges => 'Badges';

  @override
  String get rcLabelMeetups => 'Meetups';

  @override
  String get rcLabelCities => 'Cities';

  @override
  String get rcLabelSigners => 'Signers';

  @override
  String get rcLabelAge => 'Days active';

  @override
  String get rcMember => 'Einundzwanzig member';

  @override
  String get rcNoData => 'No reputation yet. Collect badges at meetups!';

  @override
  String get tpTitle => 'Trust Path';

  @override
  String get tpSubtitle => 'Who connects you to this person?';

  @override
  String get tpEnterNpub => 'Enter person\'s npub';

  @override
  String get tpScan => 'Scan npub';

  @override
  String get tpFind => 'Find path';

  @override
  String get tpSearching => 'Searching network...';

  @override
  String tpFound(Object count) {
    return 'Connected through $count hops';
  }

  @override
  String get tpDirect => 'Directly connected';

  @override
  String get tpYou => 'You';

  @override
  String get tpTarget => 'Target';

  @override
  String get tpVouchesFor => 'vouches for';

  @override
  String get tpNoPath => 'No trust path found';

  @override
  String get tpNoPathSelf =>
      'You\'re not in the vouching network yet. Get vouched by admins to see paths.';

  @override
  String get tpNoPathTarget =>
      'This person isn\'t in the vouching network (yet).';

  @override
  String get tpNoPathBetween =>
      'There\'s currently no known vouching chain between you.';

  @override
  String get tpInvalidNpub => 'Invalid npub';

  @override
  String get tpUnknown => 'Unknown';

  @override
  String get tpHint =>
      'Based on the public vouching network (Web of Trust). Only shows connections via vouching members.';

  @override
  String get caOptInTitle => 'Contribute to trust network?';

  @override
  String get caOptInBody =>
      'You can confirm your attendance at this meetup in the public trust network. Others will then see that your npub was at this meetup — and how you\'re connected through shared meetups.\n\nThis is optional. You get your badge regardless.';

  @override
  String get caOptInPrivacy =>
      'Public & permanent on Nostr relays. Reveals a movement and contact pattern. Consider carefully.';

  @override
  String get caOptInYes => 'Yes, contribute';

  @override
  String get caOptInNo => 'No, stay private';

  @override
  String get caPublished => 'Attendance confirmed in network';

  @override
  String get cnTitle => 'Network analysis';

  @override
  String get cnSubtitle =>
      'How is this person connected through shared meetups?';

  @override
  String get cnEnterNpub => 'Enter person\'s npub';

  @override
  String get cnScan => 'Scan';

  @override
  String get cnAnalyze => 'Analyze';

  @override
  String get cnLoading => 'Loading network...';

  @override
  String get cnSharedMeetups => 'Shared meetups';

  @override
  String get cnMutualContacts => 'Mutual contacts';

  @override
  String get cnReach => 'Person\'s reach';

  @override
  String get cnTotalMeetups => 'Meetups attended';

  @override
  String get cnTotalContacts => 'People met';

  @override
  String get cnNoConnection => 'No connection found';

  @override
  String get cnNoConnectionSub =>
      'You haven\'t been to shared meetups and have no mutual contacts — or this person doesn\'t participate in the network.';

  @override
  String get cnDirectMet => 'You\'ve met directly!';

  @override
  String get cnYou => 'You';

  @override
  String get cnTarget => 'This person';

  @override
  String cnViaShared(Object count) {
    return 'via $count shared meetups';
  }

  @override
  String get cnTrustHint =>
      'More shared meetups and contacts mean stronger organic trust.';

  @override
  String get cnInvalidNpub => 'Invalid npub';

  @override
  String get cnPrivacyNote => 'Only shows people who opted into the network.';

  @override
  String get tileTrustNetwork => 'Trust network';

  @override
  String get tileTrustNetworkSub => 'Check connections';

  @override
  String get tnHubTitle => 'Trust network';

  @override
  String get tnHubIntro =>
      'Check how trustworthy a person is in the Einundzwanzig network — through vouches and shared meetups.';

  @override
  String get tnHubPathTitle => 'Trust path';

  @override
  String get tnHubPathSub => 'Who connects you to a person? (vouching chain)';

  @override
  String get tnHubNetTitle => 'Network analysis';

  @override
  String get tnHubNetSub => 'A person\'s shared meetups & contacts';

  @override
  String get orgBadgeCreated => 'Organizer attendance recorded';

  @override
  String get orgBadgeLabel => 'Organizer';

  @override
  String get orgBadgeSub => 'You hosted this meetup';

  @override
  String get mnTitle => 'My network';

  @override
  String get mnIntro =>
      'Your trust network from real meetup encounters — and who\'s connected to you beyond that.';

  @override
  String get mnLoading => 'Building network...';

  @override
  String get mnEmpty => 'No connections yet';

  @override
  String get mnEmptySub =>
      'Attend meetups and collect badges (with network participation) to build your trust network.';

  @override
  String get mnDegree1 => 'Met directly';

  @override
  String get mnDegree1Sub => 'People you met live at meetups';

  @override
  String get mnDegree2 => 'Connected via contacts';

  @override
  String get mnDegree2Sub => 'People your contacts met at meetups';

  @override
  String get mnDegree3 => 'Extended network';

  @override
  String get mnDegree3Sub => 'One more level out in the network';

  @override
  String mnSharedMeetups(Object count) {
    return '$count shared meetups';
  }

  @override
  String get mnOneSharedMeetup => '1 shared meetup';

  @override
  String mnViaContacts(Object count) {
    return 'via $count contacts';
  }

  @override
  String get mnViaOneContact => 'via 1 contact';

  @override
  String get mnReachLabel => 'Reach';

  @override
  String get mnDirectLabel => 'Direct';

  @override
  String get mnIndirectLabel => 'Indirect';

  @override
  String get mnTrustHint =>
      'Indirect contacts through real encounters gradually increase your trust — even without having met the person yourself.';

  @override
  String get mnPrivacyNote =>
      'Only shows people who participate in the network (opt-in at badge scan).';

  @override
  String get mnCheckPerson => 'Check specific person';

  @override
  String get settingsHeaderTitle => 'Settings';

  @override
  String get settingsHeaderSub => 'Manage app & account';

  @override
  String get settingsSecAccount => 'ACCOUNT';

  @override
  String get settingsSecData => 'DATA & SECURITY';

  @override
  String get settingsSecNetwork => 'NETWORK';

  @override
  String get settingsSecApp => 'APP';

  @override
  String get settingsSecDanger => 'DANGER ZONE';

  @override
  String get vpTitle => 'Verify person';

  @override
  String get vpIntro =>
      'Check via real meetup encounters whether and how this person is connected to you.';

  @override
  String get vpEnterNpub => 'Enter npub or scan reputation QR';

  @override
  String get vpScanQr => 'Scan QR';

  @override
  String get vpCheck => 'Verify';

  @override
  String get vpChecking => 'Checking connection...';

  @override
  String get vpDirectTitle => 'Met directly!';

  @override
  String vpDirectSub(Object count) {
    return 'You\'ve been to $count meetups together.';
  }

  @override
  String get vpDirectSubOne => 'You\'ve been to a meetup together.';

  @override
  String vpIndirectTitle(Object count) {
    return 'Connected through $count hops';
  }

  @override
  String get vpIndirectSub =>
      'This person is connected to you through real meetup encounters.';

  @override
  String get vpNoneTitle => 'No connection found';

  @override
  String get vpNoneSub =>
      'There\'s currently no known meetup connection to you.';

  @override
  String get vpNotInNetwork => 'This person isn\'t in the network (yet).';

  @override
  String get vpPathTitle => 'Connection path';

  @override
  String get vpYou => 'You';

  @override
  String get vpTarget => 'This person';

  @override
  String get vpMetAt => 'shared meetup';

  @override
  String get vpInvalidNpub => 'Invalid npub';

  @override
  String get vpTrustNote =>
      'The closer the connection (lower degree), the stronger the trust via physical presence.';

  @override
  String get vpSelfTitle => 'That\'s you';
}
