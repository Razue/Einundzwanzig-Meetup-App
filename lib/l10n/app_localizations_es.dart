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
  String get profileNostrKey => 'CLAVE NOSTR';

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

  @override
  String get profileTitle => 'TU PERFIL';

  @override
  String get profileEditTitle => 'EDITAR PERFIL';

  @override
  String get profileSave => 'GUARDAR PERFIL';

  @override
  String get profileIntro => 'Elige un apodo y tu meetup principal.';

  @override
  String get profileNicknameMin => 'Mínimo 2 caracteres';

  @override
  String get profileNicknameReq => 'Campo obligatorio — complétalo';

  @override
  String get profileNicknameAnon => 'Elige tu propio apodo (no \'Anon\')';

  @override
  String get profileHomeMeetup => 'Meetup principal';

  @override
  String get profileHomeMeetupDash => 'Meetup principal';

  @override
  String get profileChooseMeetup => 'Elige tu meetup principal';

  @override
  String get profileMeetupReq => 'Obligatorio — elige tu meetup principal';

  @override
  String get profileSearchCity => 'Buscar ciudad...';

  @override
  String get profileIdentity => 'TU IDENTIDAD';

  @override
  String get profileStrengthen => 'REFORZAR IDENTIDAD';

  @override
  String get profileStrengthenDesc =>
      'Vincula plataformas y demuestra tu humanidad para subir tu Trust Score.';

  @override
  String get profileLinkPlatforms => 'Vincular plataformas';

  @override
  String get profilePlatformsSub => 'Telegram, X, anuncios';

  @override
  String get profileProofHumanity => 'Proof of Humanity';

  @override
  String get profileZapCheck => '¿Has hecho un zap? Verifícalo';

  @override
  String get profileLightningActive => 'Prueba Lightning activa';

  @override
  String get profileVerified => 'VERIFICADO';

  @override
  String get profileNostrKeyShort => 'Nostr';

  @override
  String get profileNoKey => 'Aún sin clave Nostr';

  @override
  String get profileKeyActiveCaps => 'CLAVE ACTIVA';

  @override
  String get profileCreateKey => 'CREAR CLAVE NOSTR';

  @override
  String get profileCreateNewKey => 'CREAR NUEVA CLAVE';

  @override
  String get profileCreating => 'CREANDO...';

  @override
  String get profileNoNostrNeeded =>
      'No necesitas cuenta Nostr. La app crea una clave por ti — toma un segundo.';

  @override
  String get profileKeyDesc =>
      'Tu clave criptográfica — firma insignias y verifica tu reputación.';

  @override
  String get profileConnectAmber => 'CONECTAR CON AMBER';

  @override
  String get profileAmberDesc =>
      'Amber es un firmante aparte para Android que mantiene tu clave privada ';

  @override
  String get profileAmberConnected =>
      '¡Conectado con Amber! Tu nsec permanece en Amber.';

  @override
  String get profileAmberNotFound => 'Amber no encontrado';

  @override
  String get profileAmberInstall =>
      'Clave guardada de forma segura. Instala Amber (p.ej. vía F-Droid ';

  @override
  String get profileAmberRetry => 'o el Zapstore) e inténtalo de nuevo.';

  @override
  String get profileAmberAborted => 'Conexión cancelada en Amber.';

  @override
  String get profileImportNsec => 'IMPORTAR NSEC EXISTENTE';

  @override
  String get profileImportNsecShort => 'IMPORTAR NSEC';

  @override
  String get profileImport => 'IMPORTAR';

  @override
  String get profileEnterNsec =>
      'Introduce tu clave privada Nostr (empieza con nsec1...):';

  @override
  String get profileKeyImported => '¡Clave importada!';

  @override
  String get profileShowNsecQ => '¿MOSTRAR NSEC?';

  @override
  String get profileShowNsecWarn =>
      'Se mostrará tu clave privada. ¡Asegúrate de que nadie mire tu pantalla!';

  @override
  String get profileShow => 'MOSTRAR';

  @override
  String get profileCopy => 'COPIAR';

  @override
  String get profileSecureKey => '¡PROTEGE TU CLAVE!';

  @override
  String get profileSaveKeyDesc =>
      'Esta es tu clave privada. ¡Guárdala en un lugar seguro! ';

  @override
  String get profileKeyNotShownAgain => '¡Esta clave NO se mostrará de nuevo!';

  @override
  String get profileKeySecured => 'LA HE GUARDADO';

  @override
  String get profileNpubCopied => '¡npub copiado!';

  @override
  String get profileNsecCopied => '¡nsec copiado! Guárdalo de forma segura.';

  @override
  String get profileNsecNeverLeaves => 'Tu nsec nunca sale de tu dispositivo.';

  @override
  String get profileWhoHasKey => 'Quien tenga esta clave TIENE tu identidad.';

  @override
  String get profileBackupNsec =>
      'Importante: ¡haz copia de tu nsec! Si pierdes el dispositivo, pierdes la clave.';

  @override
  String get profileNewKeypairDesc =>
      'Se creará un nuevo par de claves. Tu clave privada (nsec) se guarda de forma segura en tu dispositivo.\n\n';

  @override
  String get profileEdit => 'Editar';

  @override
  String get profileEditLoseStatus => 'EDITAR (perder estado)';

  @override
  String get profileWarning => '¡Atención!';

  @override
  String get profileEditWarnDesc =>
      'Si editas, pierdes tu estado \'Verificado\' y deberás ser reaprobado.';

  @override
  String get dialogCancel => 'CANCELAR';

  @override
  String get dialogCancelMixed => 'Cancelar';

  @override
  String get dialogCreate => 'CREAR';

  @override
  String errorGeneric(String msg) {
    return 'Error: $msg';
  }

  @override
  String errorAmber(String msg) {
    return 'Error de Amber: $msg';
  }

  @override
  String profileFillIn(Object fields) {
    return 'Por favor completa: $fields';
  }

  @override
  String get backupEncryptTitle => 'Cifrar copia de seguridad';

  @override
  String get backupDecryptTitle => 'Descifrar copia de seguridad';

  @override
  String get backupExportDesc =>
      'Establece una contraseña para proteger tu clave privada (nsec) en la copia.\n\n⚠️ Si olvidas esta contraseña, ¡la copia se perderá IRRECUPERABLEMENTE!';

  @override
  String get backupImportDesc =>
      'Esta copia está cifrada. Introduce la contraseña.';

  @override
  String get backupPassword => 'Contraseña';

  @override
  String get backupPasswordConfirm => 'Confirmar contraseña';

  @override
  String get backupPasswordEmpty => 'La contraseña no puede estar vacía';

  @override
  String get backupPasswordMin => 'Mínimo 8 caracteres';

  @override
  String get backupPasswordMismatch => 'Las contraseñas no coinciden';

  @override
  String get backupEncryptSave => 'Cifrar y guardar';

  @override
  String get backupDecryptLoad => 'Descifrar y cargar';

  @override
  String get backupShareTitle => 'Copia de Einundzwanzig App (Cifrada)';

  @override
  String get backupShareText =>
      'Tu copia cifrada. Ten lista tu contraseña para restaurarla.';

  @override
  String backupError(String msg) {
    return 'Error de copia: $msg';
  }

  @override
  String get backupCorrupt =>
      'El archivo de copia está dañado (error de formato).';

  @override
  String get backupWrongPassword => '¡Contraseña incorrecta o archivo dañado!';

  @override
  String get backupNotValid =>
      'El archivo no es una copia válida o tiene formato incorrecto.';

  @override
  String get backupNotEinundzwanzig =>
      'El archivo no es una copia válida de Einundzwanzig.';

  @override
  String backupLoaded(Object items) {
    return '✅ ¡Copia cargada! $items restaurado.';
  }

  @override
  String backupImportFailed(String msg) {
    return 'Importación fallida: $msg';
  }

  @override
  String get qrScanTitle => 'VERIFICAR REPUTACIÓN';

  @override
  String get qrResultTitle => 'RESULTADO';

  @override
  String get qrScanHint => 'Escanea un código QR\nde reputación Einundzwanzig';

  @override
  String get qrLoadFromGallery => 'CARGAR QR DESDE GALERÍA';

  @override
  String get qrBack => 'ATRÁS';

  @override
  String get qrNoCodeInImage => 'No se encontró código QR en la imagen';

  @override
  String get qrNotEinundzwanzig =>
      'Código QR encontrado, pero no es formato Einundzwanzig';

  @override
  String get qrVerified => 'VERIFICADO';

  @override
  String get qrVerifiedV1 => 'VERIFICADO (v1)';

  @override
  String get qrVerifiedV2 => 'VERIFICADO (v2)';

  @override
  String get qrSigInvalid => 'FIRMA NO VÁLIDA';

  @override
  String get qrFormatUnknown => 'FORMATO DESCONOCIDO';

  @override
  String get qrReadError => 'ERROR DE LECTURA';

  @override
  String get qrV2Subtitle => 'Firma legacy válida — sin prueba de insignia';

  @override
  String get qrV1Subtitle => 'Formato antiguo — sin vinculación de identidad';

  @override
  String get qrCantRead => 'No se pudo leer el código QR.';

  @override
  String qrProcessError(String msg) {
    return 'Error al procesar: $msg';
  }

  @override
  String get qrSectionIdentity => 'IDENTIDAD';

  @override
  String get qrNoIdentity => 'SIN IDENTIDAD';

  @override
  String get qrNoVerifiableIdentity => 'Sin identidad verificable.';

  @override
  String get qrSectionLightning => 'LIGHTNING';

  @override
  String get qrSectionSocial => 'RED SOCIAL';

  @override
  String get qrSectionPlatforms => 'PLATAFORMAS VINCULADAS';

  @override
  String get qrSectionMeetups => 'MEETUPS VISITADOS';

  @override
  String get qrHumanVerified => 'Humano verificado';

  @override
  String get qrLightningActive => 'Prueba Lightning activa';

  @override
  String get qrNoLightning => 'No se encontró prueba Lightning';

  @override
  String get qrNoZap => 'Sin actividad de zaps';

  @override
  String get qrNip05Invalid => 'NIP-05 no válido';

  @override
  String get qrYouFollow => 'Tú sigues';

  @override
  String get qrFollowsYou => 'Te sigue';

  @override
  String get qrMutualFollow => 'Seguimiento mutuo';

  @override
  String get qrNoDirectFollow => 'Sin seguimiento directo';

  @override
  String get qrDirectConnection => 'Conexión directa';

  @override
  String get qrBidirectional => 'Conexión bidireccional directa';

  @override
  String get qrOneWay => 'Conexión unidireccional';

  @override
  String get qrViaContacts => 'A través de contactos comunes';

  @override
  String get qrStrongOverlap => 'Fuerte solapamiento de red';

  @override
  String get qrPartiallyConnected => 'Parcialmente conectado';

  @override
  String get qrNoOverlap => 'Sin solapamiento';

  @override
  String get qrEndorsement => 'Respaldo de admins conocidos';

  @override
  String get qrSigVerified => 'Firma verificada';

  @override
  String get qrAnalyzingNetwork => 'Analizando red...';

  @override
  String get qrCheckingLightning => 'Verificando Lightning...';

  @override
  String get qrCheckingNip05 => 'Verificando NIP-05...';

  @override
  String get qrStatBadges => 'Insignias';

  @override
  String get qrStatMeetups => 'Meetups';

  @override
  String get qrStatSigners => 'Firmantes';

  @override
  String get qrStatBound => 'Vinculado';

  @override
  String get qrStatDays => 'Días';

  @override
  String get qrLabelNickname => 'Apodo';

  @override
  String get qrLabelTwitter => 'Twitter/X';

  @override
  String get qrPlatformOther => 'Otra';

  @override
  String get qrLinked => 'Vinculado';

  @override
  String get qrSigVerifiedShort => 'Firma verificada';

  @override
  String get qrLinkedShort => 'Vinculado';

  @override
  String get nfcDisabled => 'NFC está desactivado';

  @override
  String get nfcDisabledHint => 'NFC está desactivado. Por favor actívalo.';

  @override
  String get nfcUnavailable => 'NFC no disponible';

  @override
  String get nfcOpenSettings => 'ABRIR AJUSTES';

  @override
  String get nfcEnableHint => 'Activa NFC en los ajustes de tu dispositivo ';

  @override
  String get nfcSettingsAndroid => 'Android: Ajustes → Conexiones → NFC';

  @override
  String get nfcSettingsIos => 'iOS: Ajustes → NFC';

  @override
  String get verifyScanBadge => 'ESCANEAR INSIGNIA';

  @override
  String get verifyScanNfc => 'ESCANEAR ETIQUETA NFC';

  @override
  String get verifyScanQr => 'ESCANEAR QR';

  @override
  String get verifyScanQrCaps => 'ESCANEAR CÓDIGO QR';

  @override
  String get verifyReadyToScan => 'Listo para escanear';

  @override
  String get verifyWaitingNfc => 'Esperando etiqueta NFC...';

  @override
  String get verifyCheckingNfc => 'Verificando NFC...';

  @override
  String get verifyScanInstruction =>
      'Escanea la etiqueta NFC o el código QR\ndel organizador del meetup.';

  @override
  String get verifyScanQrInstruction =>
      'Escanea el código QR\ndel organizador del meetup';

  @override
  String get verifyNoNfcDevice =>
      'Este dispositivo no tiene NFC. Usa el escáner QR.';

  @override
  String get verifyNoNfcLong => 'Este dispositivo no admite NFC.\n\n';

  @override
  String get verifyUseQrInstead => 'Usa el escáner de códigos QR en su lugar ';

  @override
  String get verifyToGetBadge => 'para obtener tu insignia.';

  @override
  String get verifyAskScan => 'Pide a un participante que escanee tu etiqueta.';

  @override
  String get verifyCantSelfBadge =>
      'No puedes darte una insignia a ti mismo.\n';

  @override
  String get verifyBadgeFound => 'INSIGNIA ENCONTRADA';

  @override
  String get verifyAlreadyCollected => 'YA RECOGIDA';

  @override
  String get verifyAddToWallet => 'AÑADIR A LA CARTERA';

  @override
  String get verifyVerifiedAdmin => 'Admin verificado';

  @override
  String get verifyUnknownMeetup => 'Meetup desconocido';

  @override
  String get verifyNoExpiry => 'Sin caducidad';

  @override
  String get writerReadyToWrite => 'Listo para escribir';

  @override
  String get writerNoNfcDevice =>
      'Este dispositivo no tiene NFC. Usa códigos QR rotativos.';

  @override
  String get writerUseRollingQr =>
      'Puedes usar códigos QR rotativos en su lugar ';

  @override
  String get writerForYourMeetup => 'para tu meetup.';

  @override
  String get writerSelectHomeFirst =>
      'Primero selecciona un meetup principal en tu perfil';

  @override
  String get writerYourHomeMeetup => 'TU MEETUP PRINCIPAL';

  @override
  String get writerCreateTag => 'CREAR ETIQUETA';

  @override
  String get writerCreateMeetupTag => 'CREAR ETIQUETA MEETUP';

  @override
  String get writerMeetupTag => 'ETIQUETA MEETUP';

  @override
  String get writerSuccess => '¡ÉXITO!';

  @override
  String get writerValid6h => 'Válido por 6 horas';

  @override
  String get writerHoldTag => 'Acerca la etiqueta al dispositivo...';

  @override
  String get writerHoldTagInstruction =>
      'Acerca una etiqueta NFC al dispositivo.\nLos participantes la escanean para recoger una insignia.';

  @override
  String get writerFormatting => 'Formateando etiqueta vacía...';

  @override
  String get writerFormatFailed => 'Error de formateo';

  @override
  String get writerLoadingSession => 'Cargando datos de sesión...';

  @override
  String get writerJumpToQr => 'Saltando al código QR...';

  @override
  String get writerNoNdef => 'Formato NDEF no posible';

  @override
  String get writerTagReadOnly => 'La etiqueta es de solo lectura';

  @override
  String get writerCanOverwrite => 'La etiqueta se puede sobrescribir después';

  @override
  String get writerTagLost => 'Etiqueta perdida durante la escritura';

  @override
  String get writerTagRemovedEarly =>
      'Etiqueta retirada demasiado pronto — mantenla firme 2–3 segundos';

  @override
  String get writerUseNtag215 => 'Usa un NTAG215 (504B) o mayor.';

  @override
  String get writerToWriteTag => 'para escribir la etiqueta.\n\n';

  @override
  String verifyMsgLocation(String name) {
    return 'Lugar: $name';
  }

  @override
  String verifyMsgBlock(Object height) {
    return 'Bloque: $height';
  }

  @override
  String verifyMsgSignedBy(String signer) {
    return 'Firmado por: $signer';
  }

  @override
  String get verifyMsgProof => 'Prueba: Schnorr (BIP-340)';

  @override
  String verifyMsgTagExpiry(String expiry) {
    return 'Caducidad de etiqueta: $expiry';
  }

  @override
  String verifyAlreadyToday(String name) {
    return 'Ya recogida\n\nHoy ya tienes una insignia de:\n$name';
  }

  @override
  String get wotTitle => 'WEB OF TRUST';

  @override
  String get wotActiveOrganizers => 'ORGANIZADORES ACTIVOS';

  @override
  String get wotActiveOrganizer => 'ORGANIZADOR ACTIVO';

  @override
  String get wotActiveWarnings => 'AVISOS ACTIVOS';

  @override
  String get wotActiveWarning => 'Aviso activo';

  @override
  String get wotMyStatus => 'TU ESTADO';

  @override
  String get wotMyVouches => 'TUS AVALES';

  @override
  String get wotWhoYouVouchFor => 'POR QUIÉN AVALAS';

  @override
  String get wotWhoVouchesForYou => 'QUIÉN TE AVALA';

  @override
  String get wotWeightedReporting => 'SISTEMA DE DENUNCIAS PONDERADO';

  @override
  String get wotRestore => 'RESTAURAR';

  @override
  String get wotRevokeAll => 'REVOCAR TODO';

  @override
  String get wotPublishNostr => 'PUBLICAR EN NOSTR';

  @override
  String get wotVouch => 'AVALAR';

  @override
  String get wotVouchVerb => 'AVALAR';

  @override
  String get wotReportNpub => 'DENUNCIAR NPUB';

  @override
  String get wotScanNpub => 'ESCANEAR NPUB';

  @override
  String get wotPublishRevocation => 'PUBLICAR REVOCACIÓN';

  @override
  String get wotSigningPublishing => 'FIRMANDO Y PUBLICANDO...';

  @override
  String get wotSyncNetwork => 'Sincronizar red';

  @override
  String get wotBootstrapPhase => 'Fase de arranque';

  @override
  String get wotDecentralized => 'Descentralizado (Web of Trust)';

  @override
  String get wotMinVouches => 'Avaladores mín.';

  @override
  String get wotDistrustThreshold => 'Umbral de desconfianza';

  @override
  String get wotNotEnoughVouchers => 'AÚN SIN AVALES SUFICIENTES';

  @override
  String get wotVouchers => 'Avaladores';

  @override
  String get wotNoVouchersYet => 'Aún sin avaladores';

  @override
  String get wotNobodyYet => 'Nadie todavía';

  @override
  String get wotNotSuspendedWatch =>
      'Aún no suspendido, pero deberías estar atento.';

  @override
  String get wotNoReports => 'Sin denuncias';

  @override
  String get wotNoActiveAdmins => 'Sin admins activos';

  @override
  String get wotNoCleanNetwork =>
      'Actualmente no hay avisos abiertos\nen la red. Todo limpio.';

  @override
  String get wotNoOrganizersEnough =>
      'La red aún no tiene organizadores con avales suficientes.';

  @override
  String get wotNoVouchesFound =>
      'No se encontraron avales publicados en los relays.';

  @override
  String get wotTapPlusFirst => 'Toca + para dar tu primer aval.';

  @override
  String get wotAskOthersVouch => 'Pide a otros organizadores que te avalen.\n';

  @override
  String get wotNoDataLoaded =>
      'No se pudieron cargar los datos de la red.\nDesliza hacia abajo para actualizar.';

  @override
  String get wotNoRelay => 'Ningún relay accesible — inténtalo más tarde.';

  @override
  String get wotRevokeAllTitle => '¿REVOCAR TODOS LOS AVALES?';

  @override
  String get wotRevokeVouchTitle => '¿RETIRAR AVAL?';

  @override
  String get wotWithdrawVouch => 'Retirar aval';

  @override
  String get wotVouchWithdrawn => 'Aval retirado. No olvides publicar.';

  @override
  String get wotVouchGiven => '¡Aval otorgado! No olvides publicar.';

  @override
  String get wotAllRevoked => 'Todos los avales han sido revocados en la red.';

  @override
  String get wotReasonRequired => 'Motivo (obligatorio)';

  @override
  String get wotNpubRequired => 'npub (obligatorio)';

  @override
  String get wotNameAlias => 'Nombre / alias (opcional)';

  @override
  String get wotMeetupExample => 'Meetup (p. ej. Múnich)';

  @override
  String get wotReasonExample =>
      'p. ej. Falsifica insignias, sin meetup real...';

  @override
  String get wotNpubReasonRequired => 'npub y motivo son obligatorios.';

  @override
  String get wotScanInstruction =>
      'Escanea el código QR Nostr (npub)\ndel organizador.';

  @override
  String get wotVouchExplain =>
      'Avalas a este organizador con tu propia reputación.';

  @override
  String get wotEachVouchPersonal =>
      'Cada aval es tu voto personal de confianza — ';

  @override
  String get wotAfterPublishAll =>
      'tras publicar, toda la red ve por quién respondes.';

  @override
  String get wotWhoYouVouchExplain => 'Aquí ves por quién avalas TÚ. ';

  @override
  String get wotPublishUpdated => 'Luego publica tu lista actualizada ';

  @override
  String get wotSoNetworkKnows => 'para que la red se entere.';

  @override
  String get wotSingleReportNoWeight => 'Una sola denuncia no tiene peso — ';

  @override
  String get wotOnlyMultipleIndep =>
      'solo cuando varios organizadores independientes ';

  @override
  String get wotWarnSuspend => 'advierten, alguien queda suspendido. ';

  @override
  String get wotNobodyAlonePower =>
      'Nadie tiene poder sobre otros por sí solo.';

  @override
  String get wotYourReportAlone =>
      'Tu denuncia sola no tiene peso. Solo cuando ';

  @override
  String get wotOrgsWarnSuspended =>
      'organizadores advierten, el npub queda suspendido.';

  @override
  String get wotRevokeAllBody =>
      'Esto publica una lista vacía en Nostr y revoca TODOS ';

  @override
  String get wotFromOtherOrgs => 'de otros organizadores.';

  @override
  String get wotRestoreExplain =>
      'Los avales están firmados en Nostr. «Restaurar» recupera ';

  @override
  String get wotRestoreListBack =>
      'tu lista tras una reinstalación o un cambio de copia de seguridad.';

  @override
  String get wotVouchesSignedOnNostr =>
      'tus avales en la red — incluso los que ya no son ';

  @override
  String get wotVisibleLocally =>
      'visibles localmente.\n\nUsa esto si, tras una reinstalación, ';

  @override
  String get wotCantResolveOld => 'ya no puedes resolver tus avales antiguos.';

  @override
  String get wotRemovedFromList => 'será eliminado de tu lista de avales.\n\n';

  @override
  String get wotSuspendedByNetwork =>
      'suspendido por la red. Revisa tus avales.';

  @override
  String wotErrorLoading(String msg) {
    return 'Error al cargar: $msg';
  }

  @override
  String wotSyncFailed(String msg) {
    return 'Sincronización fallida: $msg';
  }

  @override
  String wotRevocationFailed(String msg) {
    return 'Revocación fallida: $msg';
  }

  @override
  String wotRestoreFailed(String msg) {
    return 'Restauración fallida: $msg';
  }

  @override
  String wotVouchesRestored(Object count) {
    return '$count avales restaurados desde Nostr.';
  }

  @override
  String wotNetworkHealth(String label) {
    return 'RED $label';
  }

  @override
  String wotVouchProgress(Object count, Object total) {
    return '$count / $total avales';
  }

  @override
  String wotReportsCount(Object count) {
    return '$count denuncias';
  }

  @override
  String wotNeedMoreVouches(Object count) {
    return 'Aún necesitas $count avales más ';
  }

  @override
  String wotVouchesRequired(Object count, Object total) {
    return '$count / $total necesarios';
  }

  @override
  String wotSuspensionProgress(Object count, Object total) {
    return '$count / $total suspensión';
  }

  @override
  String wotLiability(Object count) {
    return 'RESPONSABILIDAD: $count suspendidos';
  }

  @override
  String wotWarningCount(Object count) {
    return 'AVISO: $count denunciados';
  }

  @override
  String wotYourNpub(String npub) {
    return 'Tu npub: $npub';
  }

  @override
  String wotLiabilityBody(String names) {
    return 'Avalas a $names — estos npubs están suspendidos por la red. Revisa tus avales.';
  }

  @override
  String wotWarningBody(String names) {
    return 'Hay denuncias para $names. ';
  }

  @override
  String get wotVotes => 'Votos';

  @override
  String get wotSuspended => 'Suspendidos';

  @override
  String wotReportNoWeightThreshold(Object count) {
    return 'Tu denuncia sola no tiene peso. Solo cuando $count organizadores independientes advierten, el npub queda suspendido.';
  }

  @override
  String wotPublishedLive(Object count) {
    return '¡Tu Web of Trust está activo ($count relays)!';
  }

  @override
  String wotReportPublished(Object count) {
    return 'Denuncia publicada en $count relays.';
  }

  @override
  String wotErrorShort(String msg) {
    return 'Error: $msg';
  }

  @override
  String get wotOffline => 'Sin conexión';

  @override
  String get wotActive => 'Activos';

  @override
  String get wotPhase => 'Fase';

  @override
  String get wotPhaseDecentralized => 'Descentralizado';

  @override
  String get wotPhaseBootstrap => 'Arranque';

  @override
  String get wotReportsLabel => 'Denuncias';

  @override
  String get wotVouchersLabel => 'AVALADORES:';

  @override
  String writerTagTooSmall(Object data, Object max) {
    return '¡Etiqueta demasiado pequeña! Datos: ${data}B, etiqueta: ${max}B.\n';
  }

  @override
  String get writerTagWritten => '✅ ¡ETIQUETA MEETUP escrita!\n\n';

  @override
  String writerCompactSize(Object size) {
    return '📦 ${size}B (compacto)\n';
  }

  @override
  String writerValidHours(Object hours) {
    return '⏱️ Válido por ${hours}h\n\n';
  }

  @override
  String get verifyErrNoNdef => '✗ Sin etiqueta NDEF';

  @override
  String get verifyErrTagEmpty => '✗ Etiqueta vacía';

  @override
  String get verifyErrPayloadEmpty => '✗ Payload vacío';

  @override
  String get verifyErrInvalidFormat => '✗ Formato no válido';

  @override
  String verifyErrInvalidTag(String msg) {
    return '✗ Etiqueta no válida: $msg';
  }

  @override
  String verifyErrReadError(String msg) {
    return '✗ Error de lectura: $msg';
  }

  @override
  String verifyErrNfcError(String msg) {
    return '✗ Error NFC: $msg';
  }

  @override
  String verifyErrQrExpired(String msg) {
    return '✗ ¡Código QR caducado!\n$msg\n\nEscanea directamente en la pantalla del organizador.';
  }

  @override
  String verifyErrPrefix(String msg) {
    return '✗ $msg';
  }

  @override
  String writerStartError(String msg) {
    return '❌ Error de inicio: $msg';
  }

  @override
  String writerFitsNtag215(Object size) {
    return '~${size}B — cabe en NTAG215 (492B)';
  }

  @override
  String get writerNoHomeMeetup => '⚠️ Sin meetup principal definido';

  @override
  String get writerHomeMeetupNotFound => '⚠️ Meetup principal no encontrado';

  @override
  String get writerNoActiveSession =>
      '❌ No se encontró sesión de meetup activa. Reinicia el meetup.';

  @override
  String get admMyWebOfTrust => 'MI WEB OF TRUST';

  @override
  String get admMyDelegations => 'TUS DELEGACIONES';

  @override
  String get admCoAdminKnight => 'NOMBRAR CO-ADMIN';

  @override
  String get admKnighthood => 'NOMBRAMIENTO';

  @override
  String get admRemove => 'ELIMINAR';

  @override
  String get admCancel => 'CANCELAR';

  @override
  String get admRevokeTrust => '¿RETIRAR CONFIANZA?';

  @override
  String get admRevokeTrustShort => 'Retirar confianza';

  @override
  String get admSyncWot => 'Sincronizar Web of Trust';

  @override
  String get admNobodyDelegated => 'Aún no has delegado a nadie.';

  @override
  String get admTapKnighthood =>
      'Toca \'NOMBRAMIENTO\' abajo\npara dar confianza a un nuevo organizador\nen tu meetup.';

  @override
  String get admVouchNewExplain =>
      'Avalas a este nuevo organizador con tu propia reputación.';

  @override
  String get admScanNewOrg =>
      'Escanea el código QR Nostr (npub) del nuevo organizador.';

  @override
  String get admNetworkLearnsKnight =>
      'La red solo conoce a tus nuevos co-admins\ncuando publicas tu firma en Nostr.';

  @override
  String get admMustRepublish =>
      'Debes volver a publicar la lista después para que la red se entere.';

  @override
  String get admPublishEmptyRevoke =>
      'Publica una lista vacía para revocar todas las delegaciones\nen la red.';

  @override
  String get admRestoreListBack => 'tu lista tras una reinstalación.';

  @override
  String get admSigningSending => 'Firmando y enviando a Nostr...';

  @override
  String get admRestoringVouches => 'Restaurando mis avales desde Nostr...';

  @override
  String get admSyncingWot => 'Sincronizando Web of Trust...';

  @override
  String get admRevokingAll => 'Revocando todos los avales...';

  @override
  String admRevokeTrustBody(String name, String meetup) {
    return '¿Quieres retirar la confianza como admin para $meetup a $name?\n\n';
  }

  @override
  String get admRestoreExplain =>
      'Los avales están firmados en Nostr. «Restaurar» recupera ';

  @override
  String admVouchedCount(Object count) {
    return 'Has avalado a $count organizadores.';
  }

  @override
  String get admCoAdminAdded => '✅ ¡Co-admin añadido! No olvides publicar.';

  @override
  String get apMeetupSession => 'SESIÓN DE MEETUP';

  @override
  String get apSessionRunning => 'SESIÓN ACTIVA';

  @override
  String get apOpenActiveMeetup => 'ABRIR MEETUP ACTIVO';

  @override
  String get apStartMeetup => 'INICIAR MEETUP';

  @override
  String get apEndMeetupEarly => 'Finalizar meetup antes';

  @override
  String get apNetwork => 'RED';

  @override
  String get apOrganizer => 'ORGANIZADOR';

  @override
  String get apWebOfTrust => 'WEB OF TRUST';

  @override
  String get apHowItWorks => 'CÓMO FUNCIONA';

  @override
  String get apManageVouches => 'Gestionar avales, estado de red, denuncias';

  @override
  String get apNewMeetupQ => '¿Iniciar nuevo meetup?';

  @override
  String get apSessionEndQ => '¿Finalizar sesión?';

  @override
  String get apCancel => 'Cancelar';

  @override
  String get apStart => 'Iniciar';

  @override
  String get apEnd => 'Finalizar';

  @override
  String get apSeedAdmin => 'Seed Admin';

  @override
  String get apViaTrustScore => 'Vía Trust Score';

  @override
  String get apNewMeetupBody =>
      'Esto crea una firma única (tiempo de bloque) para las próximas 6 horas. Durante este tiempo, la creación de nuevas sesiones queda bloqueada.';

  @override
  String get apSessionEndBody =>
      'Esto bloquea el tiempo de bloque actual. Después puedes iniciar una nueva sesión.';

  @override
  String get apGeneratesProof =>
      'Genera una nueva prueba criptográfica para las próximas 6 horas.';

  @override
  String get humTitle => 'PROOF OF HUMANITY';

  @override
  String get humVerified => 'HUMANO VERIFICADO';

  @override
  String get humNotVerified => 'NO VERIFICADO';

  @override
  String get humVerifiedSub => 'Estás verificado como humano';

  @override
  String get humLightningActive => 'Prueba Lightning activa';

  @override
  String get humCheckNow => 'VERIFICAR AHORA';

  @override
  String get humCheckAgain => 'VERIFICAR DE NUEVO';

  @override
  String get humCheckAgainShort => 'Verificar de nuevo';

  @override
  String get humSearchingRelays => 'BUSCANDO EN RELAYS...';

  @override
  String get humHowTitle => '¿CÓMO FUNCIONA?';

  @override
  String get humIntro1 => 'Demuestra que eres humano — mostrando ';

  @override
  String get humIntro2 => 'que posees una cartera Lightning real y ';

  @override
  String get humIntro3 => 'ya has hecho un zap a alguien en Nostr.';

  @override
  String get humExplain1 => 'Los bots no tienen carteras Lightning. Un único ';

  @override
  String get humExplain2 => 'pago real demuestra que eres un humano con una ';

  @override
  String get humExplain3 => 'cartera real — sin revelar datos personales.';

  @override
  String get humStep1 => 'Haces un zap a cualquiera en Nostr';

  @override
  String get humStep2 => 'El zap crea un recibo en los relays';

  @override
  String get humStep3 => 'La app encuentra tu recibo';

  @override
  String get humStepInstruction =>
      'A cualquiera, cualquier cantidad de sats. Usa un cliente Nostr como Damus, Amethyst o Primal.';

  @override
  String get humCheckInstruction =>
      'Pulsa el botón de verificar y la app busca tu zap en los relays Nostr.';

  @override
  String get humZapReturn => 'Haz un zap a cualquiera y vuelve';

  @override
  String get humCryptoProof =>
      'Esta es una prueba criptográfica de que has hecho un pago Lightning real.';

  @override
  String get humProofInEvent1 => 'en la red Nostr. Esta prueba está en tu ';

  @override
  String get humProofPrivacy =>
      'La prueba se incluye en tu evento de reputación. No se guarda importe ni destinatario.';

  @override
  String get humReputationSaved => 'Evento de reputación guardado.';

  @override
  String humPaidOn(String date) {
    return 'Hiciste un pago Lightning el $date ';
  }

  @override
  String humLastCheck(String time) {
    return 'Última verificación: $time';
  }

  @override
  String get ppTitle => 'VINCULACIÓN DE PLATAFORMA';

  @override
  String get ppPlatform => 'PLATAFORMA';

  @override
  String get ppUsername => 'NOMBRE DE USUARIO';

  @override
  String get ppActiveLinks => 'VÍNCULOS ACTIVOS';

  @override
  String get ppLinkPlatform => 'VINCULAR PLATAFORMA';

  @override
  String get ppCreateLink => 'CREAR VÍNCULO';

  @override
  String get ppAnotherPlatform => 'OTRA PLATAFORMA';

  @override
  String get ppShareOnPlatform => 'COMPARTIR EN PLATAFORMA';

  @override
  String get ppUnlinkQ => '¿DESVINCULAR?';

  @override
  String get ppRevoke => 'REVOCAR';

  @override
  String get ppCancel => 'CANCELAR';

  @override
  String get ppYourUsername => 'Tu nombre de usuario';

  @override
  String get ppPlatformName => 'Nombre de la plataforma';

  @override
  String get ppIntro =>
      'Vincula tu cuenta con una plataforma. La prueba se incrusta automáticamente en tu QR de reputación.';

  @override
  String get ppLinkSaved =>
      '¡Vínculo guardado! Se incrusta automáticamente en tu QR de reputación.';

  @override
  String get ppMustUpdate =>
      'Debes actualizar tu evento de reputación después.';

  @override
  String get ppUnlinkBody1 => 'El vínculo de plataforma para \"';

  @override
  String get ppUnlinkBody2 => 'se eliminará.\n\n';

  @override
  String ppUnlinkBody(String username, String platform) {
    return 'El vínculo de plataforma para \"$username\" en $platform se eliminará.\n\nDebes actualizar tu evento de reputación después.';
  }

  @override
  String ppCreated(String date) {
    return 'Creado: $date';
  }

  @override
  String get ppRevokeTooltip => 'Revocar';

  @override
  String get rqTitle => 'CÓDIGO QR MEETUP';

  @override
  String get rqActive => 'ACTIVO';

  @override
  String get rqCodeRenewing => 'El código se renueva...';

  @override
  String get rqNextCodeIn => 'Próximo código en';

  @override
  String get rqEndSession => 'Finalizar sesión';

  @override
  String get rqEndSessionQ => '¿Finalizar sesión?';

  @override
  String get rqEnd => 'FINALIZAR';

  @override
  String get rqEndSessionBody =>
      'Una sesión finalizada bloquea este tiempo de bloque. Después puedes iniciar una nueva sesión.';

  @override
  String get rqNoActiveSession => 'SIN SESIÓN ACTIVA';

  @override
  String get rqNoSessionBody =>
      'No hay ninguna sesión de meetup activa.\nReinicia el meetup en el Panel de Admin.';

  @override
  String get rqBackToAdmin => 'VOLVER AL PANEL DE ADMIN';

  @override
  String get rsTitle => 'RELAYS NOSTR';

  @override
  String get rsDefaultRelays => 'RELAYS POR DEFECTO';

  @override
  String get rsCustomRelays => 'RELAYS PROPIOS';

  @override
  String get rsAddRelay => 'AÑADIR RELAY';

  @override
  String get rsAdd => 'AÑADIR';

  @override
  String get rsNoRelaysActive => '¡Sin relays activos!';

  @override
  String get rsNoCustomRelays => 'Sin relays propios configurados.';

  @override
  String get rsAllRelaysInfo =>
      'La app usa todos los relays activos a la vez para máxima cobertura.';

  @override
  String get rsRelaysIntro =>
      'Los relays distribuyen tu reputación en la red Nostr. ';

  @override
  String get rsRelayPlaceholder => 'wss://mi-relay.es';

  @override
  String get rdScanAdminTag => 'ESCANEAR ETIQUETA ADMIN';

  @override
  String get rdAnon => 'ANON';

  @override
  String get rdCollectBadge => 'RECOGER INSIGNIA';

  @override
  String get rdYourReputation => 'TU REPUTACIÓN';

  @override
  String get rdEditIdentity => 'Editar identidad';

  @override
  String get rdLinkingIdentity => 'Vinculando identidad...';

  @override
  String get rdNostrVerified => 'NOSTR VERIFIED';

  @override
  String get rdNoBadges => 'Aún sin insignias.\n¡Ve a un meetup!';

  @override
  String get rdSelfSovereign =>
      'Soberanía propia: Esta app funciona sin servidor. Tus insignias son solo tuyas y se guardan en este dispositivo.';

  @override
  String get rdVerifiedByAdmin => 'VERIFICADO POR ADMIN';

  @override
  String rqRemainingTime(String time) {
    return 'Tiempo restante: $time\n\n';
  }

  @override
  String rqSessionRemaining(String time) {
    return 'Sesión: $time';
  }

  @override
  String get rvTitle => 'VERIFICAR REPUTACIÓN';

  @override
  String get rvChecking => 'VERIFICANDO...';

  @override
  String get rvFullyVerified => 'TOTALMENTE VERIFICADO';

  @override
  String get rvPartiallyVerified => 'PARCIALMENTE VERIFICADO';

  @override
  String get rvSignatureOnly => 'SOLO FIRMA VERIFICADA';

  @override
  String get rvInvalid => 'NO VÁLIDO';

  @override
  String get rvConfirmedInEvent => 'Confirmado en el evento';

  @override
  String get rvPlatformProof => 'Prueba de plataforma';

  @override
  String get rvIntro1 =>
      'Pega la cadena de verificación o npub de una persona ';

  @override
  String get rvIntro2 =>
      'para verificar su reputación en todas las capas de prueba.';

  @override
  String get rvCheckingSignature => 'Verificando firma...';

  @override
  String get rvCheckingNostr => 'Analizando red Nostr...';

  @override
  String get rvCheckingLightning => 'Verificando actividad Lightning...';

  @override
  String get rvCheckingNip05 => 'Verificando NIP-05...';

  @override
  String get msSelectMeetup => 'SELECCIONAR MEETUP';

  @override
  String get msSearchMeetup => 'Buscar meetup...';

  @override
  String get mlTitle => 'MEETUPS';

  @override
  String get mlRetry => 'Reintentar';

  @override
  String get mlLoadError => 'Error al cargar';

  @override
  String get mlNoMeetupsFound => 'No se encontraron meetups.';

  @override
  String mlNoMeetupFor(String query) {
    return 'Sin meetup para \"$query\"';
  }

  @override
  String get cmRequestSent => 'SOLICITUD ENVIADA 🚀';

  @override
  String get cmDateTime => 'FECHA Y HORA';

  @override
  String get cmFoundBase => 'FUNDA UNA BASE.';

  @override
  String get cmLocation => 'UBICACIÓN / LUGAR';

  @override
  String get cmCityName => 'NOMBRE DE LA CIUDAD';

  @override
  String get cmTelegramGroup => 'GRUPO DE TELEGRAM (OPCIONAL)';

  @override
  String get cmNewMeetup => 'NUEVO MEETUP';

  @override
  String get cmDateExample => 'p. ej. 21 de mayo, 19:00';

  @override
  String get cmCityExample => 'p. ej. Fráncfort';

  @override
  String get cmLocationExample => 'p. ej. Room 77';

  @override
  String get evUpcomingEvents => 'PRÓXIMOS EVENTOS';

  @override
  String get evDatesEvents => 'FECHAS Y EVENTOS';

  @override
  String get evNoMeetupsFound => 'No se encontraron meetups';

  @override
  String get evSearchCityCountry => 'Buscar ciudad o país...';

  @override
  String get evIntro =>
      'La mayoría de los meetups de Einundzwanzig son periódicos. Toca un meetup para más info y fechas.';

  @override
  String get rvLabelPlatform => 'Plataforma';

  @override
  String get rvLabelUsername => 'Usuario';

  @override
  String get countryDE => 'Alemania';

  @override
  String get countryAT => 'Austria';

  @override
  String get countryCH => 'Suiza';

  @override
  String get countryES => 'España';

  @override
  String get countryNL => 'Países Bajos';

  @override
  String get countryIT => 'Italia';

  @override
  String get countryFR => 'Francia';
}
