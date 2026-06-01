// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Einundzwanzig Meetup';

  @override
  String get navHome => 'Inicio';

  @override
  String get navWallet => 'Cartera';

  @override
  String get navEvents => 'Eventos';

  @override
  String get navProfile => 'Perfil';

  @override
  String get actionSave => 'Guardar';

  @override
  String get actionCancel => 'Cancelar';

  @override
  String get actionConfirm => 'Confirmar';

  @override
  String get actionDelete => 'Eliminar';

  @override
  String get actionContinue => 'Continuar';

  @override
  String get actionBack => 'Atrás';

  @override
  String get actionClose => 'Cerrar';

  @override
  String get actionRetry => 'Reintentar';

  @override
  String get actionOk => 'OK';

  @override
  String get actionUnderstood => 'Entendido';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsLanguageSystem => 'Sistema';

  @override
  String get trustScore => 'Puntuación de confianza';

  @override
  String get reputation => 'Reputación';

  @override
  String get reputationShareQr => 'Compartir QR';

  @override
  String get community => 'Comunidad';

  @override
  String get communityPortal => 'Portal';

  @override
  String get homeMeetup => 'Meetup principal';

  @override
  String get shoutout => 'Mención';

  @override
  String get joinCommunity => 'Unirse a la comunidad';

  @override
  String get identityVerified => 'Verificado';

  @override
  String get verifiedByAdmin => 'Verificado por admin';

  @override
  String get nostrVerified => 'Verificado en Nostr';

  @override
  String get profileNickname => 'Apodo';

  @override
  String get profileChooseHomeMeetup => 'Elige tu meetup principal';

  @override
  String get profileYourIdentity => 'Tu identidad';

  @override
  String get profileNostrKey => 'Clave Nostr';

  @override
  String get profileKeyActive => 'Clave activa';

  @override
  String get requiredField => 'Campo obligatorio — complétalo';

  @override
  String get requiredHomeMeetup =>
      'Campo obligatorio — elige tu meetup principal';

  @override
  String fillRequired(String fields) {
    return 'Completa: $fields';
  }

  @override
  String get identityGenerateKey => 'Crear una clave nueva';

  @override
  String get identityConnectAmber => 'Conectar con Amber';

  @override
  String get identityImportNsec => 'Importar nsec existente';

  @override
  String get amberConnected =>
      '¡Conectado con Amber! Tu nsec permanece en Amber.';

  @override
  String get amberNotFound => 'Amber no encontrado';

  @override
  String get amberCancelled => 'Conexión cancelada en Amber.';

  @override
  String get walletTitle => 'Cartera de insignias';

  @override
  String badgesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count insignias',
      one: '1 insignia',
      zero: 'Sin insignias',
    );
    return '$_temp0';
  }

  @override
  String eventInDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days días',
      one: '1 día',
      zero: 'hoy',
    );
    return 'en $_temp0';
  }

  @override
  String get tileTrustScore => 'Trust Score';

  @override
  String get tileReputation => 'Reputación';

  @override
  String get tileReputationShare => 'Compartir QR';

  @override
  String get tileReputationCheck => 'Verificar';

  @override
  String get tileCommunity => 'Comunidad';

  @override
  String get tileCommunityPortal => 'Portal';

  @override
  String get tileEvents => 'Eventos';

  @override
  String get tileEventsCalendar => 'Calendario';

  @override
  String get tileShoutout => 'Shoutout';

  @override
  String get tileShoutoutSend => 'Enviar';

  @override
  String get tilePodcast => 'Podcast';

  @override
  String get tilePodcastListen => 'Escuchar';

  @override
  String get tileNostr => 'Nostr';

  @override
  String get tileNostrCommunity => 'Comunidad';

  @override
  String get tileOrganizer => 'Organizador';

  @override
  String get tileOrganizerPanel => 'Panel de admin';

  @override
  String get tileOrganizerNew => 'Nuevo vía Trust Score';

  @override
  String get tileWot => 'WoT';

  @override
  String get tileWotSubtitle => 'Web of Trust';

  @override
  String get homeMeetupLabel => 'MEETUP PRINCIPAL';

  @override
  String get homeMeetupChoose => 'Elige tu meetup';

  @override
  String get homeMeetupChooseSub => 'Selecciona tu meetup habitual';

  @override
  String homeMeetupBadges(int count) {
    return '$count insignias';
  }

  @override
  String get homeMeetupToday => '¡Hoy!';

  @override
  String get homeMeetupTomorrow => 'Mañana';

  @override
  String homeMeetupInDays(int days) {
    return 'en $days días';
  }

  @override
  String get homeMeetupNoDate => 'Sin fecha programada';

  @override
  String get homeMeetupNextEvent => 'Próximo meetup';

  @override
  String get homeMeetupNoneSoon => 'Sin fecha a la vista.\n¡Hora de cambiarlo!';

  @override
  String get homeMeetupSelectFirst => '¡Elige primero el\nmeetup principal!';

  @override
  String get btnEvents => 'EVENTOS';

  @override
  String get statusLive => 'EN VIVO';

  @override
  String get statusMeetupActive => 'Meetup activo';

  @override
  String get loading => 'Cargando...';

  @override
  String get organizerPromoted => '¡Ahora eres ORGANIZADOR!';

  @override
  String get resetTitle => '¿Restablecer la app?';

  @override
  String get resetBody => 'Se eliminarán todas las insignias y tu perfil.';

  @override
  String get resetCancel => 'Cancelar';

  @override
  String get resetConfirm => 'ELIMINAR';

  @override
  String get settingsSectionBackup => 'COPIA DE SEGURIDAD';

  @override
  String get settingsSectionLanguage => 'IDIOMA';

  @override
  String get settingsSectionNostr => 'RED NOSTR';

  @override
  String get settingsSectionControl => 'CONTROLES';

  @override
  String get settingsSectionAccount => 'CUENTA';

  @override
  String get settingsBackup => 'Crear copia de seguridad';

  @override
  String get settingsBackupSub => 'Protege tu cuenta';

  @override
  String get settingsLanguageTitle => 'Idioma';

  @override
  String get settingsLanguageChoose => 'Elegir idioma';

  @override
  String get settingsRelays => 'Relays Nostr';

  @override
  String get settingsRelaysSub => 'Configurar relays';

  @override
  String get settingsHaptic => 'Vibración';

  @override
  String get settingsHapticOn => 'Activado';

  @override
  String get settingsHapticOff => 'Desactivado';

  @override
  String get settingsReset => 'Restablecer la app';

  @override
  String get settingsResetSub => 'Elimina perfil e insignias';

  @override
  String get introTagline => 'TU COMUNIDAD BITCOIN';

  @override
  String get introJoin => 'UNIRSE A LA COMUNIDAD';

  @override
  String get introLoadBackup => 'CARGAR COPIA';

  @override
  String get introSetIdentity => 'Primero configura tu identidad.';

  @override
  String get navWalletTab => 'Cartera';

  @override
  String get navProfileTab => 'Perfil';

  @override
  String get scanBadge => 'Escanear insignia';

  @override
  String get scanBadgeSub => 'Código QR o etiqueta NFC del meetup';

  @override
  String get scanReputation => 'Verificar reputación';

  @override
  String get scanReputationSub => 'Verificar el Trust Score de otra persona';

  @override
  String get calendarTitle => 'EVENTOS MEETUP';

  @override
  String get calendarSearch => 'Buscar (p.ej. Múnich, Bitcoin...)';

  @override
  String get calendarNoEvents => 'No se encontraron eventos.';

  @override
  String get sectionDescription => 'DESCRIPCIÓN';

  @override
  String get sectionLocation => 'UBICACIÓN';

  @override
  String get sectionDates => 'FECHAS';

  @override
  String get sectionLinks => 'ENLACES';

  @override
  String get meetupRoute => 'Ruta';

  @override
  String get meetupNoDatesCal => 'Sin fechas en el calendario ahora.';

  @override
  String get errorOpenLink => 'No se pudo abrir el enlace';

  @override
  String get walletNoBadges => 'Aún no hay insignias';

  @override
  String get walletNoBadgesSub =>
      '¡Visita meetups y escanea etiquetas NFC para coleccionar insignias!';

  @override
  String get walletShareReputation => 'COMPARTIR REPUTACIÓN';

  @override
  String get walletShowQr => 'Mostrar código QR';

  @override
  String get walletShowQrSub => 'Para escanear in situ';

  @override
  String get walletExportJson => 'Exportar como JSON';

  @override
  String get walletExportJsonSub => 'Exportación firmada con prueba Schnorr';

  @override
  String get walletShareText => 'Compartir como texto';

  @override
  String get walletShareTextSub => 'Legible para todos (se copia en la web)';

  @override
  String get walletShareTitle => 'Compartir reputación';

  @override
  String get walletJsonCopied => 'Datos JSON copiados al portapapeles';

  @override
  String get walletReputationCopied => 'Reputación copiada al portapapeles';

  @override
  String get cancel => 'Cancelar';

  @override
  String get badgeDetailsTitle => 'Detalles de la insignia';

  @override
  String get badgeShare => 'Compartir insignia';

  @override
  String get badgeShareCaps => 'COMPARTIR INSIGNIA';

  @override
  String get badgeClose => 'CERRAR';

  @override
  String get badgeProofTitle => 'Prueba criptográfica';

  @override
  String get badgeProofOfAttendance => 'PROOF OF ATTENDANCE';

  @override
  String get badgeProofDesc =>
      'Esta insignia confirma criptográficamente que estuviste presente.';

  @override
  String get badgeMeetup => 'Meetup';

  @override
  String get badgeMeetupDate => 'Fecha del meetup';

  @override
  String get badgeMeetupId => 'ID del meetup';

  @override
  String get badgeOrganizerNpub => 'Organizador (npub)';

  @override
  String get badgeSignatureType => 'Tipo de firma';

  @override
  String get badgeTransmission => 'Transmisión';

  @override
  String get badgeTimestamp => 'Marca de tiempo';

  @override
  String get badgeScanTime => 'Hora del escaneo';

  @override
  String get badgeVerificationHash => 'HASH DE VERIFICACIÓN';

  @override
  String get badgeClaimBinding => 'Vinculación del claim';

  @override
  String get badgeBound => 'Vinculado ✓';

  @override
  String get badgeNotBound => 'No vinculado';

  @override
  String get badgeClaimedLater => 'Reclamado después';

  @override
  String get badgeNote => 'Nota';

  @override
  String get badgeNoSignature => 'Sin firma';

  @override
  String get badgeHashCopied => 'Hash copiado';

  @override
  String get badgeInfoCopied => 'Info de insignia copiada';

  @override
  String get badgeNfcTag => 'Etiqueta NFC';

  @override
  String get badgeRollingQr => 'Código QR rotativo';

  @override
  String get levelNew => 'NUEVO';

  @override
  String get levelStarter => 'INICIAL';

  @override
  String get levelActive => 'ACTIVO';

  @override
  String get levelEstablished => 'ESTABLECIDO';

  @override
  String get levelVeteran => 'VETERANO';

  @override
  String get reputationTitle => 'REPUTACIÓN';

  @override
  String get reputationNoBadges => 'AÚN SIN INSIGNIAS';

  @override
  String get reputationNoProofs => 'Aún sin pruebas criptográficas';

  @override
  String get reputationBuildHint1 =>
      'Visita un meetup y escanea una insignia para ';

  @override
  String get reputationBuildHint2 => 'construir tu reputación.';

  @override
  String get reputationScanQr => 'ESCANEAR CÓDIGO QR';

  @override
  String get reputationShareImage => 'COMPARTIR QR COMO IMAGEN';

  @override
  String get reputationUpdateRelays => 'ACTUALIZAR EN RELAYS';

  @override
  String get reputationPublishing => 'PUBLICANDO...';

  @override
  String get reputationBadges => 'Insignias';

  @override
  String get reputationMeetups => 'Meetups';

  @override
  String get reputationSigners => 'Firmantes';

  @override
  String get reputationBound => 'Vinculado';

  @override
  String get reputationSchnorrSigned => 'Firmado Schnorr';

  @override
  String get reputationSignedNoId => 'Firmado (sin identidad)';

  @override
  String get reputationNoIdentity =>
      'Sin identidad vinculada. Añade Telegram o Nostr en tu perfil.';

  @override
  String get reputationCheck => 'Verificar reputación';

  @override
  String get reputationVerified => 'Mi reputación de meetup verificada';

  @override
  String get reputationCodeFrom => 'Código de reputación de';

  @override
  String get portalDiscover => 'DESCUBRIR';

  @override
  String get portalQuickAccess => 'ACCESO RÁPIDO';

  @override
  String get portalPodcastMedia => 'PODCAST Y MEDIOS';

  @override
  String get portalSocialNetworks => 'REDES SOCIALES';

  @override
  String get portalAssociation => 'ASOCIACIÓN';

  @override
  String get portalProfile => 'Tu perfil e insignias';

  @override
  String get portalMeetupMap => 'Mapa de meetups';

  @override
  String get portalMeetupMapSub => 'Meetups cerca de ti';

  @override
  String get portalBeginnerPath => 'El Camino (principiantes)';

  @override
  String get portalShoutoutSend => 'Enviar shoutout';

  @override
  String get portalMembership => 'Hazte miembro';

  @override
  String get portalSoundboard => 'Soundboard';

  @override
  String get portalClipsSounds => 'Clips y sonidos';

  @override
  String get portalInterviews => 'Entrevistas';

  @override
  String get portalMediaArticles => 'Medios y artículos';

  @override
  String get portalMerch => 'Merch y productos Bitcoin';

  @override
  String get portalShop => 'Tienda';

  @override
  String get portalDonate => 'Donar';

  @override
  String get portalContact => 'Contacto';

  @override
  String get portalPrivacy => 'Privacidad';

  @override
  String get portalStatutes => 'Estatutos (PDF)';

  @override
  String get portalAboutAssoc => 'Sobre la asociación';

  @override
  String get portalOpen => 'Abrir portal';

  @override
  String get portalTagline => 'para bitcoiners alcistas.';

  @override
  String get portalInfotainment => 'Infotainment toximalista';

  @override
  String get portalPodcast => 'Podcast';

  @override
  String get portalProfile2 => 'Portal';
}
