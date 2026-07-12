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
  String get profileNostrKey => 'NOSTR SCHLÜSSEL';

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

  @override
  String get tileTrustScore => 'Trust Score';

  @override
  String get tileReputation => 'Reputation';

  @override
  String get tileReputationShare => 'QR teilen';

  @override
  String get tileReputationCheck => 'Prüfen';

  @override
  String get tileCommunity => 'Community';

  @override
  String get tileCommunityPortal => 'Portal';

  @override
  String get tileEvents => 'Events';

  @override
  String get tileEventsCalendar => 'Kalender';

  @override
  String get tileShoutout => 'Shoutout';

  @override
  String get tileShoutoutSend => 'Senden';

  @override
  String get tilePodcast => 'Podcast';

  @override
  String get tilePodcastListen => 'Anhören';

  @override
  String get tileNostr => 'Nostr';

  @override
  String get tileNostrCommunity => 'Community';

  @override
  String get tileOrganizer => 'Organisator';

  @override
  String get tileOrganizerPanel => 'Admin-Panel';

  @override
  String get tileOrganizerNew => 'Neu via Trust Score';

  @override
  String get tileWot => 'WoT';

  @override
  String get tileWotSubtitle => 'Web of Trust';

  @override
  String get homeMeetupLabel => 'HOME MEETUP';

  @override
  String get homeMeetupChoose => 'Wähle deinen Stammtisch';

  @override
  String get homeMeetupChooseSub => 'Dein regelmäßiges Meetup auswählen';

  @override
  String homeMeetupBadges(int count) {
    return '$count Badges';
  }

  @override
  String get homeMeetupToday => 'Heute!';

  @override
  String get homeMeetupTomorrow => 'Morgen';

  @override
  String homeMeetupInDays(int days) {
    return 'in $days Tagen';
  }

  @override
  String get homeMeetupNoDate => 'Kein Termin geplant';

  @override
  String get homeMeetupNextEvent => 'Nächstes Meetup';

  @override
  String get homeMeetupNoneSoon =>
      'Kein Termin in Sicht.\nWird Zeit, das zu ändern!';

  @override
  String get homeMeetupSelectFirst => 'Erst Home Meetup\nwählen!';

  @override
  String get btnEvents => 'EVENTS';

  @override
  String get statusLive => 'LIVE';

  @override
  String get statusMeetupActive => 'Meetup aktiv';

  @override
  String get loading => 'Lade...';

  @override
  String get organizerPromoted => 'Du bist jetzt ORGANISATOR!';

  @override
  String get resetTitle => 'App zurücksetzen?';

  @override
  String get resetBody => 'Alle Badges und dein Profil werden gelöscht.';

  @override
  String get resetCancel => 'Abbruch';

  @override
  String get resetConfirm => 'LÖSCHEN';

  @override
  String get settingsSectionBackup => 'DATENSICHERUNG';

  @override
  String get settingsSectionLanguage => 'SPRACHE';

  @override
  String get settingsSectionNostr => 'NOSTR-NETZWERK';

  @override
  String get settingsSectionControl => 'BEDIENUNG';

  @override
  String get settingsSectionAccount => 'ACCOUNT';

  @override
  String get settingsBackup => 'Backup erstellen';

  @override
  String get settingsBackupSub => 'Sichere deinen Account';

  @override
  String get settingsLanguageTitle => 'Sprache';

  @override
  String get settingsLanguageChoose => 'Sprache wählen';

  @override
  String get settingsRelays => 'Nostr-Relays';

  @override
  String get settingsRelaysSub => 'Relays konfigurieren';

  @override
  String get settingsHaptic => 'Vibrationsfeedback';

  @override
  String get settingsHapticOn => 'Aktiv';

  @override
  String get settingsHapticOff => 'Deaktiviert';

  @override
  String get settingsReset => 'App zurücksetzen';

  @override
  String get settingsResetSub => 'Löscht Profil und Badges';

  @override
  String get introTagline => 'DEINE BITCOIN COMMUNITY';

  @override
  String get introJoin => 'COMMUNITY BETRETEN';

  @override
  String get introLoadBackup => 'BACKUP LADEN';

  @override
  String get introSetIdentity => 'Bitte lege zuerst deine Identität fest.';

  @override
  String get navWalletTab => 'Wallet';

  @override
  String get navProfileTab => 'Profil';

  @override
  String get scanBadge => 'Badge scannen';

  @override
  String get scanBadgeSub => 'QR-Code oder NFC-Tag vom Meetup';

  @override
  String get scanReputation => 'Reputation prüfen';

  @override
  String get scanReputationSub =>
      'Trust Score einer anderen Person verifizieren';

  @override
  String get calendarTitle => 'MEETUP TERMINE';

  @override
  String get calendarSearch => 'Suche (z.B. München, Bitcoin...)';

  @override
  String get calendarNoEvents => 'Keine Termine gefunden.';

  @override
  String get sectionDescription => 'BESCHREIBUNG';

  @override
  String get sectionLocation => 'STANDORT';

  @override
  String get sectionDates => 'TERMINE';

  @override
  String get sectionLinks => 'LINKS';

  @override
  String get meetupRoute => 'Route';

  @override
  String get meetupNoDatesCal => 'Aktuell keine Termine im Kalender.';

  @override
  String get errorOpenLink => 'Konnte Link nicht öffnen';

  @override
  String get walletNoBadges => 'Noch keine Badges gesammelt';

  @override
  String get walletNoBadgesSub =>
      'Besuche Meetups und scanne NFC-Tags um Badges zu sammeln!';

  @override
  String get walletShareReputation => 'REPUTATION TEILEN';

  @override
  String get walletShowQr => 'QR-Code anzeigen';

  @override
  String get walletShowQrSub => 'Zum Scannen vor Ort';

  @override
  String get walletExportJson => 'Als JSON exportieren';

  @override
  String get walletExportJsonSub => 'Signierter Export mit Schnorr-Beweis';

  @override
  String get walletShareText => 'Als Text teilen';

  @override
  String get walletShareTextSub => 'Lesbar für alle (wird im Web kopiert)';

  @override
  String get walletShareTitle => 'Reputation teilen';

  @override
  String get walletJsonCopied => 'JSON-Daten in Zwischenablage kopiert';

  @override
  String get walletReputationCopied => 'Reputation in Zwischenablage kopiert';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get badgeDetailsTitle => 'Badge-Details';

  @override
  String get badgeShare => 'Badge teilen';

  @override
  String get badgeShareCaps => 'BADGE TEILEN';

  @override
  String get badgeClose => 'SCHLIESSEN';

  @override
  String get badgeProofTitle => 'Kryptographischer Beweis';

  @override
  String get badgeProofOfAttendance => 'PROOF OF ATTENDANCE';

  @override
  String get badgeProofDesc =>
      'Dieses Badge bestätigt kryptografisch, dass du physisch vor Ort warst.';

  @override
  String get badgeMeetup => 'Meetup';

  @override
  String get badgeMeetupDate => 'Meetup-Datum';

  @override
  String get badgeMeetupId => 'Meetup-ID';

  @override
  String get badgeOrganizerNpub => 'Organisator (npub)';

  @override
  String get badgeSignatureType => 'Signaturtyp';

  @override
  String get badgeTransmission => 'Übertragungsweg';

  @override
  String get badgeTimestamp => 'Zeitstempel';

  @override
  String get badgeScanTime => 'Scan-Zeitpunkt';

  @override
  String get badgeVerificationHash => 'VERIFIKATIONS-HASH';

  @override
  String get badgeClaimBinding => 'Claim-Binding';

  @override
  String get badgeBound => 'Gebunden ✓';

  @override
  String get badgeNotBound => 'Nicht gebunden';

  @override
  String get badgeClaimedLater => 'Nachträglich geclaimed';

  @override
  String get badgeNote => 'Hinweis';

  @override
  String get badgeNoSignature => 'Keine Signatur';

  @override
  String get badgeHashCopied => 'Hash kopiert';

  @override
  String get badgeInfoCopied => 'Badge-Info in Zwischenablage kopiert';

  @override
  String get badgeNfcTag => 'NFC-Tag';

  @override
  String get badgeRollingQr => 'Rolling QR-Code';

  @override
  String get levelNew => 'NEU';

  @override
  String get levelStarter => 'STARTER';

  @override
  String get levelActive => 'AKTIV';

  @override
  String get levelEstablished => 'ETABLIERT';

  @override
  String get levelVeteran => 'VETERAN';

  @override
  String get reputationTitle => 'REPUTATION';

  @override
  String get reputationNoBadges => 'NOCH KEINE BADGES';

  @override
  String get reputationNoProofs => 'Noch keine kryptographischen Beweise';

  @override
  String get reputationBuildHint1 =>
      'Besuche ein Meetup und scanne einen Badge um ';

  @override
  String get reputationBuildHint2 => 'deine Reputation aufzubauen.';

  @override
  String get reputationScanQr => 'QR-CODE SCANNEN';

  @override
  String get reputationShareImage => 'QR ALS BILD TEILEN';

  @override
  String get reputationUpdateRelays => 'AUF RELAYS AKTUALISIEREN';

  @override
  String get reputationPublishing => 'PUBLIZIERE...';

  @override
  String get reputationBadges => 'Badges';

  @override
  String get reputationMeetups => 'Meetups';

  @override
  String get reputationSigners => 'Signer';

  @override
  String get reputationBound => 'Gebunden';

  @override
  String get reputationSchnorrSigned => 'Schnorr-signiert';

  @override
  String get reputationSignedNoId => 'Signiert (ohne Identität)';

  @override
  String get reputationNoIdentity =>
      'Keine Identität verknüpft. Ergänze Telegram oder Nostr in deinem Profil.';

  @override
  String get reputationCheck => 'Reputation prüfen';

  @override
  String get reputationVerified => 'Meine verifizierte Meetup-Reputation';

  @override
  String get reputationCodeFrom => 'Reputationscode von';

  @override
  String get portalDiscover => 'ENTDECKEN';

  @override
  String get portalQuickAccess => 'SCHNELLZUGRIFF';

  @override
  String get portalPodcastMedia => 'PODCAST & MEDIA';

  @override
  String get portalSocialNetworks => 'SOZIALE NETZWERKE';

  @override
  String get portalAssociation => 'VEREIN';

  @override
  String get portalProfile => 'Dein Profil & Badges';

  @override
  String get portalMeetupMap => 'Meetup-Karte';

  @override
  String get portalMeetupMapSub => 'Treffen in deiner Nähe';

  @override
  String get portalBeginnerPath => 'Der Weg (Einsteiger)';

  @override
  String get portalShoutoutSend => 'Shoutout senden';

  @override
  String get portalMembership => 'Mitglied werden';

  @override
  String get portalSoundboard => 'Soundboard';

  @override
  String get portalClipsSounds => 'Clips & Sounds';

  @override
  String get portalInterviews => 'Interviews';

  @override
  String get portalMediaArticles => 'Media & Artikel';

  @override
  String get portalMerch => 'Merch & Bitcoin-Produkte';

  @override
  String get portalShop => 'Shop';

  @override
  String get portalDonate => 'Spenden';

  @override
  String get portalContact => 'Kontakt';

  @override
  String get portalPrivacy => 'Datenschutz';

  @override
  String get portalStatutes => 'Satzung (PDF)';

  @override
  String get portalAboutAssoc => 'Über den Verein';

  @override
  String get portalOpen => 'Portal öffnen';

  @override
  String get portalTagline => 'für bullishe Bitcoiner.';

  @override
  String get portalInfotainment => 'Toximalistisches Infotainment';

  @override
  String get portalPodcast => 'Podcast';

  @override
  String get portalProfile2 => 'Portal';

  @override
  String get profileTitle => 'DEIN PROFIL';

  @override
  String get profileEditTitle => 'PROFIL BEARBEITEN';

  @override
  String get profileSave => 'PROFIL SPEICHERN';

  @override
  String get profileIntro => 'Wähle einen Nickname und dein Home-Meetup.';

  @override
  String get profileNicknameMin => 'Mindestens 2 Zeichen';

  @override
  String get profileNicknameReq => 'Pflichtfeld — bitte ausfüllen';

  @override
  String get profileNicknameAnon =>
      'Bitte wähle einen eigenen Nickname (nicht \'Anon\')';

  @override
  String get profileHomeMeetup => 'Home Meetup';

  @override
  String get profileHomeMeetupDash => 'Home-Meetup';

  @override
  String get profileChooseMeetup => 'Wähle dein Home-Meetup';

  @override
  String get profileMeetupReq => 'Pflichtfeld — bitte wähle dein Home-Meetup';

  @override
  String get profileSearchCity => 'Stadt suchen...';

  @override
  String get profileIdentity => 'DEINE IDENTITÄT';

  @override
  String get profileStrengthen => 'IDENTITÄT STÄRKEN';

  @override
  String get profileStrengthenDesc =>
      'Verknüpfe Plattformen und beweise deine Menschlichkeit um deinen Trust Score zu erhöhen.';

  @override
  String get profileLinkPlatforms => 'Plattformen verknüpfen';

  @override
  String get profilePlatformsSub => 'Telegram, X, Kleinanzeigen';

  @override
  String get profileProofHumanity => 'Proof of Humanity';

  @override
  String get profileZapCheck => 'Einmal gezappt? Jetzt prüfen';

  @override
  String get profileLightningActive => 'Lightning-Beweis aktiv';

  @override
  String get profileVerified => 'VERIFIZIERT';

  @override
  String get profileNostrKeyShort => 'Nostr';

  @override
  String get profileNoKey => 'Noch kein Nostr-Key vorhanden';

  @override
  String get profileKeyActiveCaps => 'SCHLÜSSEL AKTIV';

  @override
  String get profileCreateKey => 'NOSTR KEY ERSTELLEN';

  @override
  String get profileCreateNewKey => 'NEUEN KEY ERSTELLEN';

  @override
  String get profileCreating => 'WIRD ERSTELLT...';

  @override
  String get profileNoNostrNeeded =>
      'Du brauchst kein Nostr-Konto. Die App erstellt dir einen Schlüssel — das dauert eine Sekunde.';

  @override
  String get profileKeyDesc =>
      'Dein kryptografischer Schlüssel — damit werden Badges signiert und deine Reputation verifiziert.';

  @override
  String get profileConnectAmber => 'MIT AMBER VERBINDEN';

  @override
  String get profileAmberDesc =>
      'Amber ist ein separater Signer für Android, der deinen privaten ';

  @override
  String get profileAmberConnected =>
      'Mit Amber verbunden! Dein nsec bleibt in Amber.';

  @override
  String get profileAmberNotFound => 'Amber nicht gefunden';

  @override
  String get profileAmberInstall =>
      'Schlüssel sicher verwahrt. Installiere Amber (z.B. über F-Droid ';

  @override
  String get profileAmberRetry => 'oder den Zapstore) und versuche es erneut.';

  @override
  String get profileAmberAborted => 'Verbindung in Amber abgebrochen.';

  @override
  String get profileImportNsec => 'BESTEHENDEN NSEC IMPORTIEREN';

  @override
  String get profileImportNsecShort => 'NSEC IMPORTIEREN';

  @override
  String get profileImport => 'IMPORTIEREN';

  @override
  String get profileEnterNsec =>
      'Gib deinen privaten Nostr-Schlüssel ein (beginnt mit nsec1...):';

  @override
  String get profileKeyImported => 'Key importiert!';

  @override
  String get profileShowNsecQ => 'NSEC ANZEIGEN?';

  @override
  String get profileShowNsecWarn =>
      'Dein privater Schlüssel wird angezeigt. Stelle sicher, dass niemand auf deinen Bildschirm schaut!';

  @override
  String get profileShow => 'ANZEIGEN';

  @override
  String get profileCopy => 'KOPIEREN';

  @override
  String get profileSecureKey => 'SICHERE DEINEN KEY!';

  @override
  String get profileSaveKeyDesc =>
      'Dies ist dein privater Schlüssel. Speichere ihn an einem sicheren Ort! ';

  @override
  String get profileKeyNotShownAgain =>
      'Dieser Key wird NICHT nochmal angezeigt!';

  @override
  String get profileKeySecured => 'ICH HAB IHN GESICHERT';

  @override
  String get profileNpubCopied => 'npub kopiert!';

  @override
  String get profileNsecCopied => 'nsec kopiert! Jetzt sicher abspeichern.';

  @override
  String get profileNsecNeverLeaves => 'Dein nsec verlässt niemals dein Gerät.';

  @override
  String get profileWhoHasKey => 'Wer diesen Key hat, HAT deine Identität.';

  @override
  String get profileBackupNsec =>
      'Wichtig: Sichere deinen nsec! Wenn du dein Gerät verlierst, ist dein Key weg.';

  @override
  String get profileNewKeypairDesc =>
      'Es wird ein neues Schlüsselpaar erstellt. Dein privater Schlüssel (nsec) wird sicher auf deinem Gerät gespeichert.\n\n';

  @override
  String get profileEdit => 'Bearbeiten';

  @override
  String get profileEditLoseStatus => 'BEARBEITEN (Status verlieren)';

  @override
  String get profileWarning => 'Achtung!';

  @override
  String get profileEditWarnDesc =>
      'Wenn du bearbeitest, verlierst du deinen \'Verifiziert\'-Status und musst neu freigeschaltet werden.';

  @override
  String get dialogCancel => 'ABBRECHEN';

  @override
  String get dialogCancelMixed => 'Abbrechen';

  @override
  String get dialogCreate => 'ERSTELLEN';

  @override
  String errorGeneric(String msg) {
    return 'Fehler: $msg';
  }

  @override
  String errorAmber(String msg) {
    return 'Amber-Fehler: $msg';
  }

  @override
  String profileFillIn(Object fields) {
    return 'Bitte ausfüllen: $fields';
  }

  @override
  String get backupEncryptTitle => 'Backup verschlüsseln';

  @override
  String get backupDecryptTitle => 'Backup entschlüsseln';

  @override
  String get backupExportDesc =>
      'Vergib ein Passwort, um deinen privaten Schlüssel (nsec) im Backup zu schützen.\n\n⚠️ Wenn du dieses Passwort vergisst, ist das Backup UNWIEDERBRINGLICH verloren!';

  @override
  String get backupImportDesc =>
      'Dieses Backup ist verschlüsselt. Bitte gib das Passwort ein.';

  @override
  String get backupPassword => 'Passwort';

  @override
  String get backupPasswordConfirm => 'Passwort bestätigen';

  @override
  String get backupPasswordEmpty => 'Passwort darf nicht leer sein';

  @override
  String get backupPasswordMin => 'Mindestens 8 Zeichen';

  @override
  String get backupPasswordMismatch => 'Passwörter stimmen nicht überein';

  @override
  String get backupEncryptSave => 'Verschlüsseln & Speichern';

  @override
  String get backupDecryptLoad => 'Entschlüsseln & Laden';

  @override
  String get backupShareTitle => 'Einundzwanzig App Backup (Verschlüsselt)';

  @override
  String get backupShareText =>
      'Dein verschlüsseltes Backup. Halte dein Passwort bereit, um es wiederherzustellen.';

  @override
  String backupError(String msg) {
    return 'Fehler beim Backup: $msg';
  }

  @override
  String get backupCorrupt => 'Backup-Datei ist beschädigt (Formatfehler).';

  @override
  String get backupWrongPassword => 'Falsches Passwort oder Datei beschädigt!';

  @override
  String get backupNotValid =>
      'Datei ist kein gültiges Backup oder das falsche Format.';

  @override
  String get backupNotEinundzwanzig =>
      'Datei ist kein gültiges Einundzwanzig Backup.';

  @override
  String backupLoaded(Object items) {
    return '✅ Backup geladen! $items wiederhergestellt.';
  }

  @override
  String backupImportFailed(String msg) {
    return 'Import fehlgeschlagen: $msg';
  }

  @override
  String get qrScanTitle => 'REPUTATION PRÜFEN';

  @override
  String get qrResultTitle => 'ERGEBNIS';

  @override
  String get qrScanHint => 'Scanne einen Einundzwanzig\nReputation QR-Code';

  @override
  String get qrLoadFromGallery => 'QR AUS GALERIE LADEN';

  @override
  String get qrBack => 'ZURÜCK';

  @override
  String get qrNoCodeInImage => 'Kein QR-Code im Bild gefunden';

  @override
  String get qrNotEinundzwanzig =>
      'QR-Code gefunden, aber kein Einundzwanzig-Format';

  @override
  String get qrVerified => 'VERIFIZIERT';

  @override
  String get qrVerifiedV1 => 'VERIFIZIERT (v1)';

  @override
  String get qrVerifiedV2 => 'VERIFIZIERT (v2)';

  @override
  String get qrSigInvalid => 'SIGNATUR UNGÜLTIG';

  @override
  String get qrFormatUnknown => 'FORMAT UNBEKANNT';

  @override
  String get qrReadError => 'LESEFEHLER';

  @override
  String get qrV2Subtitle => 'Legacy-Signatur gültig — kein Badge-Proof';

  @override
  String get qrV1Subtitle => 'Älteres Format — keine Identitätsbindung';

  @override
  String get qrCantRead => 'QR-Code konnte nicht gelesen werden.';

  @override
  String qrProcessError(String msg) {
    return 'Fehler beim Verarbeiten: $msg';
  }

  @override
  String get qrSectionIdentity => 'IDENTITÄT';

  @override
  String get qrNoIdentity => 'KEINE IDENTITÄT';

  @override
  String get qrNoVerifiableIdentity => 'Keine verifizierbare Identität.';

  @override
  String get qrSectionLightning => 'LIGHTNING';

  @override
  String get qrSectionSocial => 'SOZIALES NETZWERK';

  @override
  String get qrSectionPlatforms => 'VERKNÜPFTE PLATTFORMEN';

  @override
  String get qrSectionMeetups => 'BESUCHTE MEETUPS';

  @override
  String get qrHumanVerified => 'Mensch verifiziert';

  @override
  String get qrLightningActive => 'Lightning-Beweis aktiv';

  @override
  String get qrNoLightning => 'Kein Lightning-Beweis gefunden';

  @override
  String get qrNoZap => 'Keine Zap-Aktivität';

  @override
  String get qrNip05Invalid => 'NIP-05 ungültig';

  @override
  String get qrYouFollow => 'Du folgst';

  @override
  String get qrFollowsYou => 'Folgt dir';

  @override
  String get qrMutualFollow => 'Gegenseitiger Follow';

  @override
  String get qrNoDirectFollow => 'Kein direkter Follow';

  @override
  String get qrDirectConnection => 'Direkte Verbindung';

  @override
  String get qrBidirectional => 'Direkte bidirektionale Verbindung';

  @override
  String get qrOneWay => 'Einseitige Verbindung';

  @override
  String get qrViaContacts => 'Über gemeinsame Kontakte';

  @override
  String get qrStrongOverlap => 'Starke Netzwerk-Überlappung';

  @override
  String get qrPartiallyConnected => 'Teilweise verbunden';

  @override
  String get qrNoOverlap => 'Keine Überlappung';

  @override
  String get qrEndorsement => 'Endorsement von bekannten Admins';

  @override
  String get qrSigVerified => 'Signatur verifiziert';

  @override
  String get qrAnalyzingNetwork => 'Analysiere Netzwerk...';

  @override
  String get qrCheckingLightning => 'Prüfe Lightning...';

  @override
  String get qrCheckingNip05 => 'Prüfe NIP-05...';

  @override
  String get qrStatBadges => 'Badges';

  @override
  String get qrStatMeetups => 'Meetups';

  @override
  String get qrStatSigners => 'Signer';

  @override
  String get qrStatBound => 'Gebunden';

  @override
  String get qrStatDays => 'Tage';

  @override
  String get qrLabelNickname => 'Nickname';

  @override
  String get qrLabelTwitter => 'Twitter/X';

  @override
  String get qrPlatformOther => 'Andere';

  @override
  String get qrLinked => 'Verknüpft';

  @override
  String get qrSigVerifiedShort => 'Signatur verifiziert';

  @override
  String get qrLinkedShort => 'Verknüpft';

  @override
  String get nfcDisabled => 'NFC ist deaktiviert';

  @override
  String get nfcDisabledHint => 'NFC ist deaktiviert. Bitte einschalten.';

  @override
  String get nfcUnavailable => 'NFC nicht verfügbar';

  @override
  String get nfcOpenSettings => 'EINSTELLUNGEN ÖFFNEN';

  @override
  String get nfcEnableHint =>
      'Bitte aktiviere NFC in deinen Geräteeinstellungen, ';

  @override
  String get nfcSettingsAndroid =>
      'Android: Einstellungen → Verbindungen → NFC';

  @override
  String get nfcSettingsIos => 'iOS: Einstellungen → NFC';

  @override
  String get verifyScanBadge => 'BADGE SCANNEN';

  @override
  String get verifyScanNfc => 'NFC TAG SCANNEN';

  @override
  String get verifyScanQr => 'QR SCANNEN';

  @override
  String get verifyScanQrCaps => 'QR-CODE SCANNEN';

  @override
  String get verifyReadyToScan => 'Bereit zum Scannen';

  @override
  String get verifyWaitingNfc => 'Warte auf NFC Tag...';

  @override
  String get verifyCheckingNfc => 'Prüfe NFC...';

  @override
  String get verifyScanInstruction =>
      'Scanne den NFC-Tag oder QR-Code\ndes Meetup-Organisators.';

  @override
  String get verifyScanQrInstruction =>
      'Scanne den QR-Code\ndes Meetup-Organisators';

  @override
  String get verifyNoNfcDevice =>
      'Dieses Gerät hat kein NFC. Nutze den QR-Scanner.';

  @override
  String get verifyNoNfcLong => 'Dieses Gerät unterstützt kein NFC.\n\n';

  @override
  String get verifyUseQrInstead => 'Nutze stattdessen den QR-Code-Scanner, ';

  @override
  String get verifyToGetBadge => 'um dein Badge zu erhalten.';

  @override
  String get verifyAskScan => 'Bitte lass einen Teilnehmer deinen Tag scannen.';

  @override
  String get verifyCantSelfBadge =>
      'Du kannst dir nicht selbst ein Badge geben.\n';

  @override
  String get verifyBadgeFound => 'BADGE GEFUNDEN';

  @override
  String get verifyAlreadyCollected => 'BEREITS GESAMMELT';

  @override
  String get verifyAddToWallet => 'ZUR WALLET HINZUFÜGEN';

  @override
  String get verifyVerifiedAdmin => 'Verifizierter Admin';

  @override
  String get verifyUnknownMeetup => 'Unbekanntes Meetup';

  @override
  String get verifyNoExpiry => 'Kein Ablauf';

  @override
  String get writerReadyToWrite => 'Bereit zum Schreiben';

  @override
  String get writerNoNfcDevice =>
      'Dieses Gerät hat kein NFC. Nutze Rolling QR-Codes.';

  @override
  String get writerUseRollingQr => 'Du kannst stattdessen Rolling QR-Codes ';

  @override
  String get writerForYourMeetup => 'für dein Meetup verwenden.';

  @override
  String get writerSelectHomeFirst =>
      'Bitte erst ein Home-Meetup im Profil auswählen';

  @override
  String get writerYourHomeMeetup => 'DEIN HOME-MEETUP';

  @override
  String get writerCreateTag => 'TAG ERSTELLEN';

  @override
  String get writerCreateMeetupTag => 'MEETUP TAG ERSTELLEN';

  @override
  String get writerMeetupTag => 'MEETUP TAG';

  @override
  String get writerSuccess => 'ERFOLG!';

  @override
  String get writerValid6h => 'Gültig für 6 Stunden';

  @override
  String get writerHoldTag => 'Halte Tag an das Gerät...';

  @override
  String get writerHoldTagInstruction =>
      'Halte einen NFC Tag an das Gerät.\nTeilnehmer scannen diesen Tag um ein Badge zu sammeln.';

  @override
  String get writerFormatting => 'Formatiere leeren Tag...';

  @override
  String get writerFormatFailed => 'Formatierung fehlgeschlagen';

  @override
  String get writerLoadingSession => 'Lade Session-Daten...';

  @override
  String get writerJumpToQr => 'Springe zum QR-Code...';

  @override
  String get writerNoNdef => 'Kein NDEF Format möglich';

  @override
  String get writerTagReadOnly => 'Tag ist schreibgeschützt';

  @override
  String get writerCanOverwrite => 'Tag kann danach überschrieben werden';

  @override
  String get writerTagLost => 'Tag verloren während dem Schreiben';

  @override
  String get writerTagRemovedEarly =>
      'Tag zu früh entfernt — halte ihn ruhig 2–3 Sekunden ans Gerät';

  @override
  String get writerUseNtag215 => 'Verwende einen NTAG215 (504B) oder größer.';

  @override
  String get writerToWriteTag => 'um den Tag zu beschreiben.\n\n';

  @override
  String verifyMsgLocation(String name) {
    return 'Ort: $name';
  }

  @override
  String verifyMsgBlock(Object height) {
    return 'Block: $height';
  }

  @override
  String verifyMsgSignedBy(String signer) {
    return 'Signiert von: $signer';
  }

  @override
  String get verifyMsgProof => 'Beweis: Schnorr (BIP-340)';

  @override
  String verifyMsgTagExpiry(String expiry) {
    return 'Tag-Ablauf: $expiry';
  }

  @override
  String verifyAlreadyToday(String name) {
    return 'Bereits gesammelt\n\nHeute hast du bereits ein Badge von:\n$name';
  }

  @override
  String get wotTitle => 'WEB OF TRUST';

  @override
  String get wotActiveOrganizers => 'AKTIVE ORGANISATOREN';

  @override
  String get wotActiveOrganizer => 'AKTIVER ORGANISATOR';

  @override
  String get wotActiveWarnings => 'AKTIVE WARNUNGEN';

  @override
  String get wotActiveWarning => 'Aktive Warnung';

  @override
  String get wotMyStatus => 'DEIN STATUS';

  @override
  String get wotMyVouches => 'DEINE BÜRGSCHAFTEN';

  @override
  String get wotWhoYouVouchFor => 'FÜR WEN DU BÜRGST';

  @override
  String get wotWhoVouchesForYou => 'WER BÜRGT FÜR DICH';

  @override
  String get wotWeightedReporting => 'GEWICHTETES MELDESYSTEM';

  @override
  String get wotRestore => 'WIEDERHERSTELLEN';

  @override
  String get wotRevokeAll => 'ALLE WIDERRUFEN';

  @override
  String get wotPublishNostr => 'AUF NOSTR PUBLISHEN';

  @override
  String get wotVouch => 'BÜRGEN';

  @override
  String get wotVouchVerb => 'VERBÜRGEN';

  @override
  String get wotReportNpub => 'NPUB MELDEN';

  @override
  String get wotScanNpub => 'NPUB SCANNEN';

  @override
  String get wotPublishRevocation => 'WIDERRUF PUBLISHEN';

  @override
  String get wotSigningPublishing => 'SIGNIERE & PUBLIZIERE...';

  @override
  String get wotSyncNetwork => 'Netzwerk synchronisieren';

  @override
  String get wotBootstrapPhase => 'Bootstrap-Phase';

  @override
  String get wotDecentralized => 'Dezentral (Web of Trust)';

  @override
  String get wotMinVouches => 'Min. Bürgen';

  @override
  String get wotDistrustThreshold => 'Distrust-Schwelle';

  @override
  String get wotNotEnoughVouchers => 'NOCH NICHT GENUG BÜRGEN';

  @override
  String get wotVouchers => 'Bürgen';

  @override
  String get wotNoVouchersYet => 'Noch keine Bürgen';

  @override
  String get wotNobodyYet => 'Noch niemand';

  @override
  String get wotNotSuspendedWatch =>
      'Noch nicht suspendiert, aber du solltest aufpassen.';

  @override
  String get wotNoReports => 'Keine Meldungen';

  @override
  String get wotNoActiveAdmins => 'Keine aktiven Admins';

  @override
  String get wotNoCleanNetwork =>
      'Aktuell gibt es keine offenen Warnungen\nim Netzwerk. Alles sauber.';

  @override
  String get wotNoOrganizersEnough =>
      'Das Netzwerk hat noch keine Organisatoren mit genug Bürgschaften.';

  @override
  String get wotNoVouchesFound =>
      'Keine publizierten Bürgschaften auf den Relays gefunden.';

  @override
  String get wotTapPlusFirst =>
      'Tippe auf + um deinen ersten Ritterschlag\nzu vergeben.';

  @override
  String get wotAskOthersVouch =>
      'Bitte andere Organisatoren, für dich zu bürgen.\n';

  @override
  String get wotNoDataLoaded =>
      'Netzwerk-Daten konnten nicht geladen werden.\nZiehe zum Aktualisieren nach unten.';

  @override
  String get wotNoRelay => 'Kein Relay erreichbar — später erneut versuchen.';

  @override
  String get wotRevokeAllTitle => 'ALLE BÜRGSCHAFTEN WIDERRUFEN?';

  @override
  String get wotRevokeVouchTitle => 'BÜRGSCHAFT ENTZIEHEN?';

  @override
  String get wotWithdrawVouch => 'Bürgschaft entziehen';

  @override
  String get wotVouchWithdrawn =>
      'Bürgschaft entzogen. Vergiss nicht zu publishen.';

  @override
  String get wotVouchGiven =>
      'Ritterschlag vergeben! Vergiss nicht zu publishen.';

  @override
  String get wotAllRevoked =>
      'Alle Bürgschaften wurden im Netzwerk widerrufen.';

  @override
  String get wotReasonRequired => 'Grund (Pflicht)';

  @override
  String get wotNpubRequired => 'npub (Pflicht)';

  @override
  String get wotNameAlias => 'Name / Alias (optional)';

  @override
  String get wotMeetupExample => 'Meetup (z.B. München)';

  @override
  String get wotReasonExample => 'z.B. Fälscht Badges, kein echtes Meetup...';

  @override
  String get wotNpubReasonRequired => 'npub und Grund sind Pflicht.';

  @override
  String get wotScanInstruction =>
      'Scanne den Nostr-QR-Code (npub)\ndes Organisators.';

  @override
  String get wotVouchExplain =>
      'Du bürgst mit deiner eigenen Reputation für diesen Organisator.';

  @override
  String get wotEachVouchPersonal =>
      'Jede Bürgschaft ist dein persönliches Vertrauens-Votum — ';

  @override
  String get wotAfterPublishAll =>
      'nach dem Publishen sieht das gesamte Netzwerk, für wen du stehst.';

  @override
  String get wotWhoYouVouchExplain => 'Hier siehst du, für wen DU bürgst. ';

  @override
  String get wotPublishUpdated => 'Publishe danach deine aktualisierte Liste, ';

  @override
  String get wotSoNetworkKnows => 'damit das Netzwerk davon erfährt.';

  @override
  String get wotSingleReportNoWeight =>
      'Eine einzelne Meldung hat kein Gewicht — ';

  @override
  String get wotOnlyMultipleIndep =>
      'erst wenn mehrere unabhängige Organisatoren ';

  @override
  String get wotWarnSuspend => 'warnen, wird jemand suspendiert. ';

  @override
  String get wotNobodyAlonePower => 'Niemand hat allein Macht über andere.';

  @override
  String get wotYourReportAlone =>
      'Deine Meldung allein hat kein Gewicht. Erst wenn ';

  @override
  String get wotOrgsWarnSuspended =>
      'Organisatoren warnen, wird der npub suspendiert.';

  @override
  String get wotRevokeAllBody =>
      'Dies publiziert eine leere Liste auf Nostr und widerruft damit ALLE ';

  @override
  String get wotFromOtherOrgs => 'von anderen Organisatoren.';

  @override
  String get wotRestoreExplain =>
      'Bürgschaften liegen signiert auf Nostr. „Wiederherstellen\" holt ';

  @override
  String get wotRestoreListBack =>
      'deine Liste nach einer Neuinstallation oder einem Backup-Wechsel zurück.';

  @override
  String get wotVouchesSignedOnNostr =>
      'deine Bürgschaften im Netzwerk — auch solche, die lokal nicht mehr ';

  @override
  String get wotVisibleLocally =>
      'sichtbar sind.\n\nNutze das, wenn du nach einer Neuinstallation deine ';

  @override
  String get wotCantResolveOld =>
      'alten Bürgschaften nicht mehr auflösen kannst.';

  @override
  String get wotRemovedFromList =>
      'wird von deiner Vouching-Liste entfernt.\n\n';

  @override
  String get wotSuspendedByNetwork =>
      'durch das Netzwerk suspendiert. Überprüfe deine Bürgschaften.';

  @override
  String wotErrorLoading(String msg) {
    return 'Fehler beim Laden: $msg';
  }

  @override
  String wotSyncFailed(String msg) {
    return 'Sync fehlgeschlagen: $msg';
  }

  @override
  String wotRevocationFailed(String msg) {
    return 'Widerruf fehlgeschlagen: $msg';
  }

  @override
  String wotRestoreFailed(String msg) {
    return 'Wiederherstellung fehlgeschlagen: $msg';
  }

  @override
  String wotVouchesRestored(Object count) {
    return '$count Bürgschaften von Nostr wiederhergestellt.';
  }

  @override
  String wotNetworkHealth(String label) {
    return 'NETZWERK $label';
  }

  @override
  String wotVouchProgress(Object count, Object total) {
    return '$count / $total Bürgen';
  }

  @override
  String wotReportsCount(Object count) {
    return '$count Meldungen';
  }

  @override
  String wotNeedMoreVouches(Object count) {
    return 'Du brauchst noch $count Bürgschaften ';
  }

  @override
  String wotVouchesRequired(Object count, Object total) {
    return '$count / $total benötigt';
  }

  @override
  String wotSuspensionProgress(Object count, Object total) {
    return '$count / $total Suspendierung';
  }

  @override
  String wotLiability(Object count) {
    return 'HAFTUNG: $count suspendiert';
  }

  @override
  String wotWarningCount(Object count) {
    return 'WARNUNG: $count gemeldet';
  }

  @override
  String wotYourNpub(String npub) {
    return 'Dein npub: $npub';
  }

  @override
  String wotLiabilityBody(String names) {
    return 'Du bürgst für $names — diese npubs sind durch das Netzwerk suspendiert. Überprüfe deine Bürgschaften.';
  }

  @override
  String wotWarningBody(String names) {
    return 'Für $names gibt es Meldungen. ';
  }

  @override
  String get wotVotes => 'Stimmen';

  @override
  String get wotSuspended => 'Suspendiert';

  @override
  String wotReportNoWeightThreshold(Object count) {
    return 'Deine Meldung allein hat kein Gewicht. Erst wenn $count unabhängige Organisatoren warnen, wird der npub suspendiert.';
  }

  @override
  String wotPublishedLive(Object count) {
    return 'Dein Web of Trust ist live ($count Relays)!';
  }

  @override
  String wotReportPublished(Object count) {
    return 'Meldung publiziert an $count Relays.';
  }

  @override
  String wotErrorShort(String msg) {
    return 'Fehler: $msg';
  }

  @override
  String get wotOffline => 'Offline';

  @override
  String get wotActive => 'Aktive';

  @override
  String get wotPhase => 'Phase';

  @override
  String get wotPhaseDecentralized => 'Dezentral';

  @override
  String get wotPhaseBootstrap => 'Bootstrap';

  @override
  String get wotReportsLabel => 'Meldungen';

  @override
  String get wotVouchersLabel => 'BÜRGEN:';

  @override
  String writerTagTooSmall(Object data, Object max) {
    return 'Tag zu klein! Daten: ${data}B, Tag: ${max}B.\n';
  }

  @override
  String get writerTagWritten => '✅ MEETUP TAG geschrieben!\n\n';

  @override
  String writerCompactSize(Object size) {
    return '📦 ${size}B (kompakt)\n';
  }

  @override
  String writerValidHours(Object hours) {
    return '⏱️ Gültig für ${hours}h\n\n';
  }

  @override
  String get verifyErrNoNdef => '✗ Kein NDEF Tag';

  @override
  String get verifyErrTagEmpty => '✗ Tag ist leer';

  @override
  String get verifyErrPayloadEmpty => '✗ Payload leer';

  @override
  String get verifyErrInvalidFormat => '✗ Ungültiges Format';

  @override
  String verifyErrInvalidTag(String msg) {
    return '✗ Ungültiger Tag: $msg';
  }

  @override
  String verifyErrReadError(String msg) {
    return '✗ Lesefehler: $msg';
  }

  @override
  String verifyErrNfcError(String msg) {
    return '✗ NFC Fehler: $msg';
  }

  @override
  String verifyErrQrExpired(String msg) {
    return '✗ QR-Code abgelaufen!\n$msg\n\nBitte direkt am Bildschirm des Organisators scannen.';
  }

  @override
  String verifyErrPrefix(String msg) {
    return '✗ $msg';
  }

  @override
  String writerStartError(String msg) {
    return '❌ Start Fehler: $msg';
  }

  @override
  String writerFitsNtag215(Object size) {
    return '~${size}B — passt auf NTAG215 (492B)';
  }

  @override
  String get writerNoHomeMeetup => '⚠️ Kein Home-Meetup gesetzt';

  @override
  String get writerHomeMeetupNotFound => '⚠️ Home-Meetup nicht gefunden';

  @override
  String get writerNoActiveSession =>
      '❌ Keine aktive Meetup-Session gefunden. Bitte starte das Meetup neu.';

  @override
  String get admMyWebOfTrust => 'MEIN WEB OF TRUST';

  @override
  String get admMyDelegations => 'DEINE DELEGATIONEN';

  @override
  String get admCoAdminKnight => 'CO-ADMIN RITTERN';

  @override
  String get admKnighthood => 'RITTERSCHLAG';

  @override
  String get admRemove => 'ENTFERNEN';

  @override
  String get admCancel => 'ABBRECHEN';

  @override
  String get admRevokeTrust => 'VERTRAUEN ENTZIEHEN?';

  @override
  String get admRevokeTrustShort => 'Vertrauen entziehen';

  @override
  String get admSyncWot => 'Web of Trust synchronisieren';

  @override
  String get admNobodyDelegated => 'Du hast noch niemanden delegiert.';

  @override
  String get admTapKnighthood =>
      'Tippe unten auf \'RITTERSCHLAG\',\num einem neuen Organisator in deinem\nMeetup das Vertrauen auszusprechen.';

  @override
  String get admVouchNewExplain =>
      'Du bürgst mit deiner eigenen Reputation für diesen neuen Organisator.';

  @override
  String get admScanNewOrg =>
      'Scanne den Nostr-QR-Code (npub) des neuen Organisators.';

  @override
  String get admNetworkLearnsKnight =>
      'Das Netzwerk erfährt erst von deinen neuen Co-Admins,\nwenn du deine Signatur auf Nostr veröffentlichst.';

  @override
  String get admMustRepublish =>
      'Du musst die Liste danach neu publishen, damit das Netzwerk davon erfährt.';

  @override
  String get admPublishEmptyRevoke =>
      'Publiziere eine leere Liste um alle Delegationen\nim Netzwerk zu widerrufen.';

  @override
  String get admRestoreListBack =>
      'deine Liste nach einer Neuinstallation zurück.';

  @override
  String get admSigningSending => 'Signiere und sende an Nostr...';

  @override
  String get admRestoringVouches =>
      'Stelle meine Bürgschaften von Nostr wieder her...';

  @override
  String get admSyncingWot => 'Synchronisiere Web of Trust...';

  @override
  String get admRevokingAll => 'Widerrufe alle Bürgschaften...';

  @override
  String admRevokeTrustBody(String name, String meetup) {
    return 'Möchtest du $name das Vertrauen als Admin für $meetup entziehen?\n\n';
  }

  @override
  String get admRestoreExplain =>
      'Bürgschaften liegen signiert auf Nostr. „Wiederherstellen\" holt ';

  @override
  String admVouchedCount(Object count) {
    return 'Du hast dich für $count Organisatoren verbürgt.';
  }

  @override
  String get admCoAdminAdded =>
      '✅ Co-Admin hinzugefügt! Vergiss nicht zu publishen.';

  @override
  String get apMeetupSession => 'MEETUP SESSION';

  @override
  String get apSessionRunning => 'SESSION LÄUFT';

  @override
  String get apOpenActiveMeetup => 'AKTIVES MEETUP ÖFFNEN';

  @override
  String get apStartMeetup => 'MEETUP STARTEN';

  @override
  String get apEndMeetupEarly => 'Meetup vorzeitig beenden';

  @override
  String get apNetwork => 'NETZWERK';

  @override
  String get apOrganizer => 'ORGANISATOR';

  @override
  String get apWebOfTrust => 'WEB OF TRUST';

  @override
  String get apHowItWorks => 'SO FUNKTIONIERT\'S';

  @override
  String get apManageVouches =>
      'Bürgschaften verwalten, Netzwerk-Status, Meldungen';

  @override
  String get apNewMeetupQ => 'Neues Meetup starten?';

  @override
  String get apSessionEndQ => 'Session beenden?';

  @override
  String get apCancel => 'Abbrechen';

  @override
  String get apStart => 'Starten';

  @override
  String get apEnd => 'Beenden';

  @override
  String get apSeedAdmin => 'Seed Admin';

  @override
  String get apViaTrustScore => 'Via Trust Score';

  @override
  String get apNewMeetupBody =>
      'Dies erstellt eine eindeutige Signatur (Blockzeit) für die nächsten 6 Stunden. In dieser Zeit ist die Erstellung neuer Sessions gesperrt.';

  @override
  String get apSessionEndBody =>
      'Damit sperrst du die aktuelle Blockzeit. Du kannst danach eine neue Session starten.';

  @override
  String get apGeneratesProof =>
      'Generiert einen neuen kryptographischen Beweis für die nächsten 6 Stunden.';

  @override
  String get humTitle => 'PROOF OF HUMANITY';

  @override
  String get humVerified => 'MENSCH VERIFIZIERT';

  @override
  String get humNotVerified => 'NICHT VERIFIZIERT';

  @override
  String get humVerifiedSub => 'Du bist als Mensch verifiziert';

  @override
  String get humLightningActive => 'Lightning-Beweis aktiv';

  @override
  String get humCheckNow => 'JETZT PRÜFEN';

  @override
  String get humCheckAgain => 'ERNEUT PRÜFEN';

  @override
  String get humCheckAgainShort => 'Erneut prüfen';

  @override
  String get humSearchingRelays => 'SUCHE AUF RELAYS...';

  @override
  String get humHowTitle => 'WIE FUNKTIONIERT DAS?';

  @override
  String get humIntro1 =>
      'Beweise, dass du ein Mensch bist — indem du nachweist, ';

  @override
  String get humIntro2 => 'dass du eine echte Lightning-Wallet besitzt und ';

  @override
  String get humIntro3 => 'schon einmal jemanden auf Nostr gezappt hast.';

  @override
  String get humExplain1 =>
      'Bots haben keine Lightning-Wallets. Eine einzige echte ';

  @override
  String get humExplain2 =>
      'Zahlung beweist, dass du ein Mensch mit einer echten ';

  @override
  String get humExplain3 =>
      'Wallet bist — ohne persönliche Daten preiszugeben.';

  @override
  String get humStep1 => 'Du zappst irgendjemanden auf Nostr';

  @override
  String get humStep2 => 'Der Zap erzeugt ein Receipt auf Relays';

  @override
  String get humStep3 => 'Die App findet dein Receipt';

  @override
  String get humStepInstruction =>
      'Egal wen, egal wieviel Sats. Nutze dafür einen Nostr-Client wie Damus, Amethyst oder Primal.';

  @override
  String get humCheckInstruction =>
      'Drücke den Prüfen-Button und die App sucht auf Nostr-Relays nach deinem Zap.';

  @override
  String get humZapReturn => 'Zappe irgendjemanden und komm zurück';

  @override
  String get humCryptoProof =>
      'Das ist ein kryptographischer Beweis, dass du eine echte Lightning-Zahlung geleistet hast.';

  @override
  String get humProofInEvent1 =>
      'auf dem Nostr-Netzwerk geleistet. Dieser Beweis ist in deinem ';

  @override
  String get humProofPrivacy =>
      'Der Beweis wird in dein Reputation-Event aufgenommen. Kein Betrag oder Empfänger wird gespeichert.';

  @override
  String get humReputationSaved => 'Reputation-Event gespeichert.';

  @override
  String humPaidOn(String date) {
    return 'Du hast am $date eine Lightning-Zahlung ';
  }

  @override
  String humLastCheck(String time) {
    return 'Letzte Prüfung: $time';
  }

  @override
  String get ppTitle => 'PLATTFORM-VERKNÜPFUNG';

  @override
  String get ppPlatform => 'PLATTFORM';

  @override
  String get ppUsername => 'BENUTZERNAME';

  @override
  String get ppActiveLinks => 'AKTIVE VERKNÜPFUNGEN';

  @override
  String get ppLinkPlatform => 'PLATTFORM VERKNÜPFEN';

  @override
  String get ppCreateLink => 'VERKNÜPFUNG ERSTELLEN';

  @override
  String get ppAnotherPlatform => 'WEITERE PLATTFORM';

  @override
  String get ppShareOnPlatform => 'AUF PLATTFORM TEILEN';

  @override
  String get ppUnlinkQ => 'VERKNÜPFUNG AUFHEBEN?';

  @override
  String get ppRevoke => 'WIDERRUFEN';

  @override
  String get ppCancel => 'ABBRECHEN';

  @override
  String get ppYourUsername => 'Dein Benutzername';

  @override
  String get ppPlatformName => 'Name der Plattform';

  @override
  String get ppIntro =>
      'Verknüpfe deinen Account mit einer Plattform. Der Beweis wird automatisch in deinen Reputation-QR eingebettet.';

  @override
  String get ppLinkSaved =>
      'Verknüpfung gespeichert! Wird automatisch in deinen Reputation-QR eingebettet.';

  @override
  String get ppMustUpdate =>
      'Du musst dein Reputation-Event danach aktualisieren.';

  @override
  String get ppUnlinkBody1 => 'Die Plattform-Verknüpfung für \"';

  @override
  String get ppUnlinkBody2 => 'wird gelöscht.\n\n';

  @override
  String ppUnlinkBody(String username, String platform) {
    return 'Die Plattform-Verknüpfung für \"$username\" auf $platform wird gelöscht.\n\nDu musst dein Reputation-Event danach aktualisieren.';
  }

  @override
  String ppCreated(String date) {
    return 'Erstellt: $date';
  }

  @override
  String get ppRevokeTooltip => 'Widerrufen';

  @override
  String get rqTitle => 'MEETUP QR-CODE';

  @override
  String get rqActive => 'AKTIV';

  @override
  String get rqCodeRenewing => 'Code erneuert sich...';

  @override
  String get rqNextCodeIn => 'Nächster Code in';

  @override
  String get rqEndSession => 'Session beenden';

  @override
  String get rqEndSessionQ => 'Session beenden?';

  @override
  String get rqEnd => 'BEENDEN';

  @override
  String get rqEndSessionBody =>
      'Eine beendete Session sperrt diese Blockzeit. Du kannst danach eine neue Session starten.';

  @override
  String get rqNoActiveSession => 'KEINE AKTIVE SESSION';

  @override
  String get rqNoSessionBody =>
      'Es läuft aktuell keine Meetup-Session.\nBitte starte das Meetup im Admin Panel neu.';

  @override
  String get rqBackToAdmin => 'ZURÜCK ZUM ADMIN PANEL';

  @override
  String get rsTitle => 'NOSTR-RELAYS';

  @override
  String get rsDefaultRelays => 'DEFAULT-RELAYS';

  @override
  String get rsCustomRelays => 'EIGENE RELAYS';

  @override
  String get rsAddRelay => 'RELAY HINZUFÜGEN';

  @override
  String get rsAdd => 'HINZUFÜGEN';

  @override
  String get rsNoRelaysActive => 'Keine Relays aktiv!';

  @override
  String get rsNoCustomRelays => 'Keine eigenen Relays konfiguriert.';

  @override
  String get rsAllRelaysInfo =>
      'Die App nutzt alle aktiven Relays gleichzeitig für maximale Erreichbarkeit.';

  @override
  String get rsRelaysIntro =>
      'Relays verteilen deine Reputation im Nostr-Netzwerk. ';

  @override
  String get rsRelayPlaceholder => 'wss://mein-relay.de';

  @override
  String get rdScanAdminTag => 'ADMIN TAG SCANNEN';

  @override
  String get rdAnon => 'ANON';

  @override
  String get rdCollectBadge => 'BADGE ABHOLEN';

  @override
  String get rdYourReputation => 'DEINE REPUTATION';

  @override
  String get rdEditIdentity => 'Identität bearbeiten';

  @override
  String get rdLinkingIdentity => 'Identität verknüpfen...';

  @override
  String get rdNostrVerified => 'NOSTR VERIFIED';

  @override
  String get rdNoBadges => 'Noch keine Badges gesammelt.\nGeh zu einem Meetup!';

  @override
  String get rdSelfSovereign =>
      'Self-Sovereign: Diese App läuft ohne Server. Deine Badges gehören nur dir und sind auf diesem Gerät gespeichert.';

  @override
  String get rdVerifiedByAdmin => 'VERIFIZIERT DURCH ADMIN';

  @override
  String rqRemainingTime(String time) {
    return 'Restzeit: $time\n\n';
  }

  @override
  String rqSessionRemaining(String time) {
    return 'Session: $time';
  }

  @override
  String get rvTitle => 'REPUTATION PRÜFEN';

  @override
  String get rvChecking => 'PRÜFE...';

  @override
  String get rvFullyVerified => 'VOLLSTÄNDIG VERIFIZIERT';

  @override
  String get rvPartiallyVerified => 'TEILWEISE VERIFIZIERT';

  @override
  String get rvSignatureOnly => 'NUR SIGNATUR GEPRÜFT';

  @override
  String get rvInvalid => 'UNGÜLTIG';

  @override
  String get rvConfirmedInEvent => 'Im Event bestätigt';

  @override
  String get rvPlatformProof => 'Plattform-Proof';

  @override
  String get rvIntro1 => 'Füge den Verify-String oder npub einer Person ein, ';

  @override
  String get rvIntro2 => 'um ihre Reputation über alle Beweis-Layer zu prüfen.';

  @override
  String get rvCheckingSignature => 'Prüfe Signatur...';

  @override
  String get rvCheckingNostr => 'Analysiere Nostr-Netzwerk...';

  @override
  String get rvCheckingLightning => 'Prüfe Lightning-Aktivität...';

  @override
  String get rvCheckingNip05 => 'Prüfe NIP-05...';

  @override
  String get msSelectMeetup => 'MEETUP AUSWÄHLEN';

  @override
  String get msSearchMeetup => 'Meetup suchen...';

  @override
  String get mlTitle => 'MEETUPS';

  @override
  String get mlRetry => 'Erneut versuchen';

  @override
  String get mlLoadError => 'Fehler beim Laden';

  @override
  String get mlNoMeetupsFound => 'Keine Meetups gefunden.';

  @override
  String mlNoMeetupFor(String query) {
    return 'Kein Meetup für \"$query\"';
  }

  @override
  String get cmRequestSent => 'ANFRAGE GESENDET 🚀';

  @override
  String get cmDateTime => 'DATUM & UHRZEIT';

  @override
  String get cmFoundBase => 'GRÜNDE EINE BASIS.';

  @override
  String get cmLocation => 'LOCATION / ORT';

  @override
  String get cmCityName => 'NAME DER STADT';

  @override
  String get cmTelegramGroup => 'TELEGRAM GRUPPE (OPTIONAL)';

  @override
  String get cmNewMeetup => 'NEUES MEETUP';

  @override
  String get cmDateExample => 'z.B. 21. Mai, 19:00';

  @override
  String get cmCityExample => 'z.B. Frankfurt';

  @override
  String get cmLocationExample => 'z.B. Room 77';

  @override
  String get evUpcomingEvents => 'KOMMENDE EVENTS';

  @override
  String get evDatesEvents => 'TERMINE & EVENTS';

  @override
  String get evNoMeetupsFound => 'Keine Meetups gefunden';

  @override
  String get evSearchCityCountry => 'Stadt oder Land suchen...';

  @override
  String get evIntro =>
      'Die meisten Einundzwanzig Meetups finden regelmäßig statt. Klick auf ein Meetup für mehr Infos und Termine.';

  @override
  String get rvLabelPlatform => 'Plattform';

  @override
  String get rvLabelUsername => 'Username';

  @override
  String get countryDE => 'Deutschland';

  @override
  String get countryAT => 'Österreich';

  @override
  String get countryCH => 'Schweiz';

  @override
  String get countryES => 'Spanien';

  @override
  String get countryNL => 'Niederlande';

  @override
  String get countryIT => 'Italien';

  @override
  String get countryFR => 'Frankreich';

  @override
  String get siTitle => 'DEIN TRUST SCORE';

  @override
  String get siIntro =>
      'Misst deine Vertrauenswürdigkeit. Basiert auf kryptographischen Beweisen — niemand kann ihn fälschen.';

  @override
  String get siIdentityLayer => 'IDENTITY LAYER';

  @override
  String siLinksActive(Object count) {
    return '$count Verknüpfungen aktiv';
  }

  @override
  String get siHumanitySub => 'Lightning Zap Verifikation';

  @override
  String get siNip05Sub => 'Nostr-Identität (name@domain)';

  @override
  String get siPlatformActive => 'Plattform aktiv';

  @override
  String get siPlatforms => 'Plattformen';

  @override
  String get siNoneLinked => 'Noch keine verknüpft';

  @override
  String get siTrustLevel => 'TRUST LEVEL';

  @override
  String get siLvlNew => 'Startlevel. Besuche Meetups um Badges zu sammeln.';

  @override
  String get siLvlStarter => 'Deine ersten Badges zeigen Community-Teilnahme.';

  @override
  String get siLvlActive =>
      'Regelmäßig dabei. Verschiedene Meetups und Organisatoren stärken dein Profil.';

  @override
  String get siLvlEstablished =>
      'Vertrauenswürdiges Mitglied. Breit vernetzt und lange dabei.';

  @override
  String get siLvlVeteran => 'Höchstes Level. Reputation über Monate bewiesen.';

  @override
  String get siCalculation => 'BERECHNUNG';

  @override
  String get siFacBadges => 'Meetup-Badges';

  @override
  String get siFacBadgesDesc =>
      'Basiswert pro Badge. Gut besuchte Meetups wertvoller.';

  @override
  String get siFacDiversity => 'Diversität';

  @override
  String get siFacDiversityDesc =>
      'Verschiedene Städte/Organisatoren = mehr Punkte.';

  @override
  String get siFacSigners => 'Signers';

  @override
  String get siFacSignersDesc => 'Unabhängige Organisatoren = höherer Trust.';

  @override
  String get siFacMaturity => 'Reife';

  @override
  String get siFacMaturityDesc => 'Account-Alter + Regelmäßigkeit = Bonus.';

  @override
  String get siFacFrequency => 'Frequency Cap';

  @override
  String get siFacFrequencyDesc => 'Max. 2 Badges/Woche. Anti-Farming.';

  @override
  String get siBecomeOrganizer => 'ORGANISATOR WERDEN';

  @override
  String get siBecomeOrgDesc =>
      'Automatische Beförderung ab genügend Trust Score. Dann eigene NFC-Tags und QR-Codes erstellen.';

  @override
  String siProgressLabel(Object name) {
    return 'FORTSCHRITT ($name)';
  }

  @override
  String get siAlreadyOrganizer => 'Du bist bereits Organisator!';

  @override
  String get siIncreaseScore => 'SCORE ERHÖHEN';

  @override
  String get siTip1 => 'Regelmäßig verschiedene Meetups besuchen';

  @override
  String get siTip2 => 'Badges bei Meetups in anderen Städten sammeln';

  @override
  String get siTip3 => 'Badges von verschiedenen Organisatoren';

  @override
  String get siTip4 => 'Identität mit Lightning-Zap verifizieren';

  @override
  String get siTip5 => 'NIP-05 einrichten';

  @override
  String get siTip6 => 'Plattformen verknüpfen';

  @override
  String siProgressRow(Object label, Object current, Object required) {
    return '$label: $current/$required';
  }

  @override
  String get wotTabNetwork => 'NETZWERK';

  @override
  String get wotTabReports => 'MELDUNGEN';

  @override
  String get wotHealthGood => 'GESUND';

  @override
  String get wotHealthBuilding => 'AUFBAU';

  @override
  String get wotHealthCritical => 'KRITISCH';

  @override
  String get badgeUnknown => 'unbekannt';

  @override
  String get badgeBlockAtScan => '₿ Blockhöhe beim Scan';

  @override
  String get mwStartMeetup => 'MEETUP STARTEN';

  @override
  String get mwStep1Nfc => 'SCHRITT 1: NFC TAG';

  @override
  String get mwNfcIntro1 =>
      'Möchtest du physische NFC-Tags (NTAG215) für dieses Meetup auslegen? ';

  @override
  String get mwNfcIntro2 =>
      'Der kryptographische Beweis (Blockzeit & Signatur) wird darauf fixiert.';

  @override
  String get mwWriteNfcTag => 'NFC TAG BESCHREIBEN';

  @override
  String get mwSkipQrOnly => 'ÜBERSPRINGEN — NUR QR NUTZEN';

  @override
  String repAllBound(Object total) {
    return 'Alle $total Badges gebunden und verifiziert';
  }

  @override
  String repBoundOf(Object total, Object bound) {
    return '$bound von $total Badges identitätsgebunden';
  }

  @override
  String repBoundExtra(Object verified) {
    return ' ($verified kryptographisch verifiziert)';
  }

  @override
  String repAllVerified(Object total) {
    return 'Alle $total Badges kryptographisch verifiziert (noch nicht gebunden)';
  }

  @override
  String repVerifiedSchnorr(Object total, Object verified) {
    return '$verified von $total Badges mit Schnorr-Beweis';
  }

  @override
  String repPlatformLinksActive(Object count) {
    return '$count Plattform-Verknüpfungen aktiv';
  }

  @override
  String homeCouldNotOpen(Object url) {
    return 'Konnte $url nicht öffnen';
  }

  @override
  String admWotLive(Object count) {
    return '✅ Dein Web of Trust ist live ($count Relays)!';
  }

  @override
  String get admDelegationSigned =>
      '✅ Deine Delegation wurde kryptografisch signiert und im Netzwerk veröffentlicht!';

  @override
  String admWotCurrent(Object count) {
    return '✅ Web of Trust aktuell ($count Admins verifiziert)';
  }

  @override
  String get admNoVouchesFound =>
      '✅ Keine publizierten Bürgschaften auf den Relays gefunden';

  @override
  String admVouchesRestored(Object count) {
    return '✅ $count Bürgschaften wiederhergestellt';
  }

  @override
  String get admNoRelayReachable =>
      '⚠️ Kein Relay erreichbar — später erneut versuchen';

  @override
  String get admAllVouchesRevoked =>
      '✅ Alle Bürgschaften wurden im Netzwerk widerrufen';

  @override
  String get apHowStep3 => '3. Jeder Scan = ein Badge für den Teilnehmer\n';

  @override
  String get badgeSchnorrSig => 'Schnorr (Nostr v2) ✓';

  @override
  String msHomeMeetupSet(Object city) {
    return '✅ $city als Home-Meetup gesetzt';
  }

  @override
  String mvKnownOrganizer(Object name) {
    return '✓ Bekannter Organisator: $name';
  }

  @override
  String get mvUnknownSigner =>
      '✗ UNBEKANNTER SIGNER!\nDieser Pubkey ist nicht in der Admin-Registry.';

  @override
  String get mvAdminCheckFailed =>
      '! Admin-Status konnte nicht geprüft werden (offline?)';

  @override
  String get mvLegacyBadge => '! Legacy-Badge (v1) — Signer nicht prüfbar';

  @override
  String get mvBadgeBound => '🔗 Badge gebunden';

  @override
  String get nwSelectHomeMeetup =>
      '❌ Bitte erst ein Home-Meetup im Profil auswählen!';

  @override
  String qrUniqueRecipients(Object count) {
    return '$count verschiedene Empfänger';
  }

  @override
  String get apHowStep1 => '1. Starte ein neues Meetup (Session).\n';

  @override
  String get apHowStep2 =>
      '2. Beschreibe danach NFC Tags oder zeige den QR-Code.\n';

  @override
  String get apHowStep4 =>
      '4. Badges bauen Reputation auf → mehr Reputation = neue Organisatoren';

  @override
  String get ppHowStep1 =>
      '1. Wähle eine Plattform und gib deinen Usernamen ein\n';

  @override
  String get ppHowStep2 =>
      '2. Die App erstellt einen kryptographischen Beweis\n';

  @override
  String get ppHowStep3 =>
      '3. Der Beweis wird automatisch in deinen Reputation-QR eingebettet\n';

  @override
  String get ppHowStep4 =>
      '4. Andere scannen deinen QR und sehen die verifizierte Verknüpfung';

  @override
  String admErrorEmoji(Object msg) {
    return '❌ Fehler: $msg';
  }

  @override
  String get admNoNewUpdates => '⚠️ Keine neuen Updates gefunden';

  @override
  String homeImageLoadError(Object msg) {
    return 'Bild konnte nicht geladen werden: $msg';
  }

  @override
  String qrSentCount(Object count) {
    return '$count gesendet';
  }

  @override
  String repShareError(Object msg) {
    return 'Fehler beim Teilen: $msg';
  }

  @override
  String get rqNoHomeMeetup => '⚠️ Kein Home-Meetup gesetzt';

  @override
  String get rqMeetupNotFound => '⚠️ Meetup nicht gefunden';

  @override
  String get rlWhatMeans => 'Was bedeutet das?';

  @override
  String get rlWhyImportant => 'Warum das wichtig ist';

  @override
  String get rlWeakLabel => 'Schwaches Profil';

  @override
  String get rlWeakExpl =>
      'Nur ein Beweis-Layer aktiv. Dieser Nutzer hat kaum nachprüfbare Verbindungen. Bei größeren Transaktionen: Vorsicht.';

  @override
  String get rlWeakAdvice =>
      'Frage nach weiteren Beweisen (Lightning, NIP-05) oder triff die Person zuerst persönlich.';

  @override
  String get rlLimitedLabel => 'Eingeschränkt';

  @override
  String get rlLimitedExpl =>
      'Es gibt Meetup-Badges, aber keine weiteren unabhängigen Beweise. Der Nutzer könnte echt sein — aber es fehlt die Bestätigung durch andere Layer.';

  @override
  String get rlLimitedAdvice =>
      'Für Kleinstbeträge OK. Für größere Beträge: Abwarten bis mehr Layer aktiv sind.';

  @override
  String get rlBuildingLabel => 'Aufbauend';

  @override
  String get rlBuildingExpl =>
      'Zwei Beweis-Layer aktiv. Der Nutzer baut Reputation auf, hat aber noch nicht die volle Breite.';

  @override
  String get rlBuildingAdvice => 'Für moderate Transaktionen geeignet.';

  @override
  String get rlConnectedLabel => 'Gut vernetzt';

  @override
  String get rlConnectedExpl =>
      'Mehrere unabhängige Beweise: Meetups, Lightning-Aktivität und soziale Verbindungen. Schwer zu faken.';

  @override
  String get rlConnectedAdvice =>
      'Vertrauenswürdig für die meisten Transaktionen.';

  @override
  String get rlSolidLabel => 'Solide';

  @override
  String get rlSolidExpl =>
      'Breite Basis an Beweisen. Manipulation wäre aufwändig und teuer.';

  @override
  String get rlSolidAdvice => 'Für die meisten Zwecke vertrauenswürdig.';

  @override
  String get rlDefaultExpl => 'Einige Beweise vorhanden, aber Raum für mehr.';

  @override
  String get rlDefaultAdvice => 'Eigene Einschätzung nutzen.';

  @override
  String get rlMeetupProofs => 'Meetup-Beweise';

  @override
  String get rlMeetupGood =>
      'War bei verschiedenen Meetups mit verschiedenen Organisatoren. Das erfordert physische Anwesenheit an mehreren Orten.';

  @override
  String get rlMeetupMoreDiverse => 'Mehr Vielfalt wäre überzeugender.';

  @override
  String get rlMeetupNone =>
      'Keine Meetup-Badges vorhanden. Dieser Nutzer hat noch kein Einundzwanzig-Meetup besucht — oder nutzt die App erst seit kurzem.';

  @override
  String get rlAllBound => 'Alle kryptographisch gebunden';

  @override
  String get rlGoodSpread => 'Gute regionale Streuung';

  @override
  String get rlLowSpread => 'Wenig Streuung';

  @override
  String rlPhysGoodDiversity(Object count) {
    return 'Hat Meetup-Badges, aber nur von $count Organisator(en). Mehr Vielfalt wäre überzeugender.';
  }

  @override
  String rlBadgeCount(Object count) {
    return '$count Badges';
  }

  @override
  String rlBoundOf(Object bound, Object total) {
    return '$bound von $total gebunden';
  }

  @override
  String rlDiffMeetups(Object count) {
    return '$count verschiedene Meetups';
  }

  @override
  String rlOrganizers(Object count) {
    return '$count Organisatoren';
  }

  @override
  String get rlConfirmedByDiff => 'Von verschiedenen Personen bestätigt';

  @override
  String get rlOneOrgOnly =>
      'Nur ein Organisator — wenig unabhängige Bestätigung';

  @override
  String rlMemberSince(Object since) {
    return 'Dabei seit $since';
  }

  @override
  String rlDaysCount(Object count) {
    return '$count Tage';
  }

  @override
  String get rlLightningProof => 'Lightning-Beweis';

  @override
  String get rlLnBoth =>
      'Hat echte Lightning-Zahlungen getätigt und empfangen. Bots haben keine Lightning-Wallets — das ist ein starkes Echtheitssignal.';

  @override
  String get rlLnPaid =>
      'Hat mindestens einmal über Lightning gezahlt. Grundlegender Beweis dass eine echte Wallet existiert.';

  @override
  String get rlLnActiveOnly =>
      'Lightning-Aktivität vorhanden, aber Humanity-Proof noch nicht aktiv.';

  @override
  String get rlLnNone =>
      'Keine Lightning-Aktivität. Das heißt nicht dass der Nutzer unecht ist — vielleicht nutzt er Lightning nicht über Nostr. Aber es fehlt ein wichtiges Anti-Bot-Signal.';

  @override
  String get rlHumanVerified => 'Mensch verifiziert';

  @override
  String get rlRealLnPayment => 'Echte Lightning-Zahlung nachgewiesen';

  @override
  String rlZapsSent(Object count) {
    return '$count Zaps gesendet';
  }

  @override
  String rlToRecipients(Object count) {
    return 'An $count verschiedene Empfänger';
  }

  @override
  String rlZapsReceived(Object count) {
    return '$count Zaps empfangen';
  }

  @override
  String rlFromSenders(Object count) {
    return 'Von $count verschiedenen Sendern';
  }

  @override
  String rlMonthsActive(Object count) {
    return '$count Monate aktiv';
  }

  @override
  String get rlSocialTitle => 'Soziales Netzwerk';

  @override
  String get rlSocMutualMany =>
      'Ihr kennt euch gegenseitig auf Nostr und habt viele gemeinsame Kontakte. Starke Verbindung.';

  @override
  String get rlSocMutual => 'Gegenseitiger Follow — ihr kennt euch auf Nostr.';

  @override
  String get rlSocCommon =>
      'Viele gemeinsame Kontakte — ihr bewegt euch im selben Netzwerk.';

  @override
  String get rlSocOneSided => 'Einseitige Verbindung. Ihr kennt euch flüchtig.';

  @override
  String get rlSocOrgFollow =>
      'Bekannte Einundzwanzig-Organisatoren folgen diesem Nutzer. Das ist ein positives Signal.';

  @override
  String get rlSocDefault =>
      'Es gibt Verbindungen im Nostr-Netzwerk zu diesem Nutzer.';

  @override
  String get rlSocNone =>
      'Keine Verbindung im Nostr-Netzwerk gefunden. Das kann bedeuten: Ihr seid euch noch nie auf Nostr begegnet, oder der Nutzer ist sehr neu. Bei Fremden ist das normal — bei angeblich bekannten Gesichtern ein Warnsignal.';

  @override
  String get rlMutualFollow => 'Gegenseitiger Follow';

  @override
  String get rlYouFollow => 'Du folgst';

  @override
  String get rlFollowsYou => 'Folgt dir';

  @override
  String get rlNoFollow => 'Kein Follow';

  @override
  String get rlKnowOnNostr => 'Ihr kennt euch auf Nostr';

  @override
  String get rlNoDirectConn => 'Keine direkte Verbindung';

  @override
  String rlCommonContacts(Object count) {
    return '$count gemeinsame Kontakte';
  }

  @override
  String get rlSameNetwork => 'Gleiches Netzwerk';

  @override
  String get rlSomeOverlap => 'Einige Überlappungen';

  @override
  String get rlSeparateNetworks => 'Getrennte Netzwerke';

  @override
  String rlOrgsFollow(Object count) {
    return '$count Organisatoren folgen';
  }

  @override
  String get rlEndorsement => 'Endorsement von bekannten Admins';

  @override
  String get rlIdentityTitle => 'Identitäts-Nachweis';

  @override
  String get rlIdNip05Plat =>
      'Hat eine NIP-05-Adresse und verknüpfte Plattformen. Das verknüpft die Nostr-Identität mit einer Domain — schwerer zu faken als ein anonymer Account.';

  @override
  String get rlIdNip05Only =>
      'Hat eine NIP-05-Adresse. Das verknüpft die Nostr-Identität mit einer Domain — schwerer zu faken als ein anonymer Account.';

  @override
  String get rlIdPlatOnly =>
      'Verknüpfte Plattform-Accounts. Mehr Plattformen = mehr Aufwand für Fälscher.';

  @override
  String get rlIdNone =>
      'Keine Internet-Identifikation. Komplett anonym. Das ist für Privatsphäre OK, aber gibt auch weniger Anhaltspunkte für Vertrauen.';

  @override
  String get rlLinked => 'Verknüpft';

  @override
  String get rlNoIdentification => 'Keine Identifikation';

  @override
  String get rlAnonymous => 'Anonym';

  @override
  String get rlActive => '✓ aktiv';

  @override
  String get rlActiveShort => '✓ aktiv';

  @override
  String get rlMissingShort => '— fehlt';

  @override
  String qrReceivedCount(Object count) {
    return '$count empfangen';
  }

  @override
  String qrUniqueSenders(Object count) {
    return '$count verschiedene Sender';
  }

  @override
  String rlProofsOfFour(Object count) {
    return '$count / 4 Beweise';
  }

  @override
  String get navNearby => 'In der Nähe';

  @override
  String get nbTitle => 'MEETUPS IN DER NÄHE';

  @override
  String get nbRequestingLocation => 'Standort wird ermittelt...';

  @override
  String get nbLoading => 'Meetups werden geladen...';

  @override
  String get nbLocationDenied => 'Standortzugriff verweigert';

  @override
  String get nbLocationDeniedSub =>
      'Ohne Standort zeigen wir alle Meetups nach Datum sortiert. Aktiviere den Standort in den Einstellungen für Entfernungen.';

  @override
  String get nbServiceDisabled => 'Standortdienste sind deaktiviert';

  @override
  String get nbRetryLocation => 'Standort erneut versuchen';

  @override
  String get nbContinueWithout => 'Ohne Standort fortfahren';

  @override
  String get nbNoMeetups => 'Keine Meetups für diesen Zeitraum';

  @override
  String get nbNoMeetupsSub =>
      'Versuch einen anderen Filter oder ein anderes Datum.';

  @override
  String get nbFilterToday => 'Heute';

  @override
  String get nbFilterWeek => 'Diese Woche';

  @override
  String get nbFilterUpcoming => 'Alle kommenden';

  @override
  String get nbFilterAll => 'Alle';

  @override
  String get nbPickDate => 'Datum wählen';

  @override
  String nbKmAway(Object km) {
    return '$km km entfernt';
  }

  @override
  String get nbNoDate => 'Kein Termin angekündigt';

  @override
  String nbListHeader(Object count) {
    return '$count Meetups';
  }

  @override
  String get nbOpenInMaps => 'In Karten öffnen';

  @override
  String get nbYourLocation => 'Dein Standort';

  @override
  String get nbToday => 'Heute';

  @override
  String get nbTomorrow => 'Morgen';

  @override
  String get nbResetDate => 'Filter zurücksetzen';

  @override
  String get nbModeHere => 'Hier & jetzt';

  @override
  String get nbModePlanned => 'Geplant';

  @override
  String get nbRadius => 'Umkreis';

  @override
  String nbRadiusValue(Object km) {
    return '$km km';
  }

  @override
  String get nbSearchPlace => 'Ort suchen (z.B. Hamburg)';

  @override
  String get nbSearchingPlace => 'Suche Orte...';

  @override
  String get nbNoPlaceFound => 'Kein Ort gefunden';

  @override
  String get nbCenterHere => 'Mein Standort';

  @override
  String get nbChangePlace => 'Ort ändern';

  @override
  String get nbDateAny => 'Jederzeit';

  @override
  String get nbDateSingle => 'Datum';

  @override
  String get nbDateRange => 'Zeitraum';

  @override
  String get nbPickDay => 'Tag wählen';

  @override
  String get nbPickRange => 'Zeitraum wählen';

  @override
  String nbDateFromTo(Object from, Object to) {
    return '$from – $to';
  }

  @override
  String nbResultsHeader(Object count) {
    return '$count Meetups im Umkreis';
  }

  @override
  String get nbNoneInRadius => 'Keine Meetups im Umkreis';

  @override
  String get nbNoneInRadiusSub =>
      'Vergrößere den Umkreis oder ändere Ort/Datum.';

  @override
  String get nbApplySearch => 'Suchen';

  @override
  String nbMoreDates(Object count) {
    return '+$count weitere Termine';
  }

  @override
  String get nbDirections => 'Route';

  @override
  String get nbDetails => 'Details';

  @override
  String get settingsSectionProfile => 'Profil';

  @override
  String get settingsProfile => 'Profil bearbeiten';

  @override
  String get settingsProfileSub => 'Name, Nostr-Schlüssel & Home-Meetup';

  @override
  String get apCreateEvent => 'Termin erstellen';

  @override
  String get apCreateEventSub => 'Im Portal eintragen';

  @override
  String get apCreateEventTitle => 'Termin im Portal erstellen';

  @override
  String get apCreateEventBody =>
      'Meetup-Termine werden zentral im Einundzwanzig-Portal verwaltet. Die App öffnet jetzt das Portal in deinem Browser — dort meldest du dich mit deinem Nostr-Schlüssel an und trägst den Termin ein. Er erscheint danach automatisch hier im Kalender.';

  @override
  String get apOpenPortal => 'Portal öffnen';

  @override
  String get apNoHomeMeetupSet =>
      'Wähle zuerst dein Home-Meetup im Profil, dann kannst du Termine dafür erstellen.';

  @override
  String get apPortalHint =>
      'Warum nicht direkt in der App? Das Portal ist die zentrale Quelle für alle Termine und braucht deine Anmeldung. Eine direkte Eintragung aus der App ist geplant, sobald das Portal das unterstützt.';

  @override
  String get rcTitle => 'Reputations-Profil';

  @override
  String get rcShareImage => 'Als Bild teilen';

  @override
  String get rcSaving => 'Bild wird erstellt...';

  @override
  String rcShareError(Object error) {
    return 'Teilen fehlgeschlagen: $error';
  }

  @override
  String get rcShareText => 'Mein Einundzwanzig Trust Score & Reputation';

  @override
  String get rcLabelScore => 'Trust Score';

  @override
  String get rcLabelLevel => 'Level';

  @override
  String get rcLabelBadges => 'Badges';

  @override
  String get rcLabelMeetups => 'Meetups';

  @override
  String get rcLabelCities => 'Städte';

  @override
  String get rcLabelSigners => 'Bürgen';

  @override
  String get rcLabelAge => 'Tage dabei';

  @override
  String get rcMember => 'Einundzwanzig Mitglied';

  @override
  String get rcNoData => 'Noch keine Reputation. Sammle Badges auf Meetups!';

  @override
  String get tpTitle => 'Vertrauenspfad';

  @override
  String get tpSubtitle => 'Über wen bist du mit dieser Person verbunden?';

  @override
  String get tpEnterNpub => 'npub der Person eingeben';

  @override
  String get tpScan => 'npub scannen';

  @override
  String get tpFind => 'Pfad finden';

  @override
  String get tpSearching => 'Netzwerk wird durchsucht...';

  @override
  String tpFound(Object count) {
    return 'Verbunden über $count Stationen';
  }

  @override
  String get tpDirect => 'Direkt verbunden';

  @override
  String get tpYou => 'Du';

  @override
  String get tpTarget => 'Zielperson';

  @override
  String get tpVouchesFor => 'bürgt für';

  @override
  String get tpNoPath => 'Kein Vertrauenspfad gefunden';

  @override
  String get tpNoPathSelf =>
      'Du bist noch nicht im Bürgschafts-Netz. Lass dich von Admins bestätigen, um Pfade zu sehen.';

  @override
  String get tpNoPathTarget =>
      'Diese Person ist (noch) nicht im Bürgschafts-Netz erfasst.';

  @override
  String get tpNoPathBetween =>
      'Es gibt aktuell keine bekannte Bürgschaftskette zwischen euch.';

  @override
  String get tpInvalidNpub => 'Ungültiger npub';

  @override
  String get tpUnknown => 'Unbekannt';

  @override
  String get tpHint =>
      'Basiert auf dem öffentlichen Bürgschafts-Netz (Web of Trust). Zeigt nur Verbindungen über bürgende Mitglieder.';

  @override
  String get caOptInTitle => 'Zum Vertrauensnetzwerk beitragen?';

  @override
  String get caOptInBody =>
      'Du kannst deine Teilnahme an diesem Meetup im öffentlichen Vertrauensnetzwerk bestätigen. Andere sehen dann, dass dein npub bei diesem Meetup war — und über gemeinsame Meetups, wie ihr vernetzt seid.\n\nDas ist freiwillig. Dein Badge bekommst du auch ohne Teilnahme am Netzwerk.';

  @override
  String get caOptInPrivacy =>
      'Öffentlich & dauerhaft auf Nostr-Relays. Zeigt ein Bewegungs- und Kontaktmuster. Überleg es dir gut.';

  @override
  String get caOptInYes => 'Ja, beitragen';

  @override
  String get caOptInNo => 'Nein, privat bleiben';

  @override
  String get caPublished => 'Teilnahme im Netzwerk bestätigt';

  @override
  String get cnTitle => 'Netzwerk-Analyse';

  @override
  String get cnSubtitle =>
      'Wie ist diese Person über gemeinsame Meetups vernetzt?';

  @override
  String get cnEnterNpub => 'npub der Person eingeben';

  @override
  String get cnScan => 'Scannen';

  @override
  String get cnAnalyze => 'Analysieren';

  @override
  String get cnLoading => 'Netzwerk wird geladen...';

  @override
  String get cnSharedMeetups => 'Gemeinsame Meetups';

  @override
  String get cnMutualContacts => 'Gemeinsame Kontakte';

  @override
  String get cnReach => 'Vernetzung der Person';

  @override
  String get cnTotalMeetups => 'Meetups besucht';

  @override
  String get cnTotalContacts => 'Personen getroffen';

  @override
  String get cnNoConnection => 'Keine Verbindung gefunden';

  @override
  String get cnNoConnectionSub =>
      'Ihr wart auf keinen gemeinsamen Meetups und habt keine gemeinsamen Kontakte im Netzwerk — oder die Person nimmt nicht am Netzwerk teil.';

  @override
  String get cnDirectMet => 'Ihr habt euch direkt getroffen!';

  @override
  String get cnYou => 'Du';

  @override
  String get cnTarget => 'Diese Person';

  @override
  String cnViaShared(Object count) {
    return 'über $count gemeinsame Meetups';
  }

  @override
  String get cnTrustHint =>
      'Je mehr gemeinsame Meetups und Kontakte, desto stärker das organische Vertrauen.';

  @override
  String get cnInvalidNpub => 'Ungültiger npub';

  @override
  String get cnPrivacyNote =>
      'Zeigt nur Personen, die am Netzwerk teilnehmen (Opt-in).';

  @override
  String get tileTrustNetwork => 'Vertrauensnetzwerk';

  @override
  String get tileTrustNetworkSub => 'Vernetzung prüfen';

  @override
  String get tnHubTitle => 'Vertrauensnetzwerk';

  @override
  String get tnHubIntro =>
      'Prüfe, wie vertrauenswürdig eine Person im Einundzwanzig-Netzwerk ist — über Bürgschaften und gemeinsame Meetups.';

  @override
  String get tnHubPathTitle => 'Vertrauenspfad';

  @override
  String get tnHubPathSub =>
      'Über wen bist du mit einer Person verbunden? (Bürgschaftskette)';

  @override
  String get tnHubNetTitle => 'Netzwerk-Analyse';

  @override
  String get tnHubNetSub => 'Gemeinsame Meetups & Kontakte einer Person';

  @override
  String get orgBadgeCreated => 'Organisator-Teilnahme erfasst';

  @override
  String get orgBadgeLabel => 'Organisator';

  @override
  String get orgBadgeSub => 'Du hast dieses Meetup veranstaltet';

  @override
  String get mnTitle => 'Meine Vernetzung';

  @override
  String get mnIntro =>
      'Dein Vertrauensnetzwerk aus echten Meetup-Begegnungen — und wer darüber hinaus mit dir verbunden ist.';

  @override
  String get mnLoading => 'Netzwerk wird aufgebaut...';

  @override
  String get mnEmpty => 'Noch keine Vernetzung';

  @override
  String get mnEmptySub =>
      'Besuche Meetups und sammle Badges (mit Netzwerk-Teilnahme), um dein Vertrauensnetzwerk aufzubauen.';

  @override
  String get mnDegree1 => 'Direkt getroffen';

  @override
  String get mnDegree1Sub => 'Personen, die du live auf Meetups getroffen hast';

  @override
  String get mnDegree2 => 'Über Kontakte verbunden';

  @override
  String get mnDegree2Sub =>
      'Personen, die deine Kontakte auf Meetups getroffen haben';

  @override
  String get mnDegree3 => 'Erweitertes Netzwerk';

  @override
  String get mnDegree3Sub => 'Noch eine Ebene weiter im Netzwerk';

  @override
  String mnSharedMeetups(Object count) {
    return '$count gemeinsame Meetups';
  }

  @override
  String get mnOneSharedMeetup => '1 gemeinsames Meetup';

  @override
  String mnViaContacts(Object count) {
    return 'über $count Kontakte';
  }

  @override
  String get mnViaOneContact => 'über 1 Kontakt';

  @override
  String get mnReachLabel => 'Reichweite';

  @override
  String get mnDirectLabel => 'Direkt';

  @override
  String get mnIndirectLabel => 'Indirekt';

  @override
  String get mnTrustHint =>
      'Indirekte Kontakte über echte Begegnungen erhöhen dein Vertrauen schrittweise — auch ohne dass du die Person selbst getroffen hast.';

  @override
  String get mnPrivacyNote =>
      'Zeigt nur Personen, die am Netzwerk teilnehmen (Opt-in beim Badge-Scan).';

  @override
  String get mnCheckPerson => 'Bestimmte Person prüfen';

  @override
  String get settingsHeaderTitle => 'Einstellungen';

  @override
  String get settingsHeaderSub => 'App & Account verwalten';

  @override
  String get settingsSecAccount => 'ACCOUNT';

  @override
  String get settingsSecData => 'DATEN & SICHERHEIT';

  @override
  String get settingsSecNetwork => 'NETZWERK';

  @override
  String get settingsSecApp => 'APP';

  @override
  String get settingsSecDanger => 'GEFAHRENZONE';

  @override
  String get vpTitle => 'Person prüfen';

  @override
  String get vpIntro =>
      'Prüfe über echte Meetup-Begegnungen, ob und wie diese Person mit dir verbunden ist.';

  @override
  String get vpEnterNpub => 'npub eingeben oder Reputations-QR scannen';

  @override
  String get vpScanQr => 'QR scannen';

  @override
  String get vpCheck => 'Prüfen';

  @override
  String get vpChecking => 'Verbindung wird geprüft...';

  @override
  String get vpDirectTitle => 'Direkt getroffen!';

  @override
  String vpDirectSub(Object count) {
    return 'Ihr wart gemeinsam auf $count Meetups.';
  }

  @override
  String get vpDirectSubOne => 'Ihr wart gemeinsam auf einem Meetup.';

  @override
  String vpIndirectTitle(Object count) {
    return 'Über $count Ecken verbunden';
  }

  @override
  String get vpIndirectSub =>
      'Diese Person ist über echte Meetup-Begegnungen mit dir verbunden.';

  @override
  String get vpNoneTitle => 'Keine Verbindung gefunden';

  @override
  String get vpNoneSub =>
      'Es gibt aktuell keine bekannte Meetup-Verbindung zu dir.';

  @override
  String get vpNotInNetwork =>
      'Diese Person nimmt (noch) nicht am Netzwerk teil.';

  @override
  String get vpPathTitle => 'Verbindungspfad';

  @override
  String get vpYou => 'Du';

  @override
  String get vpTarget => 'Diese Person';

  @override
  String get vpMetAt => 'gemeinsames Meetup';

  @override
  String get vpInvalidNpub => 'Ungültiger npub';

  @override
  String get vpTrustNote =>
      'Je näher die Verbindung (kleinerer Grad), desto stärker das Vertrauen über physische Präsenz.';

  @override
  String get vpSelfTitle => 'Das bist du selbst';

  @override
  String get gpsRequired => 'Standort erforderlich';

  @override
  String get gpsRequiredOrg =>
      'Zum Erstellen eines Meetups wird dein Standort benötigt. Er legt den Ort des Meetups fest.';

  @override
  String get gpsRequiredScan =>
      'Zum Sammeln dieses Badges wird dein Standort benötigt — als Nachweis, dass du vor Ort bist.';

  @override
  String get gpsDenied =>
      'Standortzugriff verweigert. Bitte in den Einstellungen erlauben.';

  @override
  String get gpsDisabled =>
      'Standortdienste sind deaktiviert. Bitte aktivieren.';

  @override
  String get gpsError => 'Standort konnte nicht ermittelt werden.';

  @override
  String get gpsRetry => 'Erneut versuchen';

  @override
  String get gpsPickMeetup => 'Welches Meetup?';

  @override
  String get gpsPickMeetupSub =>
      'Mehrere Meetups sind in deiner Nähe. Bitte wähle das richtige.';

  @override
  String gpsDistanceKm(Object km) {
    return '$km km entfernt';
  }

  @override
  String get gpsNoMeetupNearby => 'Kein bekanntes Meetup in der Nähe gefunden.';

  @override
  String get gpsTooFar => 'Zu weit entfernt';

  @override
  String gpsTooFarSub(Object km, Object max) {
    return 'Du bist $km km vom Meetup-Ort entfernt. Badges können nur vor Ort gesammelt werden (max. $max km).';
  }

  @override
  String get mapTitle => 'Meine Badge-Weltkarte';

  @override
  String get mapButton => 'Auf der Karte ansehen';

  @override
  String get mapStatMeetups => 'Meetups';

  @override
  String get mapStatCities => 'Städte';

  @override
  String get mapStatCountries => 'Länder';

  @override
  String mapShareText(Object count) {
    return 'Hier war ich überall! 🌍 $count Meetups auf meiner Einundzwanzig Badge-Weltkarte.';
  }

  @override
  String get mapShareButton => 'Als Bild teilen';

  @override
  String get mapEmpty => 'Noch keine Badges mit Standort';

  @override
  String get mapEmptySub =>
      'Sammle Badges auf Meetups — sie erscheinen dann hier auf deiner Weltkarte.';

  @override
  String get gpsNoMeetupTitle => 'Kein Meetup in der Nähe';

  @override
  String get gpsNoMeetupBody =>
      'Im Umkreis von 10 km ist kein bekanntes Meetup eingetragen. Du kannst trotzdem eine Session starten — gib deinem Meetup einen Titel. Dein aktueller Standort wird automatisch als Veranstaltungsort auf der Karte gesetzt.';

  @override
  String get gpsMeetupNameLabel => 'Titel des Meetups';

  @override
  String get gpsMeetupNameHint => 'z. B. Bitcoin Stammtisch';

  @override
  String get gpsStartAnyway => 'Session starten';

  @override
  String get gpsNameRequired => 'Bitte gib einen Namen ein.';

  @override
  String get mnNodeDetailTitle => 'Verknüpfung';

  @override
  String get mnDegreeDirect => 'Direkt verbunden';

  @override
  String get mnDegreeSecond => '2. Grad';

  @override
  String get mnDegreeThird => '3. Grad';

  @override
  String get mnSharedMeetupsList => 'Gemeinsame Meetups';

  @override
  String get mnViaBridges => 'Verbunden über';

  @override
  String get mnNoSharedDetail => 'Keine direkten gemeinsamen Meetups';

  @override
  String get mnOpenInNostr => 'In Nostr öffnen';

  @override
  String get mnTapHint => 'Tippe auf einen Punkt für Details';

  @override
  String get mnLegendDirect => 'Direkt (1. Grad)';

  @override
  String get mnLegendSecond => '2. Grad';

  @override
  String get mnLegendThird => '3. Grad';

  @override
  String get resetBackupTitle => 'Daten sichern?';

  @override
  String get resetBackupBody =>
      'Beim Zurücksetzen werden ALLE Daten unwiderruflich gelöscht — deine Badges, dein Schlüssel und dein Profil. Ohne Backup lassen sich Badges NICHT wiederherstellen (auch nicht über Nostr). Möchtest du zuerst ein Backup erstellen?';

  @override
  String get resetBackupCreate => 'Backup erstellen';

  @override
  String get resetBackupSkip => 'Ohne Backup zurücksetzen';

  @override
  String get resetBackupDone => 'Backup erstellt. Jetzt zurücksetzen?';

  @override
  String get resetNowConfirm => 'Jetzt zurücksetzen';

  @override
  String get verifyBadgeSaved => 'Badge gespeichert ✓';

  @override
  String get tileConverter => 'Rechner';

  @override
  String get tileConverterSub => 'Kurs & Sats';

  @override
  String get convTitle => 'Wechselrechner';

  @override
  String get convYouPay => 'Betrag';

  @override
  String convRateInfo(Object price, Object cur) {
    return '1 BTC = $price $cur';
  }

  @override
  String convUpdated(Object time) {
    return 'Aktualisiert: $time';
  }

  @override
  String get convRefresh => 'Kurs aktualisieren';

  @override
  String get convOffline => 'Kurs konnte nicht geladen werden. Bist du online?';

  @override
  String get convLoading => 'Lade Kurs …';

  @override
  String get convSwap => 'Tauschen';

  @override
  String get convSelectCurrency => 'Währung wählen';

  @override
  String get convUnitSats => 'Satoshi';

  @override
  String get convUnitBtc => 'Bitcoin';

  @override
  String get convSource => 'Kurs von mempool.space';

  @override
  String get tileNews => 'News';

  @override
  String get tileNewsSub => 'Einundzwanzig Artikel lesen';

  @override
  String get newsTitle => 'News';

  @override
  String get newsEmpty => 'Keine Artikel gefunden.';

  @override
  String get newsLoading => 'Lade Artikel …';

  @override
  String get newsRefresh => 'Aktualisieren';

  @override
  String get newsSource => 'Artikel via Nostr (NIP-23)';

  @override
  String get newsOpenWebsite => 'Auf der Webseite öffnen';

  @override
  String get keyEduTitle => 'Dein Schlüssel zu Nostr';

  @override
  String get keyEduWhatNostrH => 'Was ist Nostr?';

  @override
  String get keyEduWhatNostrB =>
      'Nostr ist ein offenes, dezentrales Netzwerk – ähnlich wie das Internet selbst, aber für soziale Identität. Es gehört niemandem. Es gibt keine Firma, keinen Account und kein Passwort im klassischen Sinn. Statt dich bei einem Anbieter anzumelden, besitzt du einen kryptografischen Schlüssel, der dich überall im Netzwerk ausweist.';

  @override
  String get keyEduPairH => 'Dein Schlüsselpaar';

  @override
  String get keyEduPairB =>
      'Du bekommst gleich zwei zusammengehörige Schlüssel. Sie funktionieren wie ein Briefkasten: Der öffentliche Schlüssel ist die Adresse, die du jedem geben darfst – der private Schlüssel ist der einzige Schlüssel, der den Briefkasten öffnet.';

  @override
  String get keyEduNpubH => 'npub – dein öffentlicher Schlüssel';

  @override
  String get keyEduNpubB =>
      'Der npub (beginnt mit „npub1…“) ist deine öffentliche Identität. Du darfst ihn frei teilen – so finden dich andere, sehen deine Beiträge und können dir folgen. Er ist wie dein Benutzername, nur dass er dir wirklich gehört und niemand ihn dir wegnehmen kann.';

  @override
  String get keyEduNsecH => 'nsec – dein privater Schlüssel';

  @override
  String get keyEduNsecB =>
      'Der nsec (beginnt mit „nsec1…“) ist dein Geheimnis. Wer ihn besitzt, IST du – er kann in deinem Namen posten, deine Identität übernehmen und deine Reputation missbrauchen. Gib ihn NIEMALS weiter, tippe ihn nirgends ein, wo du unsicher bist, und mache niemals ein Foto davon in einer Cloud. Es gibt kein „Passwort vergessen“: Ist der nsec weg, ist die Identität für immer verloren.';

  @override
  String get keyEduIdentityH => 'Eine Identität, viele Möglichkeiten';

  @override
  String get keyEduIdentityB =>
      'Dieses Schlüsselpaar ist nicht nur für diese App. Es ist deine Identität im gesamten Nostr-Netzwerk: dieselbe Identität kannst du in vielen anderen Nostr-Apps nutzen – für soziale Netzwerke, Blogs, Chats, Lightning-Zahlungen und mehr. In dieser App ist sie zusätzlich mit deiner Reputation, deinen Meetup-Badges und deinem Vertrauensnetzwerk verknüpft. Deshalb ist ihr Schutz so wichtig: Verlierst du den Schlüssel, verlierst du nicht nur einen Login, sondern alles, was du dir aufgebaut hast.';

  @override
  String get keyEduProtectH => 'So schützt du deinen Schlüssel';

  @override
  String get keyEduProtect1 =>
      'Sichere den nsec sofort (z. B. in einem Passwort-Manager).';

  @override
  String get keyEduProtect2 => 'Teile nur den npub – niemals den nsec.';

  @override
  String get keyEduProtect3 =>
      'Lege ein verschlüsseltes Backup an (in dieser App möglich).';

  @override
  String get keyEduProtect4 =>
      'Für mehr Sicherheit: nutze eine Signer-App wie Amber.';

  @override
  String get keyEduUnderstood => 'Verstanden, Schlüssel erstellen';

  @override
  String get keyEduCancel => 'Abbrechen';

  @override
  String get keyEduIntro =>
      'Bevor du startest: Gleich erhältst du dein eigenes Schlüsselpaar. Nimm dir kurz Zeit – es lohnt sich zu verstehen, was du da bekommst.';

  @override
  String get tilePortal => 'Meine Meetups';

  @override
  String get tilePortalSub => 'Termine im Portal verwalten';

  @override
  String get portalTitle => 'Meine Meetups';

  @override
  String get portalNotConnected => 'Mit dem Portal verbinden';

  @override
  String get portalConnectInfo =>
      'Melde dich mit deinem Nostr-Schlüssel am Einundzwanzig-Portal an, um deine Meetup-Termine direkt aus der App zu verwalten.';

  @override
  String get portalConnect => 'Anmelden';

  @override
  String get portalConnecting => 'Anmeldung läuft …';

  @override
  String get portalLogout => 'Abmelden';

  @override
  String get portalLoginFailed => 'Anmeldung fehlgeschlagen';

  @override
  String get portalLoadingMeetups => 'Lade deine Meetups …';

  @override
  String get portalNoMeetups => 'Du verwaltest noch keine Meetups im Portal.';

  @override
  String get portalLeader => 'Organisator';

  @override
  String get portalNewEvent => 'Termin anlegen';

  @override
  String get portalEventTitle => 'Neuer Termin';

  @override
  String get portalFieldStart => 'Datum & Uhrzeit';

  @override
  String get portalPickDate => 'Datum wählen';

  @override
  String get portalPickTime => 'Uhrzeit wählen';

  @override
  String get portalFieldLocation => 'Ort';

  @override
  String get portalFieldLocationHint => 'z.B. Bitcoin-Treff Café (optional)';

  @override
  String get portalFieldDescription => 'Beschreibung';

  @override
  String get portalFieldDescriptionHint => 'Worum geht es? (optional)';

  @override
  String get portalFieldLink => 'Link';

  @override
  String get portalFieldLinkHint => 'https://… (optional)';

  @override
  String get portalSave => 'Termin speichern';

  @override
  String get portalSaving => 'Wird gespeichert …';

  @override
  String get portalCreatedOk => 'Termin angelegt ✓';

  @override
  String get portalNeedStart => 'Bitte Datum & Uhrzeit wählen.';

  @override
  String get portalSource => 'Verbunden mit portal.einundzwanzig.space';

  @override
  String get evCalendarButton => 'Veranstaltungskalender';

  @override
  String get evCalendarButtonSub => 'Alle Events im Überblick';

  @override
  String get calTitle => 'Veranstaltungskalender';

  @override
  String get calViewMonth => 'Monat';

  @override
  String get calViewYear => 'Jahr';

  @override
  String get calViewList => 'Liste';

  @override
  String get calToday => 'Heute';

  @override
  String get calNoEvents => 'Keine Veranstaltungen an diesem Tag.';

  @override
  String get calNoEventsRange => 'Keine Veranstaltungen in diesem Zeitraum.';

  @override
  String get calLoading => 'Lade Veranstaltungen …';

  @override
  String get calAddEvent => 'Event eintragen';

  @override
  String get calAllDay => 'Ganztägig';

  @override
  String get calSource => 'Events via Nostr (NIP-52)';

  @override
  String get calNewEventTitle => 'Veranstaltung eintragen';

  @override
  String get calFieldTitle => 'Titel';

  @override
  String get calFieldTitleHint => 'z.B. BTC Prag, Zitadelle …';

  @override
  String get calFieldLocation => 'Ort';

  @override
  String get calFieldLocationHint => 'z.B. Prag, Tschechien';

  @override
  String get calFieldDescription => 'Beschreibung';

  @override
  String get calFieldDescriptionHint => 'Worum geht es? (optional)';

  @override
  String get calFieldAllDay => 'Ganztägige Veranstaltung';

  @override
  String get calFieldStart => 'Beginn';

  @override
  String get calFieldEnd => 'Ende (optional)';

  @override
  String get calPickDateTime => 'Datum & Uhrzeit wählen';

  @override
  String get calPickDate => 'Datum wählen';

  @override
  String get calClearEnd => 'Ende entfernen';

  @override
  String get calPublish => 'Bei Nostr veröffentlichen';

  @override
  String get calPublishing => 'Wird veröffentlicht …';

  @override
  String get calPublishFail =>
      'Veröffentlichung fehlgeschlagen. Online & angemeldet?';

  @override
  String get calNeedTitle => 'Bitte gib einen Titel ein.';

  @override
  String get calNeedStart => 'Bitte Beginn wählen.';

  @override
  String get calPublishInfo =>
      'Diese Veranstaltung wird öffentlich bei Nostr eingetragen – jeder mit dieser App sieht sie in seinem Kalender.';

  @override
  String get calMonth1 => 'Januar';

  @override
  String get calMonth2 => 'Februar';

  @override
  String get calMonth3 => 'März';

  @override
  String get calMonth4 => 'April';

  @override
  String get calMonth5 => 'Mai';

  @override
  String get calMonth6 => 'Juni';

  @override
  String get calMonth7 => 'Juli';

  @override
  String get calMonth8 => 'August';

  @override
  String get calMonth9 => 'September';

  @override
  String get calMonth10 => 'Oktober';

  @override
  String get calMonth11 => 'November';

  @override
  String get calMonth12 => 'Dezember';

  @override
  String get calWd0 => 'Mo';

  @override
  String get calWd1 => 'Di';

  @override
  String get calWd2 => 'Mi';

  @override
  String get calWd3 => 'Do';

  @override
  String get calWd4 => 'Fr';

  @override
  String get calWd5 => 'Sa';

  @override
  String get calWd6 => 'So';

  @override
  String get calTypeMeetup => 'Meetup';

  @override
  String get calTypeEvent => 'Event';

  @override
  String get calLegendMeetup => 'Meetups';

  @override
  String get calLegendEvent => 'Veranstaltungen';

  @override
  String get portalManageEvents => 'Termine verwalten';

  @override
  String get portalExistingEvents => 'Bestehende Termine';

  @override
  String get portalLoadingEvents => 'Lade Termine …';

  @override
  String get portalNoEvents => 'Noch keine Termine für dieses Meetup.';

  @override
  String get portalEditEvent => 'Termin bearbeiten';

  @override
  String get portalUpdatedOk => 'Termin aktualisiert ✓';

  @override
  String get portalUpdate => 'Änderungen speichern';

  @override
  String get portalTapToEdit => 'Zum Bearbeiten antippen';

  @override
  String get hubTitle => 'Events';

  @override
  String get hubMeetups => 'Meetups';

  @override
  String get hubMeetupsSub => 'Meetups suchen & entdecken';

  @override
  String get hubCalendar => 'Veranstaltungskalender';

  @override
  String get hubCalendarSub => 'Alle Termine im Überblick, farblich sortiert';

  @override
  String get hubExternal => 'Externe Termine';

  @override
  String get hubExternalSub => 'Konferenzen & Events der Community';

  @override
  String get extTitle => 'Externe Termine';

  @override
  String get extIntro =>
      'Von der Community eingetragene Veranstaltungen (keine Meetups) – z.B. Konferenzen wie die BTC Prag oder die Zitadelle.';

  @override
  String get extLoading => 'Lade externe Termine …';

  @override
  String get extNone => 'Noch keine externen Termine eingetragen.';

  @override
  String get extAdd => 'Event eintragen';

  @override
  String get calFilterAll => 'Alle';

  @override
  String get calFilterMeetups => 'Meetups';

  @override
  String get calFilterExternal => 'Externe';

  @override
  String get calFilterLocation => 'Ort/Land suchen …';

  @override
  String get calFilterActive => 'Filter aktiv';

  @override
  String get calFilterClear => 'Filter zurücksetzen';

  @override
  String get calFilterNoMatch => 'Keine Events für diesen Filter.';

  @override
  String get calWorldwide => 'Weltweit';

  @override
  String get calCommunityOnly => 'Nur Community';

  @override
  String get calWorldwideHint =>
      'Weltweit zeigt alle Nostr-Events – auch fremde.';

  @override
  String get chTitle => 'Community';

  @override
  String get chPortal => 'Portal';

  @override
  String get chPortalSub => 'Meetups · Events · Kurse · Karte';

  @override
  String get chNews => 'News';

  @override
  String get chNewsSub => 'Artikel lesen';

  @override
  String get chNostr => 'Nostr';

  @override
  String get chNostrSub => 'Community-Feed';

  @override
  String get chShoutout => 'Shoutout';

  @override
  String get chShoutoutSub => 'Senden';

  @override
  String get chPodcast => 'Podcast';

  @override
  String get chPodcastSub => 'Anhören';

  @override
  String get paTitle => 'Portal';

  @override
  String get paMeetups => 'Meetups';

  @override
  String get paMeetupsSub => 'Alle Meetups durchsuchen';

  @override
  String get paEvents => 'Events & Zusagen';

  @override
  String get paEventsSub => 'Termine ansehen und direkt zusagen';

  @override
  String get paCourses => 'Kurse & Dozenten';

  @override
  String get paCoursesSub => 'Das Einundzwanzig-Bildungsangebot';

  @override
  String get paMap => 'Karte';

  @override
  String get paMapSub => 'Meetups in der Nähe';

  @override
  String get paMine => 'Meine Meetups';

  @override
  String get paMineSub => 'Termine verwalten (Organisator)';

  @override
  String get paWeb => 'Portal-Webseite';

  @override
  String get paWebSub => 'portal.einundzwanzig.space im Browser';

  @override
  String get rsvpLoading => 'Lade Events …';

  @override
  String get rsvpNone => 'Keine kommenden Events gefunden.';

  @override
  String get rsvpGoing => 'Zusagen';

  @override
  String get rsvpYouGo => 'Du hast zugesagt ✓';

  @override
  String get rsvpCount => 'Zusagen';

  @override
  String get rsvpNeedLogin =>
      'Zum Zusagen bitte zuerst im Portal anmelden (Meine Meetups).';

  @override
  String get rsvpFailed => 'Zusage fehlgeschlagen';

  @override
  String get crsLoading => 'Lade Kurse …';

  @override
  String get crsNone => 'Keine Kurse gefunden.';

  @override
  String get crsCourses => 'Kurse';

  @override
  String get crsLecturers => 'Dozenten';

  @override
  String get rsvpCancel => 'Absagen';

  @override
  String get crsAbout => 'Über den Kurs';

  @override
  String get crsUpcoming => 'Kommende Termine';

  @override
  String get crsLecturer => 'Referent';

  @override
  String get lecAbout => 'Über den Referenten';

  @override
  String get lecLinks => 'Links';

  @override
  String get crsOpenPortal => 'Im Portal öffnen';

  @override
  String get rsvpImComing => 'Ich komme';

  @override
  String get rsvpMaybe => 'Vielleicht';

  @override
  String get evOpenLink => 'Link öffnen';

  @override
  String get evShare => 'Teilen';

  @override
  String get evToCalendar => 'Zum Kalender';

  @override
  String get portalConnected => 'Portal verbunden';

  @override
  String get portalLoginPrompt =>
      'Zum Zusagen verbinden wir dich mit dem Portal.';

  @override
  String get portalTileSub => 'Für Zusagen & eigene Meetups';

  @override
  String get ldTitle => 'Organisatoren';

  @override
  String get ldManage => 'Organisatoren verwalten';

  @override
  String get ldManageSub => 'Vertraute als Leader hinzufügen';

  @override
  String get ldPickMeetup => 'Meetup wählen';

  @override
  String get ldCreator => 'Ersteller';

  @override
  String get ldAdd => 'Organisator hinzufügen';

  @override
  String get ldAddHint => 'npub des neuen Organisators';

  @override
  String get ldAddDo => 'Hinzufügen';

  @override
  String get ldRemove => 'Entfernen';

  @override
  String get ldRemoveConfirm => 'Diesen Organisator entfernen?';

  @override
  String get ldAdded => 'Organisator hinzugefügt';

  @override
  String get ldRemoved => 'Organisator entfernt';

  @override
  String get ldFailed => 'Aktion fehlgeschlagen';

  @override
  String get ldEmpty => 'Noch keine weiteren Organisatoren.';

  @override
  String get ldLoading => 'Lade Organisatoren …';

  @override
  String get ldNpubInvalid => 'Bitte einen gültigen npub eingeben.';

  @override
  String get ldAddButton => 'Admin hinzufügen';

  @override
  String get calLegendCourse => 'Kurse';

  @override
  String get calFilterCourses => 'Kurse';

  @override
  String get refreshRunning => 'Aktualisiere Daten …';

  @override
  String get refreshDone => 'Alles aktualisiert';

  @override
  String get v4vSectionTitle => 'Unterstützen';

  @override
  String get v4vSectionSubtitle =>
      'Value for Value – das Projekt mit Sats unterstützen';

  @override
  String get v4vTitle => 'Value for Value';

  @override
  String get v4vHeadline => 'Value for Value';

  @override
  String get v4vExplain1 =>
      'Diese App entsteht in echter Handarbeit für die Community – ohne Werbung, ohne Tracking, ohne Abo. Nach dem Prinzip \"Value for Value\" gibst du zurück, was dir die App wert ist.';

  @override
  String get v4vExplain2 =>
      'Deine Sats fließen direkt in die Weiterentwicklung des Projekts. Jeder Betrag hilft – vielen Dank!';

  @override
  String get v4vAmountLabel => 'Betrag';

  @override
  String get v4vDonateButton => 'Mit Lightning spenden';

  @override
  String get v4vRecipient => 'Empfänger';

  @override
  String get v4vErrInvalidAmount => 'Bitte einen gültigen Betrag eingeben.';

  @override
  String get v4vErrBelowMin => 'Betrag ist zu niedrig für diese Adresse.';

  @override
  String get v4vErrAboveMax => 'Betrag ist zu hoch für diese Adresse.';

  @override
  String get v4vErrUnreachable =>
      'Verbindung fehlgeschlagen. Bitte später erneut versuchen.';

  @override
  String get v4vErrGeneric => 'Die Invoice konnte nicht erstellt werden.';

  @override
  String get v4vNoWalletTitle => 'Keine Lightning-Wallet gefunden';

  @override
  String get v4vNoWalletBody =>
      'Es wurde keine App zum Bezahlen gefunden. Du kannst die Rechnung kopieren und in deiner Wallet einfügen.';

  @override
  String get v4vCopyInvoice => 'Rechnung kopieren';

  @override
  String get v4vCopied => 'Rechnung kopiert';

  @override
  String get convPremiumTitle => 'Auf-/Abschlag';

  @override
  String get convPremiumHint =>
      'Für Trades: Prozent-Aufschlag (+) oder Abschlag (−) auf den Kurs.';

  @override
  String get convPremiumResult => 'Mit Auf-/Abschlag';

  @override
  String get convPremiumBase => 'Basiskurs';

  @override
  String get convPremiumSats => 'Ergebnis in Sats';

  @override
  String get portalTokenMismatch =>
      'Dein Portal-Login gehört zu einem anderen Nostr-Schlüssel und wurde getrennt. Bitte verbinde das Portal neu — mit dem Schlüssel, mit dem du dort Leiter bist.';

  @override
  String get settingsLogTitle => 'Diagnose-Log';

  @override
  String get settingsLogSub => 'Ereignisse für die Fehlersuche';

  @override
  String get rsvpNoNames =>
      'Das Portal stellt für dieses Event keine Namensliste bereit.';

  @override
  String get rsvpAnon => 'Anonym';

  @override
  String get settingsMempool => 'Mempool-Server';

  @override
  String get settingsMempoolSub => 'Quelle der Bitcoin-Daten';

  @override
  String get mempoolTitle => 'Mempool-Server';

  @override
  String get mempoolIntro =>
      'Von hier holt die App Blockhöhe, Gebühren, Kurs und Lightning-Daten. Standard ist mempool.space. Wer über Tor surft, sollte die Onion-Adresse wählen — mempool.space weist Anfragen von Tor-Exit-Knoten oft ab.';

  @override
  String get mempoolClearnetTitle => 'Standard (Clearnet)';

  @override
  String get mempoolTorTitle => 'Tor / Onion';

  @override
  String get mempoolTorSub => 'Offizielle .onion von mempool.space';

  @override
  String get mempoolTorHint =>
      'Funktioniert nur, wenn Orbot im VPN-Modus läuft und diese App einschließt. Ohne Orbot ist eine .onion-Adresse nicht erreichbar. Tor ist langsamer — die Daten brauchen etwas länger.';

  @override
  String get mempoolCustomTitle => 'Eigene Instanz';

  @override
  String get mempoolCustomSub => 'Eigener Node (Umbrel, Start9, RaspiBlitz …)';

  @override
  String get mempoolSave => 'Speichern';

  @override
  String get mempoolSaved => 'Gespeichert';

  @override
  String get mempoolInvalidUrl =>
      'Das sieht nicht nach einer gültigen Adresse aus.';

  @override
  String get mempoolTest => 'Verbindung testen';

  @override
  String get mempoolTesting => 'Teste …';

  @override
  String get mempoolTestOk => 'Verbindung steht';

  @override
  String get mempoolTestFail => 'Keine Verbindung';

  @override
  String get mempoolTestBlocked =>
      'Der Server weist die Anfrage ab. Bei Tor: Onion-Adresse wählen.';

  @override
  String get mempoolTestOnionFail =>
      'Onion nicht erreichbar. Läuft Orbot im VPN-Modus und ist diese App eingeschlossen?';

  @override
  String get mempoolActive => 'Aktive Quelle';

  @override
  String get dashSource => 'Daten';

  @override
  String get dashPartial => 'Nur teilweise geladen';

  @override
  String get dashOfflineTitle => 'Keine Verbindung';

  @override
  String get dashOfflineBody =>
      'Es konnten keine Daten geladen werden. Prüfe deine Internetverbindung — oder wähle eine andere Datenquelle.';

  @override
  String get dashBlockedTitle => 'Server weist Anfragen ab';

  @override
  String get dashBlockedBody =>
      'mempool.space blockt diese IP-Adresse. Das passiert typischerweise über Tor, weil sich viele Nutzer einen Exit-Knoten teilen. Abhilfe: Onion-Adresse oder eigene Instanz verwenden.';

  @override
  String get dashChangeServer => 'Datenquelle ändern';
}
