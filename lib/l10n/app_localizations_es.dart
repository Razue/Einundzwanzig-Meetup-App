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
}
