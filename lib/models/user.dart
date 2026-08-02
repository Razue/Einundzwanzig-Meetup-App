import 'package:shared_preferences/shared_preferences.dart';
import '../services/secure_key_store.dart';
import '../services/admin_status_verifier.dart';
import 'badge.dart';
import '../services/signing_service.dart';

class UserProfile {
  String nickname;
  String fullName;
  String telegramHandle;
  String nostrNpub;       // Öffentlicher Schlüssel (npub1...)
  String twitterHandle;
  bool isNostrVerified;   // Hat einen gültigen Nostr-Key
  bool isAdminVerified;
  String homeMeetupId; // intern: Widget-Routing-Ziel = aktuell vorderstes Meetup
  /// FAVORITEN: mehrere gleichwertige Meetups (Stadtnamen). Die Dashboard-
  /// Kachel zeigt daraus swipebar je Favorit das naechste Event. homeMeetupId
  /// bleibt erhalten (= erster Favorit) fuer das Homescreen-Widget-Routing.
  List<String> favoriteMeetupIds;
  bool hasNostrKey;       // Hat der User ein Keypair in der App?

  // ── QUELLENUNABHÄNGIGER ADMIN-STATUS ──────────────────────────────
  // Jede Quelle hat ihr EIGENES Flag. isAdmin ist daraus ABGELEITET:
  // wahr, sobald IRGENDEINE Quelle es rechtfertigt. So kann kein Prüfer
  // dem anderen die Rechte wegnehmen (Portal-Entzug löscht nicht die
  // WoT-Bürgschaft und umgekehrt). Entzogen wird erst, wenn ALLE
  // zutreffenden Quellen den Status verneinen.
  bool adminViaPortal = false;  // Portal-Organisator (my-meetups)
  bool adminViaVouch  = false;  // WoT-Bürgschaft / Trust Score
  bool adminViaSeed   = false;  // Seed-Admin (fest)

  /// Abgeleiteter Admin-Status: true, sobald eine Quelle greift.
  bool get isAdmin => adminViaPortal || adminViaVouch || adminViaSeed;
  set isAdmin(bool v) {
    // Rückwärtskompatibel: Setzt/löscht die "vouch"-Quelle. Direkte
    // Zuweisungen (Legacy) landen hier; quellen-spezifische Setter unten.
    if (!v) { adminViaVouch = false; }
    else { adminViaVouch = true; }
  }

  /// Abgeleitete Quelle (für Anzeige/Claims). Priorität: Seed > Portal > Vouch.
  String get promotionSource {
    if (adminViaSeed) return 'seed_admin';
    if (adminViaPortal) return 'portal_organizer';
    if (adminViaVouch) return 'trust_score';
    return '';
  }
  set promotionSource(String s) {
    // Legacy-Kompatibilität: mappt einen Einzelwert auf das passende Flag.
    switch (s) {
      case 'seed_admin': adminViaSeed = true; break;
      case 'portal_organizer': adminViaPortal = true; break;
      case 'trust_score': adminViaVouch = true; break;
      case '': /* nichts explizit setzen */ break;
    }
  }

  // Security Audit C2: Wird true erst NACH kryptographischer Prüfung
  // Der SharedPreferences-Cache wird für Offline-UI genutzt,
  // aber sicherheitskritische Ops prüfen _adminCryptoVerified.
  bool _adminCryptoVerified = false;
  bool get isAdminCryptoVerified => _adminCryptoVerified;

  bool get hasCustomNickname {
    final trimmed = nickname.trim();
    return trimmed.isNotEmpty && trimmed != 'Anon';
  }

  bool get isOnboarded => hasCustomNickname || isVerified;

  UserProfile({
    this.nickname = "Anon",
    this.fullName = "",
    this.telegramHandle = "",
    this.nostrNpub = "",
    this.twitterHandle = "",
    this.isNostrVerified = false,
    this.isAdminVerified = false,
    bool isAdmin = false,
    this.homeMeetupId = "",
    this.favoriteMeetupIds = const [],
    this.hasNostrKey = false,
    String promotionSource = "",
  }) {
    // Konstruktor-Kompat: initiale Werte auf die Quellen-Flags mappen.
    if (promotionSource.isNotEmpty) {
      this.promotionSource = promotionSource;
    } else if (isAdmin) {
      adminViaVouch = true;
    }
  }

  static Future<UserProfile> load() async {
    final prefs = await SharedPreferences.getInstance();

    // Prüfe ob ein Nostr-Keypair existiert (über SecureKeyStore)
    final hasKey = await SecureKeyStore.hasKey();

    // Wenn Keypair vorhanden, npub aus SecureKeyStore nehmen (hat Vorrang)
    String npub = prefs.getString('nostr') ?? "";
    if (hasKey) {
      final keyNpub = await SecureKeyStore.getNpub();
      if (keyNpub != null && keyNpub.isNotEmpty) {
        npub = keyNpub;
      }
    }

    // Amber-Modus: kein lokaler nsec, aber eine gültige Identität.
    // npub kommt dann vom SigningService (verbundener Amber-Schlüssel).
    final bool amberMode = await SigningService.isAmber;
    if (amberMode) {
      final amberNpub = await SigningService.npub();
      if (amberNpub != null && amberNpub.isNotEmpty) npub = amberNpub;
    }

    final profile = UserProfile(
      nickname: prefs.getString('nickname') ?? "Anon",
      fullName: prefs.getString('full_name') ?? "",
      telegramHandle: prefs.getString('telegram') ?? "",
      nostrNpub: npub,
      twitterHandle: prefs.getString('twitter') ?? "",
      isNostrVerified: hasKey || amberMode || (prefs.getBool('nostr_verified') ?? false),
      isAdminVerified: prefs.getBool('admin_verified') ?? false,
      // Cache-Wert laden — wird durch reVerifyAdmin()/_checkPortalOrganizer überschrieben
      isAdmin: prefs.getBool('is_admin') ?? false,
      homeMeetupId: prefs.getString('home_meetup') ?? "",
      // MIGRATION: Gibt es die neue Favoritenliste, nutze sie. Sonst leite
      // sie aus dem alten Einzel-Home-Meetup ab (Bestandsnutzer verlieren
      // nichts). Leerer Altwert -> leere Liste.
      favoriteMeetupIds: prefs.getStringList('favorite_meetups') ??
          (((prefs.getString('home_meetup') ?? '').isNotEmpty)
              ? [prefs.getString('home_meetup')!]
              : <String>[]),
      hasNostrKey: hasKey, // lokaler nsec vorhanden? (im Amber-Modus false)
      promotionSource: prefs.getString('promotion_source') ?? "",
    );
    // Quellen-Flags einzeln rekonstruieren. Sind die neuen Keys vorhanden,
    // haben sie Vorrang; sonst Fallback auf das alte promotion_source
    // (das der Konstruktor oben bereits auf EIN Flag gemappt hat).
    if (prefs.containsKey('admin_via_portal')) {
      profile.adminViaPortal = prefs.getBool('admin_via_portal') ?? false;
      profile.adminViaVouch  = prefs.getBool('admin_via_vouch') ?? false;
      profile.adminViaSeed   = prefs.getBool('admin_via_seed') ?? false;
    }
    return profile;
    // HINWEIS: _adminCryptoVerified bleibt false bis reVerifyAdmin() läuft
  }

  // =============================================
  // SECURITY AUDIT C2: Kryptographische Admin-Re-Verifikation
  // =============================================
  // Muss nach dem Laden der Badges aufgerufen werden.
  // Überschreibt den SharedPreferences-Cache mit dem
  // kryptographisch verifizierten Ergebnis.
  // =============================================
  Future<AdminVerification> reVerifyAdmin(List<MeetupBadge> badges) async {
    final verification = await AdminStatusVerifier.verifyAdminStatus(
      badges: badges,
    );

    // WICHTIG: Nur die WoT/Bürgschafts-QUELLE aktualisieren — das
    // Portal-Flag (adminViaPortal) bleibt unberührt, damit sich die
    // beiden Wege nicht gegenseitig die Rechte entziehen.
    if (verification.source == 'seed_admin') {
      adminViaSeed = verification.isAdmin;
    } else {
      adminViaVouch = verification.isAdmin;
    }
    isAdminVerified = isAdmin; // abgeleitet
    _adminCryptoVerified = true;

    await save();
    return verification;
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nickname', nickname);
    await prefs.setString('full_name', fullName);
    await prefs.setString('telegram', telegramHandle);
    await prefs.setString('nostr', nostrNpub);
    await prefs.setString('twitter', twitterHandle);
    await prefs.setBool('nostr_verified', isNostrVerified);
    await prefs.setBool('admin_verified', isAdminVerified);
    await prefs.setBool('is_admin', isAdmin);
    // Quellen-Flags einzeln persistieren, damit nach Neustart der genaue
    // Zustand (Portal UND/ODER Vouch UND/ODER Seed) erhalten bleibt.
    await prefs.setBool('admin_via_portal', adminViaPortal);
    await prefs.setBool('admin_via_vouch', adminViaVouch);
    await prefs.setBool('admin_via_seed', adminViaSeed);
    await prefs.setString('home_meetup', homeMeetupId);
    await prefs.setStringList('favorite_meetups', favoriteMeetupIds);
    await prefs.setString('promotion_source', promotionSource);
  }

  bool get isVerified => isNostrVerified || isAdminVerified;
}

