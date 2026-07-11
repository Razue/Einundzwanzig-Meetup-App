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

  @override
  String get siTitle => 'TU TRUST SCORE';

  @override
  String get siIntro =>
      'Mide tu fiabilidad. Se basa en pruebas criptográficas — nadie puede falsificarlo.';

  @override
  String get siIdentityLayer => 'CAPA DE IDENTIDAD';

  @override
  String siLinksActive(Object count) {
    return '$count vínculos activos';
  }

  @override
  String get siHumanitySub => 'Verificación con zap Lightning';

  @override
  String get siNip05Sub => 'Identidad Nostr (name@domain)';

  @override
  String get siPlatformActive => 'Plataforma activa';

  @override
  String get siPlatforms => 'Plataformas';

  @override
  String get siNoneLinked => 'Aún ninguna vinculada';

  @override
  String get siTrustLevel => 'NIVEL DE CONFIANZA';

  @override
  String get siLvlNew =>
      'Nivel inicial. Visita meetups para recoger insignias.';

  @override
  String get siLvlStarter =>
      'Tus primeras insignias muestran participación en la comunidad.';

  @override
  String get siLvlActive =>
      'Activo con regularidad. Diferentes meetups y organizadores refuerzan tu perfil.';

  @override
  String get siLvlEstablished =>
      'Miembro de confianza. Bien conectado y veterano.';

  @override
  String get siLvlVeteran =>
      'Nivel máximo. Reputación demostrada durante meses.';

  @override
  String get siCalculation => 'CÁLCULO';

  @override
  String get siFacBadges => 'Insignias de meetup';

  @override
  String get siFacBadgesDesc =>
      'Valor base por insignia. Los meetups concurridos valen más.';

  @override
  String get siFacDiversity => 'Diversidad';

  @override
  String get siFacDiversityDesc =>
      'Diferentes ciudades/organizadores = más puntos.';

  @override
  String get siFacSigners => 'Firmantes';

  @override
  String get siFacSignersDesc =>
      'Organizadores independientes = mayor confianza.';

  @override
  String get siFacMaturity => 'Madurez';

  @override
  String get siFacMaturityDesc =>
      'Antigüedad de la cuenta + regularidad = bonus.';

  @override
  String get siFacFrequency => 'Límite de frecuencia';

  @override
  String get siFacFrequencyDesc => 'Máx. 2 insignias/semana. Anti-farming.';

  @override
  String get siBecomeOrganizer => 'HACERTE ORGANIZADOR';

  @override
  String get siBecomeOrgDesc =>
      'Promoción automática al alcanzar suficiente Trust Score. Luego puedes crear tus propias etiquetas NFC y códigos QR.';

  @override
  String siProgressLabel(Object name) {
    return 'PROGRESO ($name)';
  }

  @override
  String get siAlreadyOrganizer => '¡Ya eres organizador!';

  @override
  String get siIncreaseScore => 'AUMENTAR SCORE';

  @override
  String get siTip1 => 'Visita diferentes meetups con regularidad';

  @override
  String get siTip2 => 'Recoge insignias en meetups de otras ciudades';

  @override
  String get siTip3 => 'Insignias de diferentes organizadores';

  @override
  String get siTip4 => 'Verifica tu identidad con un zap Lightning';

  @override
  String get siTip5 => 'Configura NIP-05';

  @override
  String get siTip6 => 'Vincula plataformas';

  @override
  String siProgressRow(Object label, Object current, Object required) {
    return '$label: $current/$required';
  }

  @override
  String get wotTabNetwork => 'RED';

  @override
  String get wotTabReports => 'DENUNCIAS';

  @override
  String get wotHealthGood => 'SALUDABLE';

  @override
  String get wotHealthBuilding => 'EN DESARROLLO';

  @override
  String get wotHealthCritical => 'CRÍTICO';

  @override
  String get badgeUnknown => 'desconocido';

  @override
  String get badgeBlockAtScan => '₿ Altura de bloque al escanear';

  @override
  String get mwStartMeetup => 'INICIAR MEETUP';

  @override
  String get mwStep1Nfc => 'PASO 1: ETIQUETA NFC';

  @override
  String get mwNfcIntro1 =>
      '¿Quieres colocar etiquetas NFC físicas (NTAG215) para este meetup? ';

  @override
  String get mwNfcIntro2 =>
      'La prueba criptográfica (tiempo de bloque y firma) queda fijada en ellas.';

  @override
  String get mwWriteNfcTag => 'ESCRIBIR ETIQUETA NFC';

  @override
  String get mwSkipQrOnly => 'OMITIR — SOLO USAR QR';

  @override
  String repAllBound(Object total) {
    return 'Las $total insignias vinculadas y verificadas';
  }

  @override
  String repBoundOf(Object total, Object bound) {
    return '$bound de $total insignias vinculadas a identidad';
  }

  @override
  String repBoundExtra(Object verified) {
    return ' ($verified verificadas criptográficamente)';
  }

  @override
  String repAllVerified(Object total) {
    return 'Las $total insignias verificadas criptográficamente (aún no vinculadas)';
  }

  @override
  String repVerifiedSchnorr(Object total, Object verified) {
    return '$verified de $total insignias con prueba Schnorr';
  }

  @override
  String repPlatformLinksActive(Object count) {
    return '$count vínculos de plataforma activos';
  }

  @override
  String homeCouldNotOpen(Object url) {
    return 'No se pudo abrir $url';
  }

  @override
  String admWotLive(Object count) {
    return '✅ ¡Tu Web of Trust está activo ($count relays)!';
  }

  @override
  String get admDelegationSigned =>
      '✅ ¡Tu delegación fue firmada criptográficamente y publicada en la red!';

  @override
  String admWotCurrent(Object count) {
    return '✅ Web of Trust actualizado ($count admins verificados)';
  }

  @override
  String get admNoVouchesFound =>
      '✅ No se encontraron avales publicados en los relays';

  @override
  String admVouchesRestored(Object count) {
    return '✅ $count avales restaurados';
  }

  @override
  String get admNoRelayReachable =>
      '⚠️ Ningún relay accesible — inténtalo más tarde';

  @override
  String get admAllVouchesRevoked =>
      '✅ Todos los avales han sido revocados en la red';

  @override
  String get apHowStep3 =>
      '3. Cada escaneo = una insignia para el participante\n';

  @override
  String get badgeSchnorrSig => 'Schnorr (Nostr v2) ✓';

  @override
  String msHomeMeetupSet(Object city) {
    return '✅ $city establecido como meetup principal';
  }

  @override
  String mvKnownOrganizer(Object name) {
    return '✓ Organizador conocido: $name';
  }

  @override
  String get mvUnknownSigner =>
      '✗ ¡FIRMANTE DESCONOCIDO!\nEsta pubkey no está en el registro de admins.';

  @override
  String get mvAdminCheckFailed =>
      '! No se pudo verificar el estado de admin (¿sin conexión?)';

  @override
  String get mvLegacyBadge =>
      '! Insignia antigua (v1) — firmante no verificable';

  @override
  String get mvBadgeBound => '🔗 Insignia vinculada';

  @override
  String get nwSelectHomeMeetup =>
      '❌ ¡Primero selecciona un meetup principal en tu perfil!';

  @override
  String qrUniqueRecipients(Object count) {
    return '$count destinatarios diferentes';
  }

  @override
  String get apHowStep1 => '1. Inicia un nuevo meetup (sesión).\n';

  @override
  String get apHowStep2 =>
      '2. Luego escribe etiquetas NFC o muestra el código QR.\n';

  @override
  String get apHowStep4 =>
      '4. Las insignias construyen reputación → más reputación = nuevos organizadores';

  @override
  String get ppHowStep1 =>
      '1. Elige una plataforma e introduce tu nombre de usuario\n';

  @override
  String get ppHowStep2 => '2. La app crea una prueba criptográfica\n';

  @override
  String get ppHowStep3 =>
      '3. La prueba se incrusta automáticamente en tu QR de reputación\n';

  @override
  String get ppHowStep4 =>
      '4. Otros escanean tu QR y ven el vínculo verificado';

  @override
  String admErrorEmoji(Object msg) {
    return '❌ Error: $msg';
  }

  @override
  String get admNoNewUpdates => '⚠️ No se encontraron actualizaciones';

  @override
  String homeImageLoadError(Object msg) {
    return 'No se pudo cargar la imagen: $msg';
  }

  @override
  String qrSentCount(Object count) {
    return '$count enviados';
  }

  @override
  String repShareError(Object msg) {
    return 'Error al compartir: $msg';
  }

  @override
  String get rqNoHomeMeetup => '⚠️ Sin meetup principal definido';

  @override
  String get rqMeetupNotFound => '⚠️ Meetup no encontrado';

  @override
  String get rlWhatMeans => '¿Qué significa esto?';

  @override
  String get rlWhyImportant => 'Por qué es importante';

  @override
  String get rlWeakLabel => 'Perfil débil';

  @override
  String get rlWeakExpl =>
      'Solo una capa de prueba activa. Este usuario tiene pocas conexiones verificables. Para transacciones grandes: precaución.';

  @override
  String get rlWeakAdvice =>
      'Pide más pruebas (Lightning, NIP-05) o reúnete con la persona primero.';

  @override
  String get rlLimitedLabel => 'Limitado';

  @override
  String get rlLimitedExpl =>
      'Hay insignias de meetup, pero no otras pruebas independientes. El usuario podría ser real — pero falta confirmación de otras capas.';

  @override
  String get rlLimitedAdvice =>
      'OK para importes mínimos. Para importes mayores: espera a que haya más capas activas.';

  @override
  String get rlBuildingLabel => 'En desarrollo';

  @override
  String get rlBuildingExpl =>
      'Dos capas de prueba activas. El usuario está construyendo reputación pero aún sin amplitud completa.';

  @override
  String get rlBuildingAdvice => 'Adecuado para transacciones moderadas.';

  @override
  String get rlConnectedLabel => 'Bien conectado';

  @override
  String get rlConnectedExpl =>
      'Múltiples pruebas independientes: meetups, actividad Lightning y conexiones sociales. Difícil de falsificar.';

  @override
  String get rlConnectedAdvice => 'Fiable para la mayoría de transacciones.';

  @override
  String get rlSolidLabel => 'Sólido';

  @override
  String get rlSolidExpl =>
      'Amplia base de pruebas. Manipularlo sería laborioso y costoso.';

  @override
  String get rlSolidAdvice => 'Fiable para la mayoría de los casos.';

  @override
  String get rlDefaultExpl =>
      'Algunas pruebas presentes, pero hay margen para más.';

  @override
  String get rlDefaultAdvice => 'Usa tu propio criterio.';

  @override
  String get rlMeetupProofs => 'Pruebas de meetup';

  @override
  String get rlMeetupGood =>
      'Asistió a diferentes meetups con diferentes organizadores. Esto requiere presencia física en varios lugares.';

  @override
  String get rlMeetupMoreDiverse => 'Más diversidad sería más convincente.';

  @override
  String get rlMeetupNone =>
      'Sin insignias de meetup. Este usuario aún no ha asistido a un meetup de Einundzwanzig — o usa la app desde hace poco.';

  @override
  String get rlAllBound => 'Todas vinculadas criptográficamente';

  @override
  String get rlGoodSpread => 'Buena distribución regional';

  @override
  String get rlLowSpread => 'Poca distribución';

  @override
  String rlPhysGoodDiversity(Object count) {
    return 'Tiene insignias de meetup, pero solo de $count organizador(es). Más diversidad sería más convincente.';
  }

  @override
  String rlBadgeCount(Object count) {
    return '$count insignias';
  }

  @override
  String rlBoundOf(Object bound, Object total) {
    return '$bound de $total vinculadas';
  }

  @override
  String rlDiffMeetups(Object count) {
    return '$count meetups diferentes';
  }

  @override
  String rlOrganizers(Object count) {
    return '$count organizadores';
  }

  @override
  String get rlConfirmedByDiff => 'Confirmado por distintas personas';

  @override
  String get rlOneOrgOnly =>
      'Solo un organizador — poca confirmación independiente';

  @override
  String rlMemberSince(Object since) {
    return 'Miembro desde $since';
  }

  @override
  String rlDaysCount(Object count) {
    return '$count días';
  }

  @override
  String get rlLightningProof => 'Prueba Lightning';

  @override
  String get rlLnBoth =>
      'Ha realizado y recibido pagos Lightning reales. Los bots no tienen carteras Lightning — una fuerte señal de autenticidad.';

  @override
  String get rlLnPaid =>
      'Ha pagado vía Lightning al menos una vez. Prueba básica de que existe una cartera real.';

  @override
  String get rlLnActiveOnly =>
      'Hay actividad Lightning, pero Proof of Humanity aún no activo.';

  @override
  String get rlLnNone =>
      'Sin actividad Lightning. No significa que el usuario sea falso — quizás no usa Lightning vía Nostr. Pero falta una señal anti-bot importante.';

  @override
  String get rlHumanVerified => 'Humano verificado';

  @override
  String get rlRealLnPayment => 'Pago Lightning real demostrado';

  @override
  String rlZapsSent(Object count) {
    return '$count zaps enviados';
  }

  @override
  String rlToRecipients(Object count) {
    return 'A $count destinatarios diferentes';
  }

  @override
  String rlZapsReceived(Object count) {
    return '$count zaps recibidos';
  }

  @override
  String rlFromSenders(Object count) {
    return 'De $count remitentes diferentes';
  }

  @override
  String rlMonthsActive(Object count) {
    return '$count meses activo';
  }

  @override
  String get rlSocialTitle => 'Red social';

  @override
  String get rlSocMutualMany =>
      'Os conocéis en Nostr y compartís muchos contactos. Conexión fuerte.';

  @override
  String get rlSocMutual => 'Seguimiento mutuo — os conocéis en Nostr.';

  @override
  String get rlSocCommon =>
      'Muchos contactos en común — os movéis en la misma red.';

  @override
  String get rlSocOneSided => 'Conexión unilateral. Os conocéis de pasada.';

  @override
  String get rlSocOrgFollow =>
      'Organizadores conocidos de Einundzwanzig siguen a este usuario. Es una señal positiva.';

  @override
  String get rlSocDefault => 'Hay conexiones en la red Nostr con este usuario.';

  @override
  String get rlSocNone =>
      'No se encontró conexión en la red Nostr. Puede significar: nunca os habéis encontrado en Nostr, o el usuario es muy nuevo. Normal con desconocidos — señal de alerta con caras supuestamente conocidas.';

  @override
  String get rlMutualFollow => 'Seguimiento mutuo';

  @override
  String get rlYouFollow => 'Tú sigues';

  @override
  String get rlFollowsYou => 'Te sigue';

  @override
  String get rlNoFollow => 'Sin seguimiento';

  @override
  String get rlKnowOnNostr => 'Os conocéis en Nostr';

  @override
  String get rlNoDirectConn => 'Sin conexión directa';

  @override
  String rlCommonContacts(Object count) {
    return '$count contactos en común';
  }

  @override
  String get rlSameNetwork => 'Misma red';

  @override
  String get rlSomeOverlap => 'Algunas coincidencias';

  @override
  String get rlSeparateNetworks => 'Redes separadas';

  @override
  String rlOrgsFollow(Object count) {
    return '$count organizadores siguen';
  }

  @override
  String get rlEndorsement => 'Respaldo de admins conocidos';

  @override
  String get rlIdentityTitle => 'Prueba de identidad';

  @override
  String get rlIdNip05Plat =>
      'Tiene una dirección NIP-05 y plataformas vinculadas. Esto liga la identidad Nostr a un dominio — más difícil de falsificar que una cuenta anónima.';

  @override
  String get rlIdNip05Only =>
      'Tiene una dirección NIP-05. Esto liga la identidad Nostr a un dominio — más difícil de falsificar que una cuenta anónima.';

  @override
  String get rlIdPlatOnly =>
      'Cuentas de plataforma vinculadas. Más plataformas = más esfuerzo para falsificadores.';

  @override
  String get rlIdNone =>
      'Sin identificación de internet. Completamente anónimo. Bien para la privacidad, pero da menos indicios de confianza.';

  @override
  String get rlLinked => 'Vinculado';

  @override
  String get rlNoIdentification => 'Sin identificación';

  @override
  String get rlAnonymous => 'Anónimo';

  @override
  String get rlActive => '✓ activo';

  @override
  String get rlActiveShort => '✓ activo';

  @override
  String get rlMissingShort => '— falta';

  @override
  String qrReceivedCount(Object count) {
    return '$count recibidos';
  }

  @override
  String qrUniqueSenders(Object count) {
    return '$count remitentes diferentes';
  }

  @override
  String rlProofsOfFour(Object count) {
    return '$count / 4 pruebas';
  }

  @override
  String get navNearby => 'Cerca';

  @override
  String get nbTitle => 'MEETUPS CERCA';

  @override
  String get nbRequestingLocation => 'Obteniendo ubicación...';

  @override
  String get nbLoading => 'Cargando meetups...';

  @override
  String get nbLocationDenied => 'Acceso a ubicación denegado';

  @override
  String get nbLocationDeniedSub =>
      'Sin ubicación mostramos todos los meetups por fecha. Activa la ubicación en ajustes para ver distancias.';

  @override
  String get nbServiceDisabled =>
      'Los servicios de ubicación están desactivados';

  @override
  String get nbRetryLocation => 'Reintentar ubicación';

  @override
  String get nbContinueWithout => 'Continuar sin ubicación';

  @override
  String get nbNoMeetups => 'No hay meetups para este periodo';

  @override
  String get nbNoMeetupsSub => 'Prueba otro filtro u otra fecha.';

  @override
  String get nbFilterToday => 'Hoy';

  @override
  String get nbFilterWeek => 'Esta semana';

  @override
  String get nbFilterUpcoming => 'Próximos';

  @override
  String get nbFilterAll => 'Todos';

  @override
  String get nbPickDate => 'Elegir fecha';

  @override
  String nbKmAway(Object km) {
    return 'a $km km';
  }

  @override
  String get nbNoDate => 'Sin fecha anunciada';

  @override
  String nbListHeader(Object count) {
    return '$count meetups';
  }

  @override
  String get nbOpenInMaps => 'Abrir en mapas';

  @override
  String get nbYourLocation => 'Tu ubicación';

  @override
  String get nbToday => 'Hoy';

  @override
  String get nbTomorrow => 'Mañana';

  @override
  String get nbResetDate => 'Restablecer filtro';

  @override
  String get nbModeHere => 'Aquí y ahora';

  @override
  String get nbModePlanned => 'Planificado';

  @override
  String get nbRadius => 'Radio';

  @override
  String nbRadiusValue(Object km) {
    return '$km km';
  }

  @override
  String get nbSearchPlace => 'Buscar lugar (p. ej. Hamburgo)';

  @override
  String get nbSearchingPlace => 'Buscando lugares...';

  @override
  String get nbNoPlaceFound => 'Lugar no encontrado';

  @override
  String get nbCenterHere => 'Mi ubicación';

  @override
  String get nbChangePlace => 'Cambiar lugar';

  @override
  String get nbDateAny => 'Cualquier fecha';

  @override
  String get nbDateSingle => 'Fecha';

  @override
  String get nbDateRange => 'Periodo';

  @override
  String get nbPickDay => 'Elegir día';

  @override
  String get nbPickRange => 'Elegir periodo';

  @override
  String nbDateFromTo(Object from, Object to) {
    return '$from – $to';
  }

  @override
  String nbResultsHeader(Object count) {
    return '$count meetups en el radio';
  }

  @override
  String get nbNoneInRadius => 'Sin meetups en el radio';

  @override
  String get nbNoneInRadiusSub => 'Amplía el radio o cambia lugar/fecha.';

  @override
  String get nbApplySearch => 'Buscar';

  @override
  String nbMoreDates(Object count) {
    return '+$count fechas más';
  }

  @override
  String get nbDirections => 'Ruta';

  @override
  String get nbDetails => 'Detalles';

  @override
  String get settingsSectionProfile => 'Perfil';

  @override
  String get settingsProfile => 'Editar perfil';

  @override
  String get settingsProfileSub => 'Nombre, clave Nostr y meetup principal';

  @override
  String get apCreateEvent => 'Crear evento';

  @override
  String get apCreateEventSub => 'Crear en el portal';

  @override
  String get apCreateEventTitle => 'Crear evento en el portal';

  @override
  String get apCreateEventBody =>
      'Los eventos de meetup se gestionan de forma centralizada en el portal Einundzwanzig. La app abrirá ahora el portal en tu navegador — inicia sesión con tu clave Nostr y crea el evento. Después aparecerá aquí en el calendario automáticamente.';

  @override
  String get apOpenPortal => 'Abrir portal';

  @override
  String get apNoHomeMeetupSet =>
      'Selecciona primero tu meetup principal en el perfil, luego podrás crear eventos.';

  @override
  String get apPortalHint =>
      '¿Por qué no directamente en la app? El portal es la fuente central de todos los eventos y requiere tu inicio de sesión. La creación directa desde la app está prevista en cuanto el portal lo permita.';

  @override
  String get rcTitle => 'Perfil de reputación';

  @override
  String get rcShareImage => 'Compartir como imagen';

  @override
  String get rcSaving => 'Creando imagen...';

  @override
  String rcShareError(Object error) {
    return 'Error al compartir: $error';
  }

  @override
  String get rcShareText => 'Mi Trust Score y reputación de Einundzwanzig';

  @override
  String get rcLabelScore => 'Trust Score';

  @override
  String get rcLabelLevel => 'Nivel';

  @override
  String get rcLabelBadges => 'Badges';

  @override
  String get rcLabelMeetups => 'Meetups';

  @override
  String get rcLabelCities => 'Ciudades';

  @override
  String get rcLabelSigners => 'Avales';

  @override
  String get rcLabelAge => 'Días activo';

  @override
  String get rcMember => 'Miembro de Einundzwanzig';

  @override
  String get rcNoData =>
      'Aún no hay reputación. ¡Consigue badges en los meetups!';

  @override
  String get tpTitle => 'Ruta de confianza';

  @override
  String get tpSubtitle => '¿Quién te conecta con esta persona?';

  @override
  String get tpEnterNpub => 'Introduce el npub de la persona';

  @override
  String get tpScan => 'Escanear npub';

  @override
  String get tpFind => 'Buscar ruta';

  @override
  String get tpSearching => 'Buscando en la red...';

  @override
  String tpFound(Object count) {
    return 'Conectado a través de $count pasos';
  }

  @override
  String get tpDirect => 'Conectado directamente';

  @override
  String get tpYou => 'Tú';

  @override
  String get tpTarget => 'Destino';

  @override
  String get tpVouchesFor => 'avala a';

  @override
  String get tpNoPath => 'No se encontró ruta de confianza';

  @override
  String get tpNoPathSelf =>
      'Aún no estás en la red de avales. Consigue avales de admins para ver rutas.';

  @override
  String get tpNoPathTarget =>
      'Esta persona no está (aún) en la red de avales.';

  @override
  String get tpNoPathBetween =>
      'Actualmente no hay cadena de avales conocida entre vosotros.';

  @override
  String get tpInvalidNpub => 'npub no válido';

  @override
  String get tpUnknown => 'Desconocido';

  @override
  String get tpHint =>
      'Basado en la red pública de avales (Web of Trust). Solo muestra conexiones a través de miembros que avalan.';

  @override
  String get caOptInTitle => '¿Contribuir a la red de confianza?';

  @override
  String get caOptInBody =>
      'Puedes confirmar tu asistencia a este meetup en la red pública de confianza. Otros verán que tu npub estuvo en este meetup — y cómo estáis conectados por meetups en común.\n\nEs voluntario. Recibes tu badge igualmente.';

  @override
  String get caOptInPrivacy =>
      'Público y permanente en relays Nostr. Revela un patrón de movimiento y contactos. Piénsalo bien.';

  @override
  String get caOptInYes => 'Sí, contribuir';

  @override
  String get caOptInNo => 'No, mantener privado';

  @override
  String get caPublished => 'Asistencia confirmada en la red';

  @override
  String get cnTitle => 'Análisis de red';

  @override
  String get cnSubtitle =>
      '¿Cómo está conectada esta persona por meetups en común?';

  @override
  String get cnEnterNpub => 'Introduce el npub de la persona';

  @override
  String get cnScan => 'Escanear';

  @override
  String get cnAnalyze => 'Analizar';

  @override
  String get cnLoading => 'Cargando red...';

  @override
  String get cnSharedMeetups => 'Meetups en común';

  @override
  String get cnMutualContacts => 'Contactos en común';

  @override
  String get cnReach => 'Alcance de la persona';

  @override
  String get cnTotalMeetups => 'Meetups asistidos';

  @override
  String get cnTotalContacts => 'Personas conocidas';

  @override
  String get cnNoConnection => 'No se encontró conexión';

  @override
  String get cnNoConnectionSub =>
      'No habéis estado en meetups comunes ni tenéis contactos en común — o esta persona no participa en la red.';

  @override
  String get cnDirectMet => '¡Os habéis conocido directamente!';

  @override
  String get cnYou => 'Tú';

  @override
  String get cnTarget => 'Esta persona';

  @override
  String cnViaShared(Object count) {
    return 'por $count meetups en común';
  }

  @override
  String get cnTrustHint =>
      'Más meetups y contactos en común significan más confianza orgánica.';

  @override
  String get cnInvalidNpub => 'npub no válido';

  @override
  String get cnPrivacyNote =>
      'Solo muestra personas que participan en la red (opt-in).';

  @override
  String get tileTrustNetwork => 'Red de confianza';

  @override
  String get tileTrustNetworkSub => 'Comprobar conexiones';

  @override
  String get tnHubTitle => 'Red de confianza';

  @override
  String get tnHubIntro =>
      'Comprueba la confiabilidad de una persona en la red Einundzwanzig — mediante avales y meetups en común.';

  @override
  String get tnHubPathTitle => 'Ruta de confianza';

  @override
  String get tnHubPathSub =>
      '¿Quién te conecta con una persona? (cadena de avales)';

  @override
  String get tnHubNetTitle => 'Análisis de red';

  @override
  String get tnHubNetSub => 'Meetups y contactos en común de una persona';

  @override
  String get orgBadgeCreated => 'Asistencia de organizador registrada';

  @override
  String get orgBadgeLabel => 'Organizador';

  @override
  String get orgBadgeSub => 'Organizaste este meetup';

  @override
  String get mnTitle => 'Mi red';

  @override
  String get mnIntro =>
      'Tu red de confianza de encuentros reales en meetups — y quién está conectado contigo más allá.';

  @override
  String get mnLoading => 'Construyendo red...';

  @override
  String get mnEmpty => 'Aún sin conexiones';

  @override
  String get mnEmptySub =>
      'Asiste a meetups y colecciona badges (con participación en la red) para construir tu red de confianza.';

  @override
  String get mnDegree1 => 'Conocidos directamente';

  @override
  String get mnDegree1Sub => 'Personas que conociste en vivo en meetups';

  @override
  String get mnDegree2 => 'Conectados por contactos';

  @override
  String get mnDegree2Sub => 'Personas que tus contactos conocieron en meetups';

  @override
  String get mnDegree3 => 'Red extendida';

  @override
  String get mnDegree3Sub => 'Un nivel más en la red';

  @override
  String mnSharedMeetups(Object count) {
    return '$count meetups en común';
  }

  @override
  String get mnOneSharedMeetup => '1 meetup en común';

  @override
  String mnViaContacts(Object count) {
    return 'por $count contactos';
  }

  @override
  String get mnViaOneContact => 'por 1 contacto';

  @override
  String get mnReachLabel => 'Alcance';

  @override
  String get mnDirectLabel => 'Directo';

  @override
  String get mnIndirectLabel => 'Indirecto';

  @override
  String get mnTrustHint =>
      'Los contactos indirectos a través de encuentros reales aumentan gradualmente tu confianza, incluso sin haber conocido a la persona.';

  @override
  String get mnPrivacyNote =>
      'Solo muestra personas que participan en la red (opt-in al escanear badge).';

  @override
  String get mnCheckPerson => 'Comprobar persona concreta';

  @override
  String get settingsHeaderTitle => 'Ajustes';

  @override
  String get settingsHeaderSub => 'Gestionar app y cuenta';

  @override
  String get settingsSecAccount => 'CUENTA';

  @override
  String get settingsSecData => 'DATOS Y SEGURIDAD';

  @override
  String get settingsSecNetwork => 'RED';

  @override
  String get settingsSecApp => 'APP';

  @override
  String get settingsSecDanger => 'ZONA DE PELIGRO';

  @override
  String get vpTitle => 'Verificar persona';

  @override
  String get vpIntro =>
      'Comprueba mediante encuentros reales en meetups si esta persona está conectada contigo.';

  @override
  String get vpEnterNpub => 'Introduce npub o escanea QR de reputación';

  @override
  String get vpScanQr => 'Escanear QR';

  @override
  String get vpCheck => 'Verificar';

  @override
  String get vpChecking => 'Comprobando conexión...';

  @override
  String get vpDirectTitle => '¡Conocido directamente!';

  @override
  String vpDirectSub(Object count) {
    return 'Habéis estado en $count meetups juntos.';
  }

  @override
  String get vpDirectSubOne => 'Habéis estado en un meetup juntos.';

  @override
  String vpIndirectTitle(Object count) {
    return 'Conectado a través de $count pasos';
  }

  @override
  String get vpIndirectSub =>
      'Esta persona está conectada contigo mediante encuentros reales en meetups.';

  @override
  String get vpNoneTitle => 'No se encontró conexión';

  @override
  String get vpNoneSub =>
      'Actualmente no hay conexión de meetup conocida contigo.';

  @override
  String get vpNotInNetwork => 'Esta persona no está (aún) en la red.';

  @override
  String get vpPathTitle => 'Ruta de conexión';

  @override
  String get vpYou => 'Tú';

  @override
  String get vpTarget => 'Esta persona';

  @override
  String get vpMetAt => 'meetup en común';

  @override
  String get vpInvalidNpub => 'npub no válido';

  @override
  String get vpTrustNote =>
      'Cuanto más cercana la conexión (menor grado), mayor la confianza por presencia física.';

  @override
  String get vpSelfTitle => 'Eres tú mismo';

  @override
  String get gpsRequired => 'Ubicación requerida';

  @override
  String get gpsRequiredOrg =>
      'Crear un meetup requiere tu ubicación. Define el lugar del meetup.';

  @override
  String get gpsRequiredScan =>
      'Recoger este badge requiere tu ubicación — como prueba de que estás presente.';

  @override
  String get gpsDenied => 'Acceso a ubicación denegado. Permítelo en ajustes.';

  @override
  String get gpsDisabled =>
      'Los servicios de ubicación están desactivados. Actívalos.';

  @override
  String get gpsError => 'No se pudo determinar la ubicación.';

  @override
  String get gpsRetry => 'Reintentar';

  @override
  String get gpsPickMeetup => '¿Qué meetup?';

  @override
  String get gpsPickMeetupSub => 'Hay varios meetups cerca. Elige el correcto.';

  @override
  String gpsDistanceKm(Object km) {
    return 'a $km km';
  }

  @override
  String get gpsNoMeetupNearby =>
      'No se encontró ningún meetup conocido cerca.';

  @override
  String get gpsTooFar => 'Demasiado lejos';

  @override
  String gpsTooFarSub(Object km, Object max) {
    return 'Estás a $km km del lugar del meetup. Los badges solo se recogen in situ (máx $max km).';
  }

  @override
  String get mapTitle => 'Mi mapa mundial de badges';

  @override
  String get mapButton => 'Ver en el mapa';

  @override
  String get mapStatMeetups => 'Meetups';

  @override
  String get mapStatCities => 'Ciudades';

  @override
  String get mapStatCountries => 'Países';

  @override
  String mapShareText(Object count) {
    return '¡Aquí he estado! 🌍 $count meetups en mi mapa mundial de badges Einundzwanzig.';
  }

  @override
  String get mapShareButton => 'Compartir como imagen';

  @override
  String get mapEmpty => 'Aún sin badges con ubicación';

  @override
  String get mapEmptySub =>
      'Colecciona badges en meetups — aparecerán aquí en tu mapa mundial.';

  @override
  String get gpsNoMeetupTitle => 'Ningún meetup cerca';

  @override
  String get gpsNoMeetupBody =>
      'No hay ningún meetup conocido en un radio de 10 km. Aún puedes iniciar una sesión — dale un título a tu meetup. Tu ubicación actual se establece automáticamente como lugar en el mapa.';

  @override
  String get gpsMeetupNameLabel => 'Título del meetup';

  @override
  String get gpsMeetupNameHint => 'p. ej. Encuentro Bitcoin';

  @override
  String get gpsStartAnyway => 'Iniciar sesión';

  @override
  String get gpsNameRequired => 'Introduce un nombre.';

  @override
  String get mnNodeDetailTitle => 'Conexión';

  @override
  String get mnDegreeDirect => 'Conexión directa';

  @override
  String get mnDegreeSecond => '2.º grado';

  @override
  String get mnDegreeThird => '3.er grado';

  @override
  String get mnSharedMeetupsList => 'Meetups en común';

  @override
  String get mnViaBridges => 'Conectado a través de';

  @override
  String get mnNoSharedDetail => 'Sin meetups en común directos';

  @override
  String get mnOpenInNostr => 'Abrir en Nostr';

  @override
  String get mnTapHint => 'Toca un nodo para más detalles';

  @override
  String get mnLegendDirect => 'Directo (1.º)';

  @override
  String get mnLegendSecond => '2.º';

  @override
  String get mnLegendThird => '3.er';

  @override
  String get resetBackupTitle => '¿Respaldar datos?';

  @override
  String get resetBackupBody =>
      'Restablecer borra TODOS los datos de forma irreversible — tus badges, tu clave y tu perfil. Sin copia de seguridad, los badges NO se pueden recuperar (tampoco vía Nostr). ¿Crear una copia primero?';

  @override
  String get resetBackupCreate => 'Crear copia';

  @override
  String get resetBackupSkip => 'Restablecer sin copia';

  @override
  String get resetBackupDone => 'Copia creada. ¿Restablecer ahora?';

  @override
  String get resetNowConfirm => 'Restablecer ahora';

  @override
  String get verifyBadgeSaved => 'Badge guardado ✓';

  @override
  String get tileConverter => 'Calculadora';

  @override
  String get tileConverterSub => 'Tipo & sats';

  @override
  String get convTitle => 'Conversor';

  @override
  String get convYouPay => 'Importe';

  @override
  String convRateInfo(Object price, Object cur) {
    return '1 BTC = $price $cur';
  }

  @override
  String convUpdated(Object time) {
    return 'Actualizado: $time';
  }

  @override
  String get convRefresh => 'Actualizar tasa';

  @override
  String get convOffline => 'No se pudo cargar la tasa. ¿Estás en línea?';

  @override
  String get convLoading => 'Cargando tasa …';

  @override
  String get convSwap => 'Intercambiar';

  @override
  String get convSelectCurrency => 'Seleccionar moneda';

  @override
  String get convUnitSats => 'Satoshi';

  @override
  String get convUnitBtc => 'Bitcoin';

  @override
  String get convSource => 'Tasa de mempool.space';

  @override
  String get tileNews => 'Noticias';

  @override
  String get tileNewsSub => 'Leer artículos de Einundzwanzig';

  @override
  String get newsTitle => 'Noticias';

  @override
  String get newsEmpty => 'No se encontraron artículos.';

  @override
  String get newsLoading => 'Cargando artículos …';

  @override
  String get newsRefresh => 'Actualizar';

  @override
  String get newsSource => 'Artículos vía Nostr (NIP-23)';

  @override
  String get newsOpenWebsite => 'Abrir en el sitio web';

  @override
  String get keyEduTitle => 'Tu clave para Nostr';

  @override
  String get keyEduWhatNostrH => '¿Qué es Nostr?';

  @override
  String get keyEduWhatNostrB =>
      'Nostr es una red abierta y descentralizada, similar a internet, pero para la identidad social. No pertenece a nadie. No hay empresa, ni cuenta, ni contraseña en el sentido clásico. En lugar de registrarte con un proveedor, posees una clave criptográfica que te identifica en toda la red.';

  @override
  String get keyEduPairH => 'Tu par de claves';

  @override
  String get keyEduPairB =>
      'Estás a punto de recibir dos claves emparejadas. Funcionan como un buzón: la clave pública es la dirección que puedes dar a cualquiera; la clave privada es la única que abre el buzón.';

  @override
  String get keyEduNpubH => 'npub – tu clave pública';

  @override
  String get keyEduNpubB =>
      'El npub (empieza con «npub1…») es tu identidad pública. Puedes compartirlo libremente: así te encuentran, ven tus publicaciones y te siguen. Es como tu nombre de usuario, salvo que realmente te pertenece y nadie puede quitártelo.';

  @override
  String get keyEduNsecH => 'nsec – tu clave privada';

  @override
  String get keyEduNsecB =>
      'El nsec (empieza con «nsec1…») es tu secreto. Quien lo posea ERES tú: puede publicar en tu nombre, apropiarse de tu identidad y abusar de tu reputación. NUNCA lo compartas, no lo escribas donde no estés seguro y nunca guardes una foto en la nube. No hay «olvidé mi contraseña»: si pierdes el nsec, la identidad se pierde para siempre.';

  @override
  String get keyEduIdentityH => 'Una identidad, muchos usos';

  @override
  String get keyEduIdentityB =>
      'Este par de claves no es solo para esta app. Es tu identidad en toda la red Nostr: puedes usar la misma identidad en muchas otras apps de Nostr, para redes sociales, blogs, chats, pagos Lightning y más. En esta app, además, está vinculada a tu reputación, tus badges de meetups y tu red de confianza. Por eso es tan importante protegerla: si pierdes la clave, no pierdes solo un acceso, sino todo lo que has construido.';

  @override
  String get keyEduProtectH => 'Cómo proteger tu clave';

  @override
  String get keyEduProtect1 =>
      'Haz una copia del nsec de inmediato (p. ej. en un gestor de contraseñas).';

  @override
  String get keyEduProtect2 => 'Comparte solo el npub, nunca el nsec.';

  @override
  String get keyEduProtect3 => 'Crea una copia cifrada (posible en esta app).';

  @override
  String get keyEduProtect4 =>
      'Para más seguridad: usa una app firmante como Amber.';

  @override
  String get keyEduUnderstood => 'Entendido, crear clave';

  @override
  String get keyEduCancel => 'Cancelar';

  @override
  String get keyEduIntro =>
      'Antes de empezar: estás a punto de recibir tu propio par de claves. Tómate un momento; vale la pena entender lo que recibes.';

  @override
  String get tilePortal => 'Mis meetups';

  @override
  String get tilePortalSub => 'Gestionar eventos en el portal';

  @override
  String get portalTitle => 'Mis meetups';

  @override
  String get portalNotConnected => 'Conectar con el portal';

  @override
  String get portalConnectInfo =>
      'Inicia sesión en el portal Einundzwanzig con tu clave Nostr para gestionar tus eventos desde la app.';

  @override
  String get portalConnect => 'Iniciar sesión';

  @override
  String get portalConnecting => 'Iniciando sesión …';

  @override
  String get portalLogout => 'Cerrar sesión';

  @override
  String get portalLoginFailed => 'Error de inicio de sesión';

  @override
  String get portalLoadingMeetups => 'Cargando tus meetups …';

  @override
  String get portalNoMeetups => 'Aún no gestionas meetups en el portal.';

  @override
  String get portalLeader => 'Organizador';

  @override
  String get portalNewEvent => 'Crear evento';

  @override
  String get portalEventTitle => 'Nuevo evento';

  @override
  String get portalFieldStart => 'Fecha y hora';

  @override
  String get portalPickDate => 'Elegir fecha';

  @override
  String get portalPickTime => 'Elegir hora';

  @override
  String get portalFieldLocation => 'Ubicación';

  @override
  String get portalFieldLocationHint => 'p. ej. café del meetup (opcional)';

  @override
  String get portalFieldDescription => 'Descripción';

  @override
  String get portalFieldDescriptionHint => '¿De qué trata? (opcional)';

  @override
  String get portalFieldLink => 'Enlace';

  @override
  String get portalFieldLinkHint => 'https://… (opcional)';

  @override
  String get portalSave => 'Guardar evento';

  @override
  String get portalSaving => 'Guardando …';

  @override
  String get portalCreatedOk => 'Evento creado ✓';

  @override
  String get portalNeedStart => 'Elige fecha y hora.';

  @override
  String get portalSource => 'Conectado a portal.einundzwanzig.space';

  @override
  String get evCalendarButton => 'Calendario de eventos';

  @override
  String get evCalendarButtonSub => 'Todos los eventos de un vistazo';

  @override
  String get calTitle => 'Calendario de eventos';

  @override
  String get calViewMonth => 'Mes';

  @override
  String get calViewYear => 'Año';

  @override
  String get calViewList => 'Lista';

  @override
  String get calToday => 'Hoy';

  @override
  String get calNoEvents => 'No hay eventos este día.';

  @override
  String get calNoEventsRange => 'No hay eventos en este periodo.';

  @override
  String get calLoading => 'Cargando eventos …';

  @override
  String get calAddEvent => 'Añadir evento';

  @override
  String get calAllDay => 'Todo el día';

  @override
  String get calSource => 'Eventos vía Nostr (NIP-52)';

  @override
  String get calNewEventTitle => 'Añadir evento';

  @override
  String get calFieldTitle => 'Título';

  @override
  String get calFieldTitleHint => 'p. ej. BTC Praga, Zitadelle …';

  @override
  String get calFieldLocation => 'Ubicación';

  @override
  String get calFieldLocationHint => 'p. ej. Praga, Chequia';

  @override
  String get calFieldDescription => 'Descripción';

  @override
  String get calFieldDescriptionHint => '¿De qué trata? (opcional)';

  @override
  String get calFieldAllDay => 'Evento de todo el día';

  @override
  String get calFieldStart => 'Inicio';

  @override
  String get calFieldEnd => 'Fin (opcional)';

  @override
  String get calPickDateTime => 'Elegir fecha y hora';

  @override
  String get calPickDate => 'Elegir fecha';

  @override
  String get calClearEnd => 'Quitar fin';

  @override
  String get calPublish => 'Publicar en Nostr';

  @override
  String get calPublishing => 'Publicando …';

  @override
  String get calPublishFail => 'Error al publicar. ¿En línea y conectado?';

  @override
  String get calNeedTitle => 'Introduce un título.';

  @override
  String get calNeedStart => 'Elige un inicio.';

  @override
  String get calPublishInfo =>
      'Este evento se publica públicamente en Nostr: todos con esta app lo verán en su calendario.';

  @override
  String get calMonth1 => 'Enero';

  @override
  String get calMonth2 => 'Febrero';

  @override
  String get calMonth3 => 'Marzo';

  @override
  String get calMonth4 => 'Abril';

  @override
  String get calMonth5 => 'Mayo';

  @override
  String get calMonth6 => 'Junio';

  @override
  String get calMonth7 => 'Julio';

  @override
  String get calMonth8 => 'Agosto';

  @override
  String get calMonth9 => 'Septiembre';

  @override
  String get calMonth10 => 'Octubre';

  @override
  String get calMonth11 => 'Noviembre';

  @override
  String get calMonth12 => 'Diciembre';

  @override
  String get calWd0 => 'Lun';

  @override
  String get calWd1 => 'Mar';

  @override
  String get calWd2 => 'Mié';

  @override
  String get calWd3 => 'Jue';

  @override
  String get calWd4 => 'Vie';

  @override
  String get calWd5 => 'Sáb';

  @override
  String get calWd6 => 'Dom';

  @override
  String get calTypeMeetup => 'Meetup';

  @override
  String get calTypeEvent => 'Evento';

  @override
  String get calLegendMeetup => 'Meetups';

  @override
  String get calLegendEvent => 'Eventos';

  @override
  String get portalManageEvents => 'Gestionar eventos';

  @override
  String get portalExistingEvents => 'Eventos existentes';

  @override
  String get portalLoadingEvents => 'Cargando eventos …';

  @override
  String get portalNoEvents => 'Aún no hay eventos para este meetup.';

  @override
  String get portalEditEvent => 'Editar evento';

  @override
  String get portalUpdatedOk => 'Evento actualizado ✓';

  @override
  String get portalUpdate => 'Guardar cambios';

  @override
  String get portalTapToEdit => 'Toca para editar';

  @override
  String get hubTitle => 'Eventos';

  @override
  String get hubMeetups => 'Meetups';

  @override
  String get hubMeetupsSub => 'Buscar y descubrir meetups';

  @override
  String get hubCalendar => 'Calendario de eventos';

  @override
  String get hubCalendarSub => 'Todos los eventos, por colores';

  @override
  String get hubExternal => 'Eventos externos';

  @override
  String get hubExternalSub => 'Conferencias y eventos de la comunidad';

  @override
  String get extTitle => 'Eventos externos';

  @override
  String get extIntro =>
      'Eventos de la comunidad (no meetups), p. ej. conferencias como BTC Praga o Zitadelle.';

  @override
  String get extLoading => 'Cargando eventos externos …';

  @override
  String get extNone => 'Aún no hay eventos externos.';

  @override
  String get extAdd => 'Añadir evento';

  @override
  String get calFilterAll => 'Todos';

  @override
  String get calFilterMeetups => 'Meetups';

  @override
  String get calFilterExternal => 'Externos';

  @override
  String get calFilterLocation => 'Buscar lugar/país …';

  @override
  String get calFilterActive => 'Filtro activo';

  @override
  String get calFilterClear => 'Borrar filtro';

  @override
  String get calFilterNoMatch => 'No hay eventos para este filtro.';

  @override
  String get calWorldwide => 'Mundial';

  @override
  String get calCommunityOnly => 'Solo comunidad';

  @override
  String get calWorldwideHint =>
      'Mundial muestra todos los eventos Nostr, también externos.';

  @override
  String get chTitle => 'Comunidad';

  @override
  String get chPortal => 'Portal';

  @override
  String get chPortalSub => 'Meetups · Eventos · Cursos · Mapa';

  @override
  String get chNews => 'Noticias';

  @override
  String get chNewsSub => 'Leer artículos';

  @override
  String get chNostr => 'Nostr';

  @override
  String get chNostrSub => 'Feed de la comunidad';

  @override
  String get chShoutout => 'Shoutout';

  @override
  String get chShoutoutSub => 'Enviar';

  @override
  String get chPodcast => 'Podcast';

  @override
  String get chPodcastSub => 'Escuchar';

  @override
  String get paTitle => 'Portal';

  @override
  String get paMeetups => 'Meetups';

  @override
  String get paMeetupsSub => 'Explorar meetups';

  @override
  String get paEvents => 'Eventos y confirmaciones';

  @override
  String get paEventsSub => 'Ver eventos y confirmar asistencia';

  @override
  String get paCourses => 'Cursos y docentes';

  @override
  String get paCoursesSub => 'La oferta educativa';

  @override
  String get paMap => 'Mapa';

  @override
  String get paMapSub => 'Meetups cercanos';

  @override
  String get paMine => 'Mis meetups';

  @override
  String get paMineSub => 'Gestionar eventos';

  @override
  String get paWeb => 'Web del portal';

  @override
  String get paWebSub => 'Abrir portal.einundzwanzig.space';

  @override
  String get rsvpLoading => 'Cargando eventos …';

  @override
  String get rsvpNone => 'No hay eventos próximos.';

  @override
  String get rsvpGoing => 'Confirmar';

  @override
  String get rsvpYouGo => 'Has confirmado ✓';

  @override
  String get rsvpCount => 'asistentes';

  @override
  String get rsvpNeedLogin => 'Inicia sesión en el portal primero.';

  @override
  String get rsvpFailed => 'Error al confirmar';

  @override
  String get crsLoading => 'Cargando cursos …';

  @override
  String get crsNone => 'No hay cursos.';

  @override
  String get crsCourses => 'Cursos';

  @override
  String get crsLecturers => 'Docentes';

  @override
  String get rsvpCancel => 'Cancelar';

  @override
  String get crsAbout => 'Sobre el curso';

  @override
  String get crsUpcoming => 'Próximas fechas';

  @override
  String get crsLecturer => 'Docente';

  @override
  String get lecAbout => 'Sobre el docente';

  @override
  String get lecLinks => 'Enlaces';

  @override
  String get crsOpenPortal => 'Abrir en el portal';

  @override
  String get rsvpImComing => 'Voy a ir';

  @override
  String get rsvpMaybe => 'Quizás';

  @override
  String get evOpenLink => 'Abrir enlace';

  @override
  String get evShare => 'Compartir';

  @override
  String get evToCalendar => 'Añadir al calendario';

  @override
  String get portalConnected => 'Portal conectado';

  @override
  String get portalLoginPrompt => 'Te conectamos al portal para confirmar.';

  @override
  String get portalTileSub => 'Para confirmaciones y tus meetups';

  @override
  String get ldTitle => 'Organizadores';

  @override
  String get ldManage => 'Gestionar organizadores';

  @override
  String get ldManageSub => 'Añadir co-organizadores';

  @override
  String get ldPickMeetup => 'Elegir meetup';

  @override
  String get ldCreator => 'Creador';

  @override
  String get ldAdd => 'Añadir organizador';

  @override
  String get ldAddHint => 'npub del nuevo organizador';

  @override
  String get ldAddDo => 'Añadir';

  @override
  String get ldRemove => 'Quitar';

  @override
  String get ldRemoveConfirm => '¿Quitar este organizador?';

  @override
  String get ldAdded => 'Organizador añadido';

  @override
  String get ldRemoved => 'Organizador quitado';

  @override
  String get ldFailed => 'Acción fallida';

  @override
  String get ldEmpty => 'Aún no hay otros organizadores.';

  @override
  String get ldLoading => 'Cargando organizadores …';

  @override
  String get ldNpubInvalid => 'Introduce un npub válido.';

  @override
  String get ldAddButton => 'Añadir admin';

  @override
  String get calLegendCourse => 'Cursos';

  @override
  String get calFilterCourses => 'Cursos';

  @override
  String get refreshRunning => 'Actualizando datos …';

  @override
  String get refreshDone => 'Todo actualizado';

  @override
  String get v4vSectionTitle => 'Apoyar';

  @override
  String get v4vSectionSubtitle =>
      'Value for Value – apoya el proyecto con sats';

  @override
  String get v4vTitle => 'Value for Value';

  @override
  String get v4vHeadline => 'Value for Value';

  @override
  String get v4vExplain1 =>
      'Esta app está hecha a mano para la comunidad: sin anuncios, sin rastreo, sin suscripción. Según el principio \"Value for Value\", devuelves lo que la app vale para ti.';

  @override
  String get v4vExplain2 =>
      'Tus sats van directamente al desarrollo del proyecto. Cada cantidad ayuda. ¡Gracias!';

  @override
  String get v4vAmountLabel => 'Cantidad';

  @override
  String get v4vDonateButton => 'Donar con Lightning';

  @override
  String get v4vRecipient => 'Destinatario';

  @override
  String get v4vErrInvalidAmount => 'Introduce una cantidad válida.';

  @override
  String get v4vErrBelowMin =>
      'La cantidad es demasiado baja para esta dirección.';

  @override
  String get v4vErrAboveMax =>
      'La cantidad es demasiado alta para esta dirección.';

  @override
  String get v4vErrUnreachable =>
      'Conexión fallida. Inténtalo de nuevo más tarde.';

  @override
  String get v4vErrGeneric => 'No se pudo crear la factura.';

  @override
  String get v4vNoWalletTitle => 'No se encontró ninguna wallet Lightning';

  @override
  String get v4vNoWalletBody =>
      'No se encontró ninguna app para pagar. Puedes copiar la factura y pegarla en tu wallet.';

  @override
  String get v4vCopyInvoice => 'Copiar factura';

  @override
  String get v4vCopied => 'Factura copiada';

  @override
  String get convPremiumTitle => 'Prima / Descuento';

  @override
  String get convPremiumHint =>
      'Para operaciones: prima (+) o descuento (−) en porcentaje sobre el precio.';

  @override
  String get convPremiumResult => 'Con prima/descuento';

  @override
  String get convPremiumBase => 'Precio base';

  @override
  String get convPremiumSats => 'Resultado en sats';

  @override
  String get portalTokenMismatch =>
      'Tu sesión del portal pertenece a otra clave Nostr y se ha desconectado. Vuelve a conectar el portal con la clave con la que eres líder.';
}
