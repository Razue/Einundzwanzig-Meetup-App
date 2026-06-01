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
}
