// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'Compañero de Memorización Bíblica';

  @override
  String get navStudies => 'Estudios';

  @override
  String get navLibrary => 'Biblioteca';

  @override
  String get navStore => 'Tienda';

  @override
  String get navProgress => 'Progreso';

  @override
  String get navSettings => 'Ajustes';

  @override
  String get shellMyStudies => 'Mis estudios';

  @override
  String get account => 'Cuenta';

  @override
  String get signInTitle => 'Inicia sesión solo cuando te ayude';

  @override
  String get signInBody =>
      'Las descargas gratuitas de Escrituras siguen disponibles sin cuenta. La cuenta está reservada para el audio de pago futuro, la recuperación de compras y la sincronización entre dispositivos.';

  @override
  String get continueAsGuest => 'Continuar como invitado';

  @override
  String get previewSignInLater => 'Ver inicio de sesión más tarde';

  @override
  String updateRequiredForPackage(String version) {
    return 'Actualiza la app a la versión $version o superior para obtener este paquete.';
  }

  @override
  String get studiesGetStartedTitle => 'Selecciona un paquete para empezar';

  @override
  String get studiesGetStartedBody =>
      'Abre un paquete descargado desde la Biblioteca para crear tu primer estudio.';

  @override
  String get goToLibrary => 'Ir a la Biblioteca';

  @override
  String get createStudy => 'Crear estudio';

  @override
  String get studiesNoStudiesTitle => 'Aún no hay estudios';

  @override
  String get studiesNoStudiesBody =>
      'Aún no hay estudios para este paquete. Crea el primero.';

  @override
  String get deleteStudyTitle => '¿Eliminar este estudio?';

  @override
  String deleteStudyMessage(String title) {
    return '\"$title\" y su progreso se eliminarán de forma permanente.';
  }

  @override
  String get deleteStudyTooltip => 'Eliminar estudio';

  @override
  String get notStarted => 'Sin empezar';

  @override
  String get resume => 'Continuar';

  @override
  String get start => 'Empezar';

  @override
  String progressOf(int learned, int total) {
    return '$learned de $total aprendidos';
  }

  @override
  String get libraryPaneDownloads => 'Descargas';

  @override
  String get libraryNoDownloadsTitle => 'Aún no hay descargas';

  @override
  String get libraryNoDownloadsBody =>
      'Los paquetes que descargues de la Tienda aparecerán aquí y seguirán disponibles sin conexión.';

  @override
  String get libraryErrorTitle => 'No se pudo cargar el catálogo';

  @override
  String get tryAgain => 'Inténtalo de nuevo.';

  @override
  String get retry => 'Reintentar';

  @override
  String get libraryEmptyTitle => 'El catálogo está vacío';

  @override
  String get libraryEmptyBody => 'Aún no se ha publicado ningún paquete.';

  @override
  String get catalogFresh => 'Mostrando resultados en caché.';

  @override
  String catalogLastUpdated(String time) {
    return 'Actualizado hace $time.';
  }

  @override
  String get catalogStaleSuffix =>
      'No se pudo actualizar; se muestra la última lista conocida.';

  @override
  String get statusFree => 'Gratis';

  @override
  String get statusOwned => 'Comprado';

  @override
  String get statusPaid => 'De pago';

  @override
  String get actionDownload => 'Descargar';

  @override
  String get actionUnlock => 'Desbloquear';

  @override
  String get packageTypeBook => 'Libro';

  @override
  String get packageTypeSeason => 'Temporada';

  @override
  String get packageTypeAudio => 'Audio extra';

  @override
  String get packageTypePackage => 'Paquete';

  @override
  String get unknownSize => 'Tamaño desconocido';

  @override
  String sizeKilobytes(String size) {
    return '$size KB';
  }

  @override
  String sizeMegabytes(String size) {
    return '$size MB';
  }

  @override
  String get storeBannerDownloadsTitle => 'Descargas sin conexión';

  @override
  String get storeBannerDownloadsBody =>
      'Los paquetes descargados siguen disponibles sin conexión a internet, listos para repasar versículo por versículo.';

  @override
  String get storeBannerCatalogTitle =>
      'Catálogo de Escrituras accesible para invitados';

  @override
  String get storeBannerCatalogBody =>
      'El contenido gratuito puede explorarse y descargarse sin iniciar sesión. Las tarjetas bloqueadas anticipan futuros audios de pago.';

  @override
  String downloadingPercent(int percent) {
    return 'Descargando $percent%';
  }

  @override
  String get downloadingStarting => 'Comenzando…';

  @override
  String get downloadingVerifying => 'Verificando el checksum…';

  @override
  String get downloadingInstalling => 'Instalando…';

  @override
  String get cancel => 'Cancelar';

  @override
  String get downloadInstalled => 'Instalado';

  @override
  String updateAvailable(String version) {
    return 'Actualización disponible (v$version)';
  }

  @override
  String get update => 'Actualizar';

  @override
  String get open => 'Abrir';

  @override
  String get downloadFailedFallback => 'La descarga falló.';

  @override
  String get retryDownload => 'Reintentar descarga';

  @override
  String requiresAppVersion(String version) {
    return 'Requiere la versión $version de la app o superior.';
  }

  @override
  String get packageContents => 'Contenido del paquete';

  @override
  String get manifestErrorTitle => 'No se pudo cargar el contenido del paquete';

  @override
  String creditAttribution(String attribution) {
    return 'Crédito: $attribution';
  }

  @override
  String get removeDownloadTitle => '¿Eliminar esta descarga?';

  @override
  String removeDownloadMessage(String title) {
    return '\"$title\" y sus estudios se eliminarán de forma permanente de este dispositivo.';
  }

  @override
  String get remove => 'Eliminar';

  @override
  String get removeDownloadTooltip => 'Eliminar descarga';

  @override
  String get progressPackagesInstalled => 'Paquetes instalados';

  @override
  String get progressVersesLearned => 'Versículos aprendidos';

  @override
  String get progressEmptyTitle => 'Aún no hay nada instalado';

  @override
  String get progressEmptyBody =>
      'Instala un paquete y crea un estudio para ver tu progreso aquí.';

  @override
  String get progressByPackage => 'Por paquete';

  @override
  String progressVersesOf(int learned, int total) {
    return '$learned de $total versículos aprendidos';
  }

  @override
  String chapterWithNumber(int chapter) {
    return 'Capítulo $chapter';
  }

  @override
  String learnedOf(int learned, int total) {
    return '$learned de $total';
  }

  @override
  String get settingsTextSize => 'Tamaño del texto';

  @override
  String get settingsTextSizeSubtitle =>
      'Lectura cómoda con tarjetas de versículo más grandes';

  @override
  String get settingsThemeTone => 'Tono del tema';

  @override
  String get settingsThemeToneSubtitle =>
      'Pergamino tranquilo con fuerte contraste para las Escrituras';

  @override
  String get settingsAppLanguage => 'Idioma de la app';

  @override
  String get settingsAppLanguageSubtitle =>
      'Sigue el idioma del dispositivo con respaldo en inglés';

  @override
  String get settingsAudioTeaser => 'Vista previa de audio';

  @override
  String get settingsAudioTeaserSubtitle =>
      'Solo vista previa en la primera versión';

  @override
  String get settingStandard => 'Estándar';

  @override
  String get settingLight => 'Claro';

  @override
  String get settingAuto => 'Automático';

  @override
  String get settingOff => 'Apagado';

  @override
  String get studyByChapter => 'Por capítulo';

  @override
  String get studyBySection => 'Por sección';

  @override
  String get studyCustom => 'Personalizado';

  @override
  String studyOpenErrorTitle(String title) {
    return 'No se pudo abrir $title';
  }

  @override
  String get contentReadError => 'No se pudo leer el contenido del paquete.';

  @override
  String get noChaptersTitle => 'No se encontraron capítulos';

  @override
  String get noChaptersBody => 'Este paquete no tiene datos de capítulos.';

  @override
  String get byChapterHint =>
      'Toca un capítulo para crear y empezar un estudio con todos sus versículos.';

  @override
  String get noSectionsTitle => 'Este paquete no tiene secciones';

  @override
  String get noSectionsBody =>
      'Este paquete no incluye un archivo de secciones.';

  @override
  String get bySectionHint =>
      'Toca una sección con título para crear y empezar.';

  @override
  String sectionSubtitle(String range, int count) {
    return '$range · $count versículos';
  }

  @override
  String get filterHint =>
      'Filtra lo que ves abajo; tus versículos marcados se mantienen marcados de cualquier forma.';

  @override
  String get filterAll => 'Todos';

  @override
  String get filterDifficult => 'Difíciles';

  @override
  String get filterLearned => 'Aprendidos';

  @override
  String get studyNameField => 'Nombre del estudio';

  @override
  String versesSelected(int count) {
    return '$count versículos seleccionados';
  }

  @override
  String get go => 'Ir';

  @override
  String get studyEmptyBody => 'Este estudio no tiene versículos.';

  @override
  String verseProgress(int current, int total) {
    return 'Versículo $current de $total';
  }

  @override
  String get revealHint =>
      'Toca para revelar el texto del versículo y toca de nuevo para ocultarlo y poner a prueba tu memoria.';

  @override
  String get previous => 'Anterior';

  @override
  String get next => 'Siguiente';

  @override
  String defaultStudyName(int number) {
    return 'Mi estudio $number';
  }

  @override
  String versesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count versículos',
      one: '1 versículo',
    );
    return '$_temp0';
  }

  @override
  String chaptersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count capítulos',
      one: '1 capítulo',
    );
    return '$_temp0';
  }

  @override
  String filesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count archivos',
      one: '1 archivo',
    );
    return '$_temp0';
  }

  @override
  String get timeJustNow => 'ahora mismo';

  @override
  String timeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hace $count minutos',
      one: 'hace 1 minuto',
    );
    return '$_temp0';
  }

  @override
  String timeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hace $count horas',
      one: 'hace 1 hora',
    );
    return '$_temp0';
  }

  @override
  String timeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hace $count días',
      one: 'hace 1 día',
    );
    return '$_temp0';
  }

  @override
  String get commonDelete => 'Eliminar';

  @override
  String get drawerTagline =>
      'Práctica clara y tranquila de las Escrituras con paquetes sin conexión.';

  @override
  String get catalogPackages => 'Paquetes del catálogo';

  @override
  String get installedPackages => 'Paquetes instalados';

  @override
  String get guestModeNote =>
      'El modo invitado sigue totalmente soportado para descargas gratuitas de Escrituras.';

  @override
  String get errorGeneric => 'Algo salió mal.';

  @override
  String get errorRequestTimeout => 'El servidor tardó demasiado en responder.';

  @override
  String get errorNoInternet => 'No hay conexión a internet.';

  @override
  String get errorNetwork => 'Error de red.';

  @override
  String get errorRequestFailed => 'No se pudo contactar con el servidor.';

  @override
  String get errorUnexpectedResponse => 'Formato de respuesta inesperado.';

  @override
  String get errorInvalidJson => 'El servidor devolvió datos no válidos.';

  @override
  String get errorMissingArtifactUrl =>
      'Este paquete no tiene enlace de descarga.';

  @override
  String get errorDownloadTimeout => 'La descarga tardó demasiado en comenzar.';

  @override
  String errorDownloadFailedTitle(String title) {
    return 'No se pudo descargar $title.';
  }

  @override
  String get errorDownloadInterrupted => 'La descarga se interrumpió.';

  @override
  String get errorChecksumMismatch =>
      'No se pudo verificar el archivo descargado.';

  @override
  String get errorInstallGeneric => 'No se pudo instalar el paquete.';

  @override
  String get errorArchiveOpen => 'No se pudo abrir el archivo del paquete.';

  @override
  String get errorMissingManifest => 'El paquete no tiene manifest.json.';

  @override
  String get errorInvalidManifest => 'El manifiesto del paquete no es válido.';

  @override
  String get errorUnsafePath => 'El paquete contiene una ruta no segura.';

  @override
  String errorMissingFile(String file) {
    return 'Falta $file en el paquete.';
  }

  @override
  String errorFileSize(String file) {
    return '$file tiene un tamaño inesperado.';
  }

  @override
  String errorFileChecksum(String file) {
    return '$file no superó su verificación.';
  }

  @override
  String get errorCatalogLoad => 'No se pudo cargar el catálogo.';

  @override
  String errorContentMissing(String title) {
    return '$title ya no está en este dispositivo.';
  }

  @override
  String errorContentFileMissing(String file) {
    return 'Falta $file.';
  }

  @override
  String errorContentMalformed(String file) {
    return '$file está corrupto.';
  }

  @override
  String errorContentInvalidJson(String file) {
    return '$file no es JSON válido.';
  }
}
