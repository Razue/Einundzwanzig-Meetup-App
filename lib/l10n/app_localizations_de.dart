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
}
