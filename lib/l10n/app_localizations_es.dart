// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'SpotVibe';

  @override
  String get continueBtn => 'Continuar';

  @override
  String get skipForNow => 'Omitir por ahora';

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Eliminar';

  @override
  String get allow => 'Permitir';

  @override
  String get allowed => 'Permitido';

  @override
  String get denied => 'Denegado';

  @override
  String get close => 'Cerrar';

  @override
  String get optional => 'Opcional';

  @override
  String get fullNameLabel => 'Nombre completo';

  @override
  String get emailLabel => 'Correo electrónico';

  @override
  String get passwordLabel => 'Contraseña';

  @override
  String get createAccount => 'Crear cuenta';

  @override
  String get signIn => 'Iniciar sesión';

  @override
  String get forgotPassword => '¿Olvidaste tu contraseña?';

  @override
  String get passwordResetBackend =>
      'Si existe una cuenta con ese correo, enviamos un enlace para restablecer la contraseña.';

  @override
  String get passwordResetInstructions =>
      'Ingresa el correo electrónico de tu cuenta de SpotVibe.';

  @override
  String get sendPasswordReset => 'Enviar enlace';

  @override
  String get passwordResetSent =>
      'Si existe una cuenta con ese correo, enviamos un enlace para restablecer la contraseña.';

  @override
  String get passwordResetFailed =>
      'No se pudo enviar el correo para restablecer la contraseña. Inténtalo de nuevo.';

  @override
  String get emailRequired => 'El correo es obligatorio';

  @override
  String get validEmail => 'Ingresa un correo electrónico válido';

  @override
  String get passwordRequired => 'La contraseña es obligatoria';

  @override
  String get passwordMinChars =>
      'La contraseña debe tener al menos 6 caracteres';

  @override
  String get fullNameRequired => 'El nombre completo es obligatorio';

  @override
  String get alreadyHaveAccount => '¿Ya tienes una cuenta? Inicia sesión';

  @override
  String get noAccountCreate => '¿No tienes una cuenta? Crea una';

  @override
  String get orContinueWithEmail => 'o continúa con tu correo';

  @override
  String get continueAsGuest => 'Continuar como invitado';

  @override
  String get agreeToTermsPrefix => 'Al continuar aceptas nuestros ';

  @override
  String get termsOfUse => 'Términos de uso';

  @override
  String get privacyPolicy => 'Política de privacidad';

  @override
  String get google => 'Google';

  @override
  String get facebook => 'Facebook';

  @override
  String get apple => 'Apple';

  @override
  String get discoverTitle => 'Descubre eventos\ncerca de ti';

  @override
  String get discoverBody =>
      'SpotVibe te muestra los mejores eventos locales: conciertos, festivales gastronómicos, reuniones comunitarias y más, personalizados según lo que te gusta.';

  @override
  String get nearYou => 'Cerca de ti';

  @override
  String get homeHappeningNearYou => 'Eventos cerca de ti';

  @override
  String get homeEditorialTagline => 'TU GUÍA LOCAL';

  @override
  String get homeNextUp => 'PRÓXIMAMENTE';

  @override
  String get quickFilters => 'Filtros rápidos';

  @override
  String openEvent(String title) {
    return 'Abrir $title';
  }

  @override
  String get personalised => 'Personalizado';

  @override
  String get social => 'Social';

  @override
  String get reminders => 'Recordatorios';

  @override
  String get quickPermsTitle => 'Un par de\npermisos rápidos';

  @override
  String get quickPermsBody =>
      'Concederlos hace que SpotVibe sea mucho más útil. Puedes cambiarlos cuando quieras en Configuración.';

  @override
  String get location => 'Ubicación';

  @override
  String get locationDesc =>
      'Encuentra eventos cerca de ti. Solo se usa mientras la app está abierta; nunca en segundo plano.';

  @override
  String get notifications => 'Notificaciones';

  @override
  String get notifDesc =>
      'Recibe alertas de eventos que te interesan, recordatorios de RSVP y novedades sociales.';

  @override
  String get whatAreYouInto => '¿Qué te gusta?';

  @override
  String get pickInterestsBody =>
      'Elige tus intereses y te mostraremos eventos que de verdad te importan.';

  @override
  String get selectAtLeastOne =>
      'Selecciona al menos uno para personalizar tu feed.';

  @override
  String get allSetTitle => '¡Todo listo! 🎉';

  @override
  String get allSetBody =>
      'Tu feed de eventos personalizado está listo.\nToca Explorar para ver qué está pasando cerca de ti.';

  @override
  String get browseNearYou => 'Explora eventos cerca de ti';

  @override
  String get filterByDatePrice => 'Filtra por fecha, precio y categoría';

  @override
  String get seeWhosGoing => 'Mira quién más va a ir';

  @override
  String get exploreSpotVibe => 'Explorar SpotVibe';

  @override
  String get interestMusic => 'Música';

  @override
  String get interestSports => 'Deportes';

  @override
  String get interestFoodDrink => 'Comida y bebida';

  @override
  String get interestArts => 'Arte';

  @override
  String get interestNightlife => 'Vida nocturna';

  @override
  String get interestComedy => 'Comedia';

  @override
  String get interestCommunity => 'Comunidad';

  @override
  String get interestTech => 'Tecnología';

  @override
  String get interestFitness => 'Fitness';

  @override
  String get interestFamily => 'Familia';

  @override
  String get interestOutdoor => 'Aire libre';

  @override
  String get interestFilm => 'Cine';

  @override
  String get setupTitle => 'Configuremos SpotVibe';

  @override
  String get setupBody =>
      'Un par de permisos rápidos hacen la experiencia\nmucho mejor.';

  @override
  String get locationCardDesc =>
      'Encuentra eventos cerca de ti. SpotVibe usa tu ubicación solo mientras la app está abierta; nunca en segundo plano.';

  @override
  String get notifCardDesc =>
      'Recibe alertas de nuevos eventos cerca de ti, mensajes de amigos y novedades de los eventos a los que asistirás.';

  @override
  String get changeSettingsAnytime =>
      'Puedes cambiar estos ajustes cuando quieras en la app de Configuración de tu dispositivo.';

  @override
  String get profile => 'Perfil';

  @override
  String get browsingAsGuest => 'Navegando como invitado';

  @override
  String get guestPrompt =>
      'Crea una cuenta para confirmar asistencia, dejar comentarios, crear eventos y conectar con otros.';

  @override
  String get signInOrCreate => 'Iniciar sesión o crear cuenta';

  @override
  String get notificationsSettings => 'Notificaciones';

  @override
  String get darkMode => 'Modo oscuro';

  @override
  String get map => 'Mapa';

  @override
  String get myEvents => 'Mis eventos';

  @override
  String get savedEvents => 'Eventos guardados';

  @override
  String get signOut => 'Cerrar sesión';

  @override
  String get deleteAccount => 'Eliminar cuenta';

  @override
  String get language => 'Idioma';

  @override
  String get languageSystemDefault => 'Predeterminado del sistema';

  @override
  String get english => 'English';

  @override
  String get spanish => 'Español (México)';

  @override
  String get deleteAccountTitle => '¿Eliminar cuenta?';

  @override
  String get deleteAccountBody =>
      'Esto elimina permanentemente tu cuenta, perfil, eventos, confirmaciones y comentarios. No se puede deshacer.';

  @override
  String get passwordEmailAccounts => 'Contraseña (cuentas de correo)';

  @override
  String get accountDeletedMsg => 'Tu cuenta y tus datos han sido eliminados.';

  @override
  String get forPromoters => 'Para promotores, venues y organizadores';

  @override
  String thenPrice(String price) {
    return 'después $price';
  }

  @override
  String foundingLock(String price, int remaining, int limit) {
    return 'Los venues fundadores aseguran $price: quedan $remaining de $limit';
  }

  @override
  String get freeTier => 'Gratis — \$0';

  @override
  String premiumTier(String price) {
    return 'Premium — $price';
  }

  @override
  String get everythingPlus =>
      'Todo lo de Gratis, más las herramientas a continuación.';

  @override
  String get welcomePremium => 'Bienvenido a SpotVibe Premium.';

  @override
  String get restorePurchases => 'Restaurar compras';

  @override
  String get noSubscriptionFound =>
      'No se encontró ninguna suscripción para restaurar.';

  @override
  String get bySubscribingPrefix => 'Al suscribirte aceptas nuestros ';

  @override
  String get youAreOnPremium => 'Tienes Premium';

  @override
  String get premiumUnlockedBody =>
      'Eventos recurrentes, galerías multimedia, analíticas, marca y reclamaciones verificadas están desbloqueados.';

  @override
  String get freePerk1 => 'Publica hasta 2 eventos únicos próximos a la vez';

  @override
  String get freePerk2 =>
      'Página de evento básica: título, descripción, 1 foto de portada, 1 video corto, ubicación y hora';

  @override
  String get freePerk3 => 'Tu evento aparece en el feed público';

  @override
  String get premiumPerk1Title => 'Eventos recurrentes';

  @override
  String get premiumPerk1Subtitle =>
      'Publica una vez y repite semanal o mensualmente';

  @override
  String get premiumPerk2Title => 'Posicionamiento destacado';

  @override
  String get premiumPerk2Subtitle =>
      'Arriba del feed de la categoría 1 vez por semana';

  @override
  String get premiumPerk3Title => 'Panel de analíticas';

  @override
  String get premiumPerk3Subtitle => 'Vistas, guardados y clics en vivo';

  @override
  String get premiumPerk4Title => 'Marca personalizada';

  @override
  String get premiumPerk4Subtitle =>
      'Logo y colores de marca en la página de tu evento';

  @override
  String get premiumPerk5Title => 'Botón de contacto';

  @override
  String get premiumPerk5Subtitle =>
      'Teléfono, sitio web y herramientas de contacto';

  @override
  String get premiumPerk6Title => 'Sin anuncios';

  @override
  String get premiumPerk6Subtitle => 'Páginas de evento limpias y sin anuncios';

  @override
  String get premiumPerk7Title => 'Reclama eventos existentes';

  @override
  String get premiumPerk7Subtitle =>
      'Verifica primero. Tu primer reclamo es gratis';

  @override
  String get premiumPerk8Title => 'Galería multimedia';

  @override
  String get premiumPerk8Subtitle =>
      'Hasta 5 fotos y 3 videos cortos en cada evento';

  @override
  String get trialLabel => 'prueba gratuita de 7 días';

  @override
  String get startFreeTrial => 'Comienza tu prueba gratuita de 7 días';

  @override
  String perMonth(String price) {
    return '$price/mes';
  }

  @override
  String afterTrial(String trial) {
    return 'después de una $trial';
  }

  @override
  String billingFoundingOpen(
    String trial,
    String price,
    int remaining,
    int limit,
  ) {
    return '$trial, después $price con precio asegurado para venues fundadores · quedan $remaining de $limit · cancela cuando quieras';
  }

  @override
  String billingFoundingLocked(String price) {
    return 'Precio fundador asegurado en $price · cobro mensual · cancela cuando quieras';
  }

  @override
  String billingStandard(String trial, String price) {
    return '$trial, después $price · cobro mensual · cancela cuando quieras';
  }

  @override
  String get purchaseFailed => 'La compra falló. Inténtalo de nuevo.';

  @override
  String get noActiveSubscription =>
      'No se encontró una suscripción activa para restaurar.';

  @override
  String get restoreFailed => 'La restauración falló. Inténtalo de nuevo.';

  @override
  String get filtersTooltip => 'Filtros';

  @override
  String get couldNotGetLocation =>
      'No pudimos determinar tu ubicación. Verifica que la ubicación esté activada en la configuración de tu dispositivo e inténtalo de nuevo.';

  @override
  String showingEventsIn(String area) {
    return 'Mostrando eventos en \"$area\"';
  }

  @override
  String get clear => 'Limpiar';

  @override
  String searchResults(int count, String query) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count resultados para \"$query\"',
      one: '1 resultado para \"$query\"',
    );
    return '$_temp0';
  }

  @override
  String get nearestFirst => 'Más cercanos primero';

  @override
  String get byDate => 'Por fecha';

  @override
  String get errorTitle => 'No se pudieron cargar los eventos';

  @override
  String get errorSubtitle =>
      'Revisa tu conexión e inténtalo de nuevo. Tus eventos guardados siguen disponibles.';

  @override
  String get tryAgain => 'Reintentar';

  @override
  String get viewSavedEvents => 'Ver eventos guardados';

  @override
  String get noMatchesTitle => 'No hay resultados con estos filtros';

  @override
  String get noMatchesSubtitle =>
      'Intenta ampliar tu búsqueda: ajusta los filtros de fecha, precio o categoría para ver más eventos.';

  @override
  String get clearFilters => 'Limpiar filtros';

  @override
  String noEventsNear(String area) {
    return 'No hay eventos cerca de \"$area\"';
  }

  @override
  String get noEventsNearSubtitle =>
      'Prueba con otra ciudad o código postal, o aumenta el radio de búsqueda en las opciones de filtro.';

  @override
  String get increaseRadius => 'Aumentar radio';

  @override
  String get clearLocation => 'Quitar ubicación';

  @override
  String get locationNeededTitle => 'Encuentra eventos cerca de ti';

  @override
  String get locationNeededSubtitle =>
      'Usa tu ubicación para ver eventos cercanos. Si ya permitiste el acceso, verifica que la ubicación esté activada en la configuración de tu dispositivo.';

  @override
  String get enableLocation => 'Usar mi ubicación';

  @override
  String get browseAllEvents => 'Ver todos los eventos';

  @override
  String get noEventsFoundTitle => 'No se encontraron eventos cerca';

  @override
  String get noEventsFoundSubtitle =>
      'Prueba aumentar el radio de búsqueda o vuelve más tarde: se agregan eventos nuevos todos los días.';

  @override
  String get shareEventTooltip => 'Compartir evento';

  @override
  String get featuredThisWeek => 'DESTACADO ESTA SEMANA';

  @override
  String get tickets => 'Boletos';

  @override
  String get aboutThisEvent => 'Acerca de este evento';

  @override
  String get organizer => 'Organizador';

  @override
  String bookmarkedCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Guardados',
      one: '1 Guardado',
    );
    return '$_temp0';
  }

  @override
  String interestedCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Interesados',
      one: '1 Interesado',
    );
    return '$_temp0';
  }

  @override
  String followingName(String name) {
    return 'Siguiendo a $name';
  }

  @override
  String unfollowedName(String name) {
    return 'Dejaste de seguir a $name';
  }

  @override
  String get userBlocked => 'Usuario bloqueado';

  @override
  String get reportUser => 'Reportar usuario';

  @override
  String get reasonForReporting => 'Motivo del reporte...';

  @override
  String get reportSubmitted => 'Reporte enviado';

  @override
  String get submit => 'Enviar';

  @override
  String get freePlanLimit => 'Límite del plan gratis';

  @override
  String freePlanLimitBody(String trial) {
    return 'Las cuentas gratis pueden tener 2 eventos únicos próximos a la vez. Comienza una $trial para eventos ilimitados y recurrentes.';
  }

  @override
  String get notNow => 'Ahora no';

  @override
  String get goPremium => 'Ir a Premium';

  @override
  String policyViolation(String category, String reason) {
    return 'Violación de la política de $category: $reason';
  }

  @override
  String contentWarning(String category, String reason) {
    return 'Advertencia de $category: $reason Tu evento se enviará de todos modos.';
  }

  @override
  String get content => 'Contenido';

  @override
  String get eventUpdated => '¡Evento actualizado!';

  @override
  String get eventCreated => '¡Evento creado!';

  @override
  String get editEvent => 'Editar evento';

  @override
  String get createEvent => 'Crear evento';

  @override
  String get save => 'Guardar';

  @override
  String get publish => 'Publicar';

  @override
  String get eventPublishing => 'Publicación del evento';

  @override
  String get eventDetails => 'Detalles del evento';

  @override
  String get eventTitle => 'Título del evento';

  @override
  String get eventTitleHint => 'p. ej. Mercado Nocturno de Verano';

  @override
  String get titleRequired => 'El título es obligatorio';

  @override
  String get description => 'Descripción';

  @override
  String get descriptionHint => 'Cuéntale a la gente de qué trata tu evento...';

  @override
  String get descriptionRequired => 'La descripción es obligatoria';

  @override
  String get dateAndTime => 'Fecha y hora';

  @override
  String get date => 'Fecha';

  @override
  String get time => 'Hora';

  @override
  String get locationSection => 'Ubicación';

  @override
  String get venueName => 'Nombre del venue';

  @override
  String get venueNameHint => 'p. ej. Parque Riverside';

  @override
  String get venueNameRequired => 'El nombre del venue es obligatorio';

  @override
  String get streetAddress => 'Dirección';

  @override
  String get streetAddressHint => 'Calle Principal 123';

  @override
  String get city => 'Ciudad';

  @override
  String get cityHint => 'El Paso';

  @override
  String get state => 'Estado';

  @override
  String get stateHint => 'TX';

  @override
  String get zip => 'C.P.';

  @override
  String get zipHint => '79901';

  @override
  String get mapLinkOptional => 'Enlace de mapa (opcional)';

  @override
  String get extras => 'Extras';

  @override
  String get ticketPriceLabel =>
      'Precio del boleto (deja en blanco si es gratis)';

  @override
  String get enterValidPrice => 'Ingresa un precio válido';

  @override
  String get eventImageUrl => 'URL de la imagen del evento (opcional)';

  @override
  String get eventVideoUrl => 'URL del video del evento (opcional)';

  @override
  String get aiArtDirection => 'Dirección artística (opcional)';

  @override
  String get aiArtDirectionHint =>
      'p. ej., mesas de billar con neón azul, iluminación elegante y espacio para el título';

  @override
  String get aiArtworkOnly =>
      'La IA crea solo el arte. Poster Studio agrega los datos exactos del evento. Revisa el resultado antes de publicar; no se envía a SpotVibe para aprobación manual. No uses logotipos engañosos, imágenes de celebridades ni personajes protegidos por derechos de autor.';

  @override
  String get posterStudio => 'Estudio de pósteres';

  @override
  String get posterStudioIntro =>
      'Diseña un póster listo para compartir usando los datos exactos de este evento. Si cambias un dato, abre de nuevo el Estudio de pósteres para actualizarlo.';

  @override
  String get posterExactDetails =>
      'SpotVibe escribe el título, fecha, hora, venue y precio desde este formulario. No se le pide a la IA que cree estos datos.';

  @override
  String get posterTemplate => 'Plantilla';

  @override
  String get posterLayout => 'Diseño';

  @override
  String get posterTemplateBold => 'Impactante';

  @override
  String get posterTemplateEditorial => 'Editorial';

  @override
  String get posterTemplateNeon => 'Neón';

  @override
  String get posterTemplateMinimal => 'Minimalista';

  @override
  String get posterLayoutLeft => 'Izquierda';

  @override
  String get posterLayoutCenter => 'Centrado';

  @override
  String get posterShowVenue => 'Mostrar venue y ubicación';

  @override
  String get posterShowPrice => 'Mostrar precio del boleto';

  @override
  String get posterPreparing => 'Preparando póster…';

  @override
  String get sharePoster => 'Compartir póster';

  @override
  String get posterCaptureFailed =>
      'No se pudo crear el póster. Inténtalo de nuevo.';

  @override
  String get posterSharingMobileOnly =>
      'Compartir pósteres está disponible en la app de Android.';

  @override
  String get createSharePoster => 'Crear y compartir póster completo';

  @override
  String get posterCoverStays => 'La portada actual del evento no cambia.';

  @override
  String get posterTitleVenueRequired =>
      'Agrega un título y venue antes de crear un póster.';

  @override
  String eventPhotosCount(int current, int maximum) {
    return 'Fotos del evento ($current/$maximum)';
  }

  @override
  String get photoGalleryHint =>
      'Agrega hasta 5 fotos en total. La portada cuenta como la primera.';

  @override
  String get photoGalleryFreeHint =>
      'Los eventos gratis incluyen 1 foto de portada. Premium desbloquea hasta 5 fotos.';

  @override
  String get videoGalleryFreeHint =>
      'Los eventos gratis incluyen 1 video corto. Premium desbloquea hasta 3 videos.';

  @override
  String get noAdditionalPhotos => 'Agrega fotos desde tu biblioteca o cámara.';

  @override
  String get addPhotoUrl => 'Agregar enlace de foto (opcional)';

  @override
  String get addPhotoLink => 'Agregar enlace de foto';

  @override
  String get validPhotoUrl => 'Ingresa un enlace de foto http o https válido.';

  @override
  String get library => 'Biblioteca';

  @override
  String get camera => 'Cámara';

  @override
  String photoNumber(int number) {
    return 'Foto $number';
  }

  @override
  String eventVideosCount(int current, int maximum) {
    return 'Videos del evento ($current/$maximum)';
  }

  @override
  String get videoGalleryHint =>
      'Agrega hasta 3 videos cortos. Cada uno puede durar hasta 30 segundos.';

  @override
  String get noVideosYet =>
      'Aún no hay videos. Agrega uno desde tu biblioteca o cámara.';

  @override
  String videoNumber(int number) {
    return 'Video $number';
  }

  @override
  String get addVideoUrl => 'Agregar enlace de video (opcional)';

  @override
  String get addVideoLink => 'Agregar enlace de video';

  @override
  String get validVideoUrl => 'Ingresa un enlace de video http o https válido.';

  @override
  String mediaPhotoLimit(int maximum) {
    return 'Puedes agregar hasta $maximum fotos a un evento.';
  }

  @override
  String mediaVideoLimit(int maximum) {
    return 'Puedes agregar hasta $maximum videos a un evento.';
  }

  @override
  String get photos => 'Fotos';

  @override
  String get mediaPremiumPerk =>
      'Premium desbloquea hasta 5 fotos y 3 videos por evento.';

  @override
  String get unlockMediaGallery => 'Desbloquear galería completa';

  @override
  String get videos => 'Videos';

  @override
  String get chatLink => 'Enlace de chat comunitario (opcional)';

  @override
  String get saveChanges => 'Guardar cambios';

  @override
  String get publishPremium => 'Publicar evento — Premium';

  @override
  String get publishFree => 'Publicar evento — Gratis';

  @override
  String get premium => 'Premium';

  @override
  String get premiumFeaturesSubtitle =>
      'Eventos recurrentes · galería multimedia · analíticas · marca personalizada · botón de contacto';

  @override
  String get premiumFeaturesUnlocked => 'Funciones Premium desbloqueadas';

  @override
  String get recurringSchedule => 'Calendario recurrente';

  @override
  String get contactInfo => 'Información de contacto';

  @override
  String get phoneOptional => 'Teléfono (opcional)';

  @override
  String get websiteOptional => 'Sitio web (opcional)';

  @override
  String get socialHandleOptional => 'Otra cuenta social (opcional)';

  @override
  String get organizerSocialLinks =>
      'Enlaces de redes sociales del organizador';

  @override
  String get organizerSocialLinksHelp =>
      'Opcional. Agrega perfiles públicos que controlas. Se muestran como botones en este evento; SpotVibe nunca se conecta ni publica en tus cuentas.';

  @override
  String get instagramOptional => 'Instagram (opcional)';

  @override
  String get facebookOptional => 'Facebook (opcional)';

  @override
  String get snapchatOptional => 'Snapchat (opcional)';

  @override
  String get tiktokOptional => 'TikTok (opcional)';

  @override
  String get youtubeOptional => 'YouTube (opcional)';

  @override
  String get socialProfileHint => '@tucuenta o https://...';

  @override
  String validSocialProfileLink(String platform) {
    return 'Ingresa un usuario o enlace HTTPS válido de $platform.';
  }

  @override
  String get followOrganizer => 'Sigue al organizador';

  @override
  String get socialLinkOpenFailed =>
      'No se pudo abrir este enlace de red social.';

  @override
  String get shareSocialHint =>
      'Elige Instagram, Facebook, Snapchat u otra app instalada.';

  @override
  String get customBranding => 'Marca personalizada';

  @override
  String get brandAccentColor => 'Color de acento de marca';

  @override
  String get brandLogoUrl => 'URL del logo de marca (opcional)';

  @override
  String get oneTime => 'Único';

  @override
  String get weekly => 'Semanal';

  @override
  String get monthly => 'Mensual';

  @override
  String get category => 'Categoría';

  @override
  String get premiumUnlimited => 'Premium — eventos ilimitados';

  @override
  String get premiumIncludes =>
      'Incluye galerías multimedia, eventos recurrentes, analíticas, marca y reclamaciones.';

  @override
  String get freePlan => 'Plan gratis';

  @override
  String get freePlanBody =>
      'Hasta 2 eventos únicos próximos a la vez. Página básica con 1 foto de portada, 1 video corto, título, descripción, ubicación, hora y enlaces públicos del organizador en el feed público.';

  @override
  String upgradeToPremium(String price) {
    return 'Mejora a Premium — $price';
  }

  @override
  String get searchHint => 'Busca eventos, artistas, venues...';

  @override
  String get areaHint => 'Código postal, ciudad o estado...';

  @override
  String get usingYourLocation => 'Usando tu ubicación';

  @override
  String get useMyLocation => 'Usar mi ubicación';

  @override
  String get featured => 'DESTACADO';

  @override
  String byOrganizer(String name) {
    return 'por $name';
  }

  @override
  String get underTenthMi => '<0.1 millas';

  @override
  String miShort(String value) {
    return '$value millas';
  }

  @override
  String get couldNotOpenTickets => 'No se pudieron abrir los boletos.';

  @override
  String get getTicketsOnTm => 'Consigue boletos en Ticketmaster';

  @override
  String get getTickets => 'Conseguir boletos';

  @override
  String get logInToRsvp => 'Inicia sesión para confirmar';

  @override
  String get rsvpToThisEvent => 'Confirmar asistencia a este evento';

  @override
  String get youAreAttending => '¡Vas a asistir!';

  @override
  String get privateRsvp => 'RSVP privado';

  @override
  String get publicRsvp => 'RSVP público';

  @override
  String get cancelRsvp => 'Cancelar RSVP';

  @override
  String get rsvpSubtitle =>
      'Haz saber a los demás que irás, o mantenlo privado.';

  @override
  String get keepPrivate => 'Mantener mi RSVP privado';

  @override
  String get onlyCountVisible => 'Solo se verá el número, no tu nombre.';

  @override
  String get nameWillAppear => 'Tu nombre aparecerá en la lista de asistentes.';

  @override
  String get confirmRsvp => 'Confirmar RSVP';

  @override
  String get claimPromo =>
      '¿Promotor? Verifica este evento: el primer reclamo es gratis.';

  @override
  String get calendarError =>
      'No se pudo abrir el calendario. Agrega el evento manualmente.';

  @override
  String get googleCalendarError => 'No se pudo abrir Google Calendar.';

  @override
  String get addToGoogleCalendar => 'Agregar a Google Calendar';

  @override
  String get addToAppleCalendar => 'Agregar a Apple Calendar';

  @override
  String get sponsored => 'Patrocinado';

  @override
  String get goingOutThisWeek => '¿Sales esta semana?';

  @override
  String get pageAdBody =>
      'SpotVibe te muestra música en vivo, comida y vida nocturna cerca de ti, sin buscar por toda la ciudad.';

  @override
  String get browseEvents => 'Explorar eventos';

  @override
  String get comments => 'Comentarios';

  @override
  String get noCommentsYet => 'Aún no hay comentarios. ¡Sé el primero!';

  @override
  String get logInToComment => 'Inicia sesión para dejar un comentario';

  @override
  String get justNow => 'justo ahora';

  @override
  String minutesAgo(int minutes) {
    return 'hace $minutes min';
  }

  @override
  String hoursAgo(int hours) {
    return 'hace $hours h';
  }

  @override
  String get you => 'Tú';

  @override
  String detectedLabel(String category) {
    return '$category detectado';
  }

  @override
  String warningLabel(String category) {
    return 'Advertencia de $category';
  }

  @override
  String get reviewComment => 'Revisa tu comentario por favor.';

  @override
  String get addCommentHint => 'Agrega un comentario…';

  @override
  String get whosGoing => 'Quién va';

  @override
  String get noRsvpsYet => 'Nadie ha confirmado aún';

  @override
  String get beFirstToGo => 'Sé el primero en decir que irás.';

  @override
  String get attendeesPrivate => 'Los asistentes mantienen sus RSVP privados.';

  @override
  String peopleGoing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count personas van a asistir',
      one: '1 persona va a asistir',
    );
    return '$_temp0';
  }

  @override
  String get bePartOfExperience => 'Sé parte de la experiencia';

  @override
  String privateCount(int count) {
    return '+$count privados';
  }

  @override
  String get mapsError => 'No se pudieron abrir los mapas para este venue.';

  @override
  String get reportEvent => 'Reportar evento';

  @override
  String get whatsWrong => '¿Qué está mal con este evento?';

  @override
  String get reportSubmittedThanks => 'Reporte enviado. ¡Gracias!';

  @override
  String get calendar => 'Calendario';

  @override
  String get directions => 'Cómo llegar';

  @override
  String get share => 'Compartir';

  @override
  String get story => 'Historia';

  @override
  String get reportThisEvent => 'Reportar este evento';

  @override
  String get practicalInfo => 'Información práctica';

  @override
  String get weather => 'Clima';

  @override
  String get weatherValue => 'Revisa el pronóstico cerca de la fecha';

  @override
  String get parking => 'Estacionamiento';

  @override
  String get parkingValue =>
      'Estacionamiento en la calle y lotes cercanos disponibles';

  @override
  String get duration => 'Duración';

  @override
  String get age => 'Edad';

  @override
  String get accessible => 'Accesible';

  @override
  String get accessibleValue => 'Venue accesible para silla de ruedas';

  @override
  String get dur2to3 => '2–3 horas';

  @override
  String get dur2to4 => '2–4 horas';

  @override
  String get dur1to2 => '1–2 horas';

  @override
  String get dur1to3 => '1–3 horas';

  @override
  String get dur15to25 => '1.5–2.5 horas';

  @override
  String get dur3to5 => '3–5 horas';

  @override
  String get age21plus => 'Solo 21+';

  @override
  String get age18plus => '18+';

  @override
  String get moreLikeThis => 'Más como esto';

  @override
  String get seeAll => 'Ver todo';

  @override
  String get whyAmISeeing => '¿Por qué veo esto?';

  @override
  String get personalizationBody =>
      'SpotVibe aprende de cómo interactúas con los eventos: lo que ves, guardas y a lo que confirmas asistencia. Con el tiempo, el feed se reordena para mostrar más de lo que disfrutas.';

  @override
  String get topInterests => 'Tus principales intereses ahora:';

  @override
  String get resetMyPreferences => 'Restablecer mis preferencias';

  @override
  String get gotIt => 'Entendido';

  @override
  String get personalizingFeed => 'Personalizando tu feed…';

  @override
  String get showingMore => 'Mostrando más ';

  @override
  String get forYou => ' para ti';

  @override
  String showingAll(int total) {
    return 'Mostrando los $total eventos';
  }

  @override
  String showingRange(int start, int end, int total) {
    return 'Mostrando $start–$end de $total eventos';
  }

  @override
  String get previous => 'Anterior';

  @override
  String pageXOfY(int page, int total) {
    return 'Página $page de $total';
  }

  @override
  String get next => 'Siguiente';

  @override
  String get allDates => 'Todas las fechas';

  @override
  String get today => 'Hoy';

  @override
  String get tomorrow => 'Mañana';

  @override
  String get thisWeekend => 'Este fin de semana';

  @override
  String get thisWeek => 'Esta semana';

  @override
  String get customRange => 'Rango personalizado';

  @override
  String get anyPrice => 'Cualquier precio';

  @override
  String get free => 'Gratis';

  @override
  String get under20 => 'Menos de \$20';

  @override
  String get under50 => 'Menos de \$50';

  @override
  String get anyTime => 'Cualquier hora';

  @override
  String get morning => 'Mañana';

  @override
  String get afternoon => 'Tarde';

  @override
  String get evening => 'Noche (temprano)';

  @override
  String get night => 'Noche';

  @override
  String get anyDate => 'Cualquier fecha';

  @override
  String get anyDistance => 'Cualquier distancia';

  @override
  String get filterEvents => 'Filtrar eventos';

  @override
  String get clearAll => 'Limpiar todo';

  @override
  String get from => 'Desde';

  @override
  String get to => 'Hasta';

  @override
  String get price => 'Precio';

  @override
  String get timeOfDay => 'Hora del día';

  @override
  String get distance => 'Distancia';

  @override
  String get any => 'Cualquiera';

  @override
  String get locationHint => 'p. ej. Brooklyn, Manhattan...';

  @override
  String get eventSources => 'Fuentes de eventos';

  @override
  String get showResults => 'Ver resultados';

  @override
  String get catAll => 'Todo';

  @override
  String get catMusic => 'Música';

  @override
  String get catFood => 'Comida';

  @override
  String get catFoodDrink => 'Comida y bebida';

  @override
  String get catArts => 'Arte';

  @override
  String get catSports => 'Deportes';

  @override
  String get catTech => 'Tecnología';

  @override
  String get catCommunity => 'Comunidad';

  @override
  String get catFamily => 'Familia';

  @override
  String get catWellness => 'Bienestar';

  @override
  String get catSocial => 'Social';

  @override
  String get catMarkets => 'Mercados';

  @override
  String get catDance => 'Baile';

  @override
  String get catFunGames => 'Diversión y juegos';

  @override
  String get catHealth => 'Salud';

  @override
  String get catOther => 'Otro';

  @override
  String get catNightlife => 'Vida nocturna';

  @override
  String get catComedy => 'Comedia';

  @override
  String get catFitness => 'Fitness';

  @override
  String get catOutdoor => 'Aire libre';

  @override
  String get catFilm => 'Cine';

  @override
  String activeLabel(String price) {
    return 'Activo — $price';
  }

  @override
  String trialActiveLabel(String price) {
    return 'Prueba activa — después $price';
  }

  @override
  String get and => ' y ';

  @override
  String get tourNext => 'Siguiente';

  @override
  String get tourDone => 'Listo';

  @override
  String get tourSkip => 'Omitir';

  @override
  String get takeTheTour => 'Hacer el recorrido';

  @override
  String get tourRestarted =>
      'Recorrido reiniciado. Se reproducirá de nuevo en las próximas pantallas que abras.';

  @override
  String get tourHome1Title => 'Bienvenido a SpotVibe';

  @override
  String get tourHome1Body =>
      'Encuentra eventos reales cerca de ti: conciertos, comida, vida nocturna y más.';

  @override
  String get tourHome2Title => 'Busca eventos';

  @override
  String get tourHome2Body =>
      'Busca por evento, artista o venue, o por código postal, ciudad o estado.';

  @override
  String get tourHome3Title => 'Filtra los resultados';

  @override
  String get tourHome3Body =>
      'Acota los resultados por fecha, precio, hora del día, distancia y más.';

  @override
  String get tourHome4Title => 'Explora categorías';

  @override
  String get tourHome4Body =>
      'Toca una categoría para enfocar tu feed en lo que te gusta.';

  @override
  String get tourHome5Title => 'Tu feed de eventos';

  @override
  String get tourHome5Body =>
      'Desplázate para descubrir eventos. Toca una tarjeta para ver detalles, boletos y confirmar asistencia.';

  @override
  String get tourEvent1Title => 'Confirma tu asistencia';

  @override
  String get tourEvent1Body =>
      'Toca aquí para decir que asistirás, en público o en privado: tú decides.';

  @override
  String get tourEvent2Title => 'Guarda y sigue';

  @override
  String get tourEvent2Body => 'Guarda eventos o marca los que te interesan.';

  @override
  String get tourEvent3Title => 'Comparte';

  @override
  String get tourEvent3Body =>
      'Envía el evento a tus amigos como enlace o tarjeta para compartir.';

  @override
  String get tourProfile1Title => 'SpotVibe Premium';

  @override
  String get tourProfile1Body =>
      'Desbloquea eventos recurrentes, analíticas y marca personalizada.';

  @override
  String get tourProfile2Title => 'Idioma';

  @override
  String get tourProfile2Body =>
      'Cambia entre inglés y español cuando quieras.';

  @override
  String get tourProfile3Title => 'Tus eventos';

  @override
  String get tourProfile3Body =>
      'Administra los eventos que has creado y guardado.';

  @override
  String get adminDashboard => 'Panel de administración';

  @override
  String get adminAccountAccess => 'Acceso de administrador';

  @override
  String get adminAccountAccessBody =>
      'Todas las herramientas de creador y Premium están habilitadas para esta cuenta.';

  @override
  String get adminReports => 'Reportes';

  @override
  String get adminEvents => 'Eventos';

  @override
  String get adminNoReports => 'No hay reportes pendientes: todo está al día.';

  @override
  String get adminResolve => 'Marcar resuelto';

  @override
  String get adminRemove => 'Eliminar';

  @override
  String get adminRemoveEvent => 'Eliminar evento';

  @override
  String get adminRemoveEventTitle => '¿Eliminar este evento?';

  @override
  String get adminRemoveEventBody =>
      'Esto elimina permanentemente el evento, sus comentarios y confirmaciones del feed público.';

  @override
  String get adminEventRemoved => 'Evento eliminado.';

  @override
  String get adminReportResolved => 'Reporte resuelto.';

  @override
  String get adminSearchEvents => 'Buscar eventos…';

  @override
  String get adminNoEvents => 'No se encontraron eventos.';

  @override
  String adminReason(String reason) {
    return 'Motivo: $reason';
  }

  @override
  String adminReportedUser(String id) {
    return 'Usuario reportado: $id';
  }

  @override
  String adminReportedBy(String id) {
    return 'Reportado por: $id';
  }

  @override
  String get adminAccess => 'Administrador';

  @override
  String get adminDeleteComment => 'Eliminar comentario';

  @override
  String get adminCommentRemoved => 'Comentario eliminado.';

  @override
  String get adminPostUnlimited => 'Cuenta oficial: eventos únicos ilimitados';

  @override
  String get adminSearchHint => 'Busca por título, venue u organizador…';

  @override
  String get adminDeleteCommentBody =>
      'Esto elimina permanentemente el comentario de la página del evento.';

  @override
  String get adminClaims => 'Reclamos';

  @override
  String get adminNoClaims => 'Aún no hay reclamos de venues.';

  @override
  String get adminApprove => 'Aprobar';

  @override
  String get adminReject => 'Rechazar';

  @override
  String get adminClaimApproved =>
      'Reclamo aprobado: el venue ya puede editar este evento.';

  @override
  String get adminClaimRejected => 'Reclamo rechazado.';

  @override
  String get adminPending => 'Pendiente';

  @override
  String get adminApproved => 'Aprobado';

  @override
  String get adminRejected => 'Rechazado';

  @override
  String get adminBanUser => 'Bloquear usuario';

  @override
  String get adminUnban => 'Desbloquear';

  @override
  String get adminBannedUsers => 'Usuarios bloqueados';

  @override
  String get adminNoBanned => 'No hay usuarios bloqueados.';

  @override
  String get adminUserBanned =>
      'Usuario bloqueado: su contenido ahora está oculto.';

  @override
  String get adminUserUnbanned => 'Usuario desbloqueado.';

  @override
  String get adminBanConfirmTitle => '¿Bloquear a este usuario?';

  @override
  String get adminBanConfirmBody =>
      'Esto oculta todos sus eventos, comentarios y confirmaciones de la app. Puedes deshacerlo cuando quieras.';

  @override
  String get claimRoleOwner => 'Dueño / operador';

  @override
  String get claimRolePromoter => 'Promotor autorizado';

  @override
  String get claimRoleBookingAgent => 'Agente de reservas';

  @override
  String get claimRoleMarketing => 'Marketing / RRPP';

  @override
  String get claimRoleOther => 'Otro representante autorizado';

  @override
  String get authInvalidEmail => 'Esa dirección de correo no es válida.';

  @override
  String get authWrongCredentials => 'Correo o contraseña incorrectos.';

  @override
  String get authEmailInUse => 'Ese correo ya está en uso.';

  @override
  String get authWeakPassword => 'Esa contraseña es demasiado débil.';

  @override
  String get authTooManyRequests =>
      'Demasiados intentos. Inténtalo de nuevo más tarde.';

  @override
  String get authNetworkError =>
      'Error de red. Revisa tu conexión e inténtalo de nuevo.';

  @override
  String get authMethodDisabled =>
      'Este método de inicio de sesión está deshabilitado.';

  @override
  String get authDifferentCredential =>
      'Ese correo ya está vinculado a otro método de inicio de sesión.';

  @override
  String get authCancelled => 'Inicio de sesión cancelado.';

  @override
  String get authLoginFailed =>
      'No se pudo iniciar sesión. Inténtalo de nuevo.';

  @override
  String get authRegisterFailed =>
      'No se pudo crear tu cuenta. Inténtalo de nuevo.';

  @override
  String get authNoAccountToDelete =>
      'No hay una cuenta con sesión iniciada para eliminar.';

  @override
  String get authNoEmailToVerify => 'No hay un correo para verificar.';

  @override
  String get authRequiresRecentLogin =>
      'Vuelve a iniciar sesión para continuar.';

  @override
  String get authFacebookMissingToken =>
      'No se pudo iniciar sesión con Facebook. Inténtalo de nuevo.';

  @override
  String get authAppleMissingToken =>
      'No se pudo iniciar sesión con Apple. Inténtalo de nuevo.';

  @override
  String get authFailed => 'Error de autenticación. Inténtalo de nuevo.';

  @override
  String get claimProofOfficialEmail =>
      'Correo oficial (coincide con el dominio del lugar)';

  @override
  String get claimProofVenueWebsite => 'Enlace al sitio web del lugar';

  @override
  String get claimProofContract => 'Contrato o confirmación de reserva';

  @override
  String get claimProofPressContact => 'Contacto de prensa';

  @override
  String get eventCreationGuide => 'Guía para crear eventos';

  @override
  String get eventCreationGuideTooltip => 'Cómo crear un evento';

  @override
  String get eventCreationGuideCardTitle => 'Crea con confianza';

  @override
  String get eventCreationGuideCardBody =>
      'Sigue la lista rápida y compara exactamente lo que incluyen Gratis y Premium.';

  @override
  String get eventCreationGuideMediaSummary =>
      'Gratis: 1 foto de portada + 1 video corto. Premium: hasta 5 fotos en total (incluida la portada) + 3 videos cortos.';

  @override
  String get openEventCreationGuide => 'Abrir guía para creadores';

  @override
  String get eventCreationGuideIntro =>
      'Una lista simple para publicar un evento claro y listo para compartir.';

  @override
  String get eventCreationGuideCurrentPlan => 'Tu plan actual';

  @override
  String get eventCreationGuideFreeActive => 'Plan gratis';

  @override
  String get eventCreationGuidePremiumActive => 'Premium activo';

  @override
  String get eventCreationGuideAdminAccess =>
      'Acceso de prueba de administrador';

  @override
  String get eventCreationGuideDetailsTitle => '1. Empieza con los detalles';

  @override
  String get eventCreationGuideDetailsBody =>
      'Agrega un título y una descripción claros; luego confirma la fecha y hora de inicio y finalización, venue, ubicación y precio del boleto. Deja el precio en blanco si el evento es gratis.';

  @override
  String get eventCreationGuideVisualsTitle => '2. Hazlo visual';

  @override
  String get eventCreationGuideVisualsBody =>
      'Elige primero una foto de portada. Los creadores Premium pueden generar un fondo promocional con IA. Poster Studio crea un póster separado para compartir con el título, fecha, hora, venue y precio exactos de este formulario.';

  @override
  String get eventCreationGuideMediaTitle => '3. Agrega medios según tu plan';

  @override
  String get eventCreationGuidePlanIntro =>
      'La foto de portada cuenta como la foto 1. Cada video debe durar 30 segundos o menos y pesar menos de 50 MB.';

  @override
  String get eventCreationGuideFreeEvents =>
      'Hasta 2 eventos únicos próximos a la vez';

  @override
  String get eventCreationGuideFreeMedia =>
      '1 foto de portada en total y 1 video corto por evento';

  @override
  String get eventCreationGuideFreePublish =>
      'Página básica del evento con enlaces públicos del organizador en el feed público';

  @override
  String get eventCreationGuidePremiumEvents =>
      'Eventos ilimitados, incluidos eventos recurrentes semanales o mensuales';

  @override
  String get eventCreationGuidePremiumMedia =>
      'Hasta 5 fotos en total (incluida la portada) y 3 videos cortos por evento';

  @override
  String get eventCreationGuidePremiumTools =>
      'Fondos promocionales con IA, analíticas, marca personalizada y enlaces de contacto';

  @override
  String get eventCreationGuideSharedTools =>
      'Ambos planes permiten publicar los detalles principales, agregar enlaces públicos del organizador, agregar una portada y usar Poster Studio para crear un póster para compartir. Los fondos promocionales con IA son una herramienta para creadores Premium.';

  @override
  String get eventCreationGuideAdminNote =>
      'Tu cuenta de administrador puede probar el límite completo de 5 fotos y 3 videos, además de todas las herramientas de creador sin suscripción.';

  @override
  String get eventCreationGuideReviewTitle => '4. Revisa, publica y comparte';

  @override
  String get eventCreationGuideReviewBody =>
      'Revisa cada detalle antes de publicar. Si después cambias el título, fecha, hora, venue o precio, vuelve a abrir Poster Studio para crear un póster actualizado.';

  @override
  String get eventCreationGuideExplorePremium => 'Explorar Premium';

  @override
  String get eventCreationGuideStart => 'Empezar a crear';

  @override
  String get notificationTestTitle => 'Probar notificaciones';

  @override
  String get notificationTestBody =>
      'Envía una alerta de prueba para confirmar que las notificaciones funcionan en este dispositivo.';

  @override
  String get sendTestNotification => 'Enviar notificación de prueba';

  @override
  String get notificationTestAlertTitle =>
      'Las notificaciones de SpotVibe funcionan';

  @override
  String get notificationTestAlertBody =>
      'Esta es una notificación de prueba que solicitaste.';

  @override
  String get notificationTestSent =>
      'Notificación de prueba enviada. Revisa la bandeja de notificaciones.';

  @override
  String get notificationPermissionNeeded =>
      'Las notificaciones de SpotVibe están desactivadas. Actívalas en Configuración para probarlas.';

  @override
  String get notificationTestFailed =>
      'No pudimos enviar una notificación de prueba. Inténtalo de nuevo.';

  @override
  String get openSettings => 'Abrir configuración';

  @override
  String get eventStarts => 'Empieza';

  @override
  String get eventEnds => 'Termina';

  @override
  String get endTimeHint =>
      'Indica la hora real de finalización. Tu evento seguirá visible como En curso hasta entonces.';

  @override
  String get endTimeMustBeAfterStart =>
      'La fecha y hora de finalización deben ser posteriores al inicio.';

  @override
  String get endTimeRequired =>
      'Elige una hora de finalización antes de publicar.';

  @override
  String get selectEndTime => 'Elegir hora';

  @override
  String get happeningNow => 'En curso ahora';

  @override
  String get editProfile => 'Editar perfil';

  @override
  String get profileNameLabel => 'Nombre de empresa u organizador';

  @override
  String get profileNameHint => 'p. ej., SpotVibe';

  @override
  String get profileNameHelp =>
      'Este nombre aparece en tu perfil y en los eventos que creas.';

  @override
  String get updateExistingEventNames =>
      'Actualizar este nombre en los eventos que ya publiqué';

  @override
  String get profileNameRequired =>
      'Ingresa un nombre de empresa u organizador.';

  @override
  String get profileNameTooLong =>
      'El nombre debe tener 100 caracteres o menos.';

  @override
  String get profileUpdated => 'Perfil actualizado.';

  @override
  String get askSpotVibe => 'Pregúntale a SpotVibe';

  @override
  String get askSpotVibeSubtitle =>
      'Describe lo que quieres hacer y encuentra eventos locales reales, con opciones de viaje por carretera.';

  @override
  String get askSpotVibeSignIn =>
      'Inicia sesión para recibir recomendaciones de eventos reales.';

  @override
  String get aiSearchIntro =>
      'Cuéntame qué estás buscando. Lo convertiré en una búsqueda y mostraré solo eventos reales de SpotVibe y Ticketmaster.';

  @override
  String get aiSearchRealResults =>
      'SpotVibe interpreta tu solicitud. Los nombres, fechas, precios y disponibilidad siempre provienen de eventos reales.';

  @override
  String get aiSearchRoadTrips =>
      'Incluir viajes a ciudades cercanas (hasta 4 horas)';

  @override
  String get aiSearchRoadTripsHint =>
      'Opcional: busca coincidencias reales en ciudades regionales seleccionadas. Confirma las indicaciones y el tiempo de viaje antes de salir.';

  @override
  String get aiSearchTryPrompt => 'Prueba una de estas opciones';

  @override
  String get aiSearchPromptMusic => 'Música en vivo este fin de semana';

  @override
  String get aiSearchPromptFamily => 'Eventos familiares mañana';

  @override
  String get aiSearchPromptFood => 'Eventos de comida y bebida esta semana';

  @override
  String get aiSearchHint =>
      'p. ej., comedia el viernes, arte al aire libre o jazz en vivo';

  @override
  String get aiSearchEmptyQuery => 'Dile a SpotVibe qué quieres encontrar.';

  @override
  String get aiSearchSearching => 'Buscando eventos reales…';

  @override
  String get aiSearchFoundRealResults =>
      'Estos son eventos reales que coinciden con tu solicitud.';

  @override
  String get aiSearchNoResults =>
      'No se encontraron eventos activos que coincidan. Prueba una solicitud más amplia u otra fecha.';

  @override
  String aiSearchLocalResults(String location) {
    return 'Cerca de $location';
  }

  @override
  String aiSearchRoadTripResults(String location) {
    return 'Opciones de viaje en $location';
  }

  @override
  String get aiSearchNoResultsHere =>
      'No se encontraron eventos activos que coincidan en esta zona.';

  @override
  String get poweredByJamBase => 'Con tecnología de JamBase';

  @override
  String get viewOnJamBase => 'Ver en JamBase';

  @override
  String get navDiscover => 'Descubrir';

  @override
  String get navGems => 'Joyas';

  @override
  String get navMap => 'Mapa';

  @override
  String get gemsTitle => 'Joyas Ocultas';

  @override
  String get gemsSubtitle =>
      'Lugares locales pasados por alto que vale la pena descubrir';

  @override
  String get gemsSearchHint => 'Buscar una ciudad';

  @override
  String get gemsUseMyLocation => 'Usar mi ubicación';

  @override
  String gemsShowingIn(String area) {
    return 'Mostrando joyas en $area';
  }

  @override
  String get gemsAllCategories => 'Todas';

  @override
  String get gemsEmptyTitle => 'Aún no hay joyas por aquí';

  @override
  String get gemsEmptySubtitle =>
      'Sé la primera persona en compartir una joya escondida en esta zona.';

  @override
  String get gemsAttribution => 'Compartido por la comunidad de SpotVibe';

  @override
  String get gemsGoodToKnow => 'Bueno saberlo';

  @override
  String get gemsDirections => 'Cómo llegar';

  @override
  String get gemsWebsite => 'Sitio web';

  @override
  String get gemsAddButton => 'Agregar joya';

  @override
  String get gemsAddTitle => 'Agregar una joya escondida';

  @override
  String get gemsSignInToAdd => 'Inicia sesión para agregar una joya';

  @override
  String get gemsSignInToInteract =>
      'Inicia sesión para dar me gusta y comentar';

  @override
  String get gemNameLabel => 'Nombre';

  @override
  String get gemNameHint => 'p. ej. mirador del Cañón McKelligon';

  @override
  String get gemCategoryLabel => 'Categoría';

  @override
  String get gemSummaryLabel => 'Por qué es una joya';

  @override
  String get gemSummaryHint =>
      'Una línea sobre lo que hace especial a este lugar';

  @override
  String get gemDescriptionLabel => 'Descripción';

  @override
  String get gemDescriptionHint =>
      'Consejos, mejor hora para visitar, cómo llegar…';

  @override
  String get gemLocationLabel => 'Ubicación';

  @override
  String get gemLocationHint => 'Ciudad, barrio o punto de referencia';

  @override
  String get gemUsePreciseLocation => 'Usar mi ubicación actual';

  @override
  String get gemLocationCaptured => 'Ubicación precisa registrada';

  @override
  String get gemLocationNeeded =>
      'Agrega una ubicación para que otros la encuentren';

  @override
  String get gemPhotosLabel => 'Fotos';

  @override
  String get gemAddPhoto => 'Agregar foto';

  @override
  String get gemPhotosOptional => 'Las fotos son opcionales';

  @override
  String get gemSubmit => 'Compartir joya';

  @override
  String get gemSubmitting => 'Compartiendo…';

  @override
  String get gemSubmitSuccess => 'Tu joya está publicada. ¡Gracias por compartir!';

  @override
  String get gemSubmitRejected =>
      'No se pudo publicar tu joya porque podría infringir nuestras normas comunitarias.';

  @override
  String get gemSubmitError => 'Algo salió mal. Inténtalo de nuevo.';

  @override
  String get gemNameRequired => 'Agrega un nombre';

  @override
  String get gemSummaryRequired => 'Agrega un resumen breve';

  @override
  String get gemLocationRequired => 'Agrega una ubicación';

  @override
  String gemLikes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count me gusta',
      one: '1 me gusta',
      zero: 'Sin me gusta',
    );
    return _temp0;
  }

  @override
  String gemComments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count comentarios',
      one: '1 comentario',
      zero: 'Sin comentarios',
    );
    return _temp0;
  }

  @override
  String get gemCommentHint => 'Agrega un comentario…';

  @override
  String get gemCommentPost => 'Publicar';

  @override
  String get gemCommentEmpty => 'Sé la primera persona en comentar';

  @override
  String get gemCommentRejected =>
      'No se pudo publicar tu comentario porque podría infringir nuestras normas comunitarias.';

  @override
  String get gemCommentError =>
      'No se pudo publicar tu comentario. Inténtalo de nuevo.';

  @override
  String gemAddedBy(String name) {
    return 'Agregado por $name';
  }

  @override
  String get gemDelete => 'Eliminar joya';

  @override
  String get gemDeleteConfirm => '¿Eliminar esta joya? No se puede deshacer.';

  @override
  String get gemDeleted => 'Joya eliminada';

  @override
  String get gemReport => 'Reportar';

  @override
  String get gemsEditTitle => 'Editar joya escondida';

  @override
  String get gemEdit => 'Editar joya';

  @override
  String get gemUpdate => 'Guardar cambios';

  @override
  String get gemUpdating => 'Guardando…';

  @override
  String get gemUpdateSuccess => 'Tus cambios se guardaron.';

  @override
  String get gemUpdateRejected =>
      'No se pudieron guardar tus cambios porque podrían infringir nuestras normas de la comunidad.';

  @override
  String get adminGems => 'Joyas';

  @override
  String get adminNoGems => 'No hay joyas para moderar';

  @override
  String get adminSearchGemsHint => 'Buscar joyas';

  @override
  String get gemHide => 'Ocultar';

  @override
  String get gemUnhide => 'Mostrar';

  @override
  String get gemHidden => 'Joya oculta';

  @override
  String get gemUnhidden => 'Joya visible de nuevo';

  @override
  String get gemHiddenBadge => 'Oculta';

  @override
  String get mapTitle => 'Mapa';

  @override
  String get mapResetView => 'Restablecer vista';

  @override
  String get mapViewEvent => 'Ver evento';

  @override
  String get mapViewGem => 'Ver joya';

  @override
  String mapEventsLayer(int count) {
    return '$count eventos';
  }

  @override
  String mapGemsLayer(int count) {
    return '$count joyas';
  }
}
