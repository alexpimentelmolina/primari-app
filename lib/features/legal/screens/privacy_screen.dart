import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: AppTheme.onSurface,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Política de Privacidad',
          style: GoogleFonts.manrope(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.onSurface,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _title('POLÍTICA DE PRIVACIDAD'),
              _subtitle('Plataforma Prímari — weareprimari.com'),
              _meta('Última actualización: 02 de abril de 2026'),
              const SizedBox(height: 24),

              _section('1. Introducción',
                  'La presente Política de Privacidad tiene por objeto informar a los usuarios de la plataforma Prímari (en adelante, «la Plataforma»), accesible a través del sitio web weareprimari.com y de la aplicación móvil para iOS, sobre el tratamiento de sus datos personales de conformidad con el Reglamento (UE) 2016/679 del Parlamento Europeo y del Consejo, de 27 de abril de 2016, relativo a la protección de las personas físicas en lo que respecta al tratamiento de datos personales (en adelante, «RGPD»), y con la Ley Orgánica 3/2018, de 5 de diciembre, de Protección de Datos Personales y garantía de los derechos digitales (en adelante, «LOPDGDD»).\n\nPrímari es un marketplace del sector primario (productos agrícolas, ganaderos y artesanales) que conecta a productores y vendedores con compradores finales. La Plataforma actúa exclusivamente como intermediaria tecnológica: no gestiona pagos, no gestiona envíos, no dispone de mensajería interna y no interviene en los acuerdos que puedan alcanzarse entre los usuarios.'),

              _section('2. Responsable del tratamiento',
                  'Responsable: ALEX PIMENTEL MOLINA\nNIF: 73660428F\nDomicilio: Calle Gerardo Ferrando 4\nCorreo electrónico: info@weareprimari.com\nSitio web: weareprimari.com'),

              _section('3. Datos personales que recogemos',
                  '3.1. Datos de autenticación\n\nPara crear una cuenta en la Plataforma, se recogen los siguientes datos según el método de registro utilizado:\n\n— Registro con email: dirección de correo electrónico y contraseña (cifrada).\n— Google Sign-In (OAuth2): nombre y dirección de correo electrónico proporcionados por Google LLC.\n— Apple Sign-In (OAuth nativo iOS): nombre y dirección de correo electrónico proporcionados por Apple Inc.\n\n3.2. Datos de perfil del usuario\n\nUna vez registrado, el usuario puede completar voluntariamente su perfil con la siguiente información (salvo el correo electrónico, que es obligatorio):\n\n— Nombre visible (display_name) — Voluntario\n— Teléfono — Voluntario\n— Ciudad — Voluntario\n— Código postal — Voluntario\n— Dirección física, con visibilidad configurable por el usuario — Voluntario\n— Foto de perfil (avatar_url) — Voluntario\n— Biografía personal — Voluntario\n— Tipo de cuenta (vendedor o comprador) — Obligatorio\n\n3.3. Datos generados por el uso de la Plataforma\n\nDurante la utilización de la Plataforma, se generan y almacenan los siguientes datos:\n\n— Productos publicados: título, descripción, precio, categoría, imágenes y localización aproximada.\n— Imágenes de productos: fotografías subidas por el usuario.\n— Favoritos: productos guardados por el usuario.\n— Reseñas: valoraciones escritas por usuarios sobre otros usuarios.\n— Reportes de contenido: motivo y descripción del reporte realizado.'),

              _section('4. Finalidad del tratamiento',
                  '— Gestión de la cuenta: crear, mantener y administrar la cuenta del usuario en la Plataforma.\n— Prestación del servicio: permitir la publicación y búsqueda de productos, la interacción entre usuarios (favoritos, reseñas) y la visualización de perfiles públicos.\n— Contacto entre usuarios: facilitar que compradores y vendedores se pongan en contacto a través de medios externos (WhatsApp). Prímari no almacena ni gestiona dichas conversaciones.\n— Moderación de contenido: revisar reportes de productos y conductas contrarias a las normas de uso de la Plataforma.\n— Seguridad y trazabilidad: mantener registros de auditoría para garantizar la seguridad de la Plataforma y cumplir obligaciones legales.\n— Mejora del servicio: analizar el uso agregado de la Plataforma para mejorar su funcionamiento y la experiencia del usuario.'),

              _section('5. Base legal del tratamiento',
                  '— Ejecución de contrato (art. 6.1.b RGPD): el tratamiento es necesario para la prestación del servicio contratado por el usuario al registrarse en la Plataforma: gestión de la cuenta, publicación de productos, funcionamiento del marketplace.\n— Consentimiento (art. 6.1.a RGPD): para el tratamiento de datos voluntarios del perfil (teléfono, dirección, biografía, foto de perfil) y para la autenticación mediante proveedores externos (Google Sign-In, Apple Sign-In).\n— Interés legítimo (art. 6.1.f RGPD): para la moderación de contenidos, la prevención de fraudes, la seguridad de la Plataforma y el mantenimiento de registros de auditoría.\n— Obligación legal (art. 6.1.c RGPD): para la conservación de datos que resulten exigibles conforme a la normativa vigente.'),

              _section('6. Plazo de conservación de los datos',
                  '— Cuenta activa: los datos se conservan mientras la cuenta del usuario permanezca activa.\n— Eliminación de cuenta: al eliminar la cuenta, se suprimen el perfil del usuario, las imágenes almacenadas y los registros asociados. Los productos publicados quedan en estado «soft delete» (eliminados lógicamente) con fines de trazabilidad interna.\n— Registro de auditoría: se conserva un registro (user_id, email, display_name, account_type y fecha de eliminación) durante un plazo máximo de 3 años desde la eliminación, salvo que una obligación legal exija un plazo superior.\n— Obligaciones legales: los datos podrán conservarse durante los plazos legalmente establecidos, incluso tras la eliminación de la cuenta, en cumplimiento de la normativa aplicable.'),

              _section('7. Destinatarios y transferencias internacionales de datos',
                  '7.1. Encargados del tratamiento y terceros\n\n— Supabase, Inc. (supabase.com): base de datos PostgreSQL, autenticación de usuarios y almacenamiento de imágenes. Servidores de AWS, región UE. Garantías: cláusulas contractuales tipo (SCC) y cumplimiento del RGPD.\n— Google LLC: autenticación OAuth2 (Google Sign-In). Garantías: Data Privacy Framework (DPF) UE-EE. UU. y cláusulas contractuales tipo.\n— Apple Inc.: autenticación nativa iOS (Apple Sign-In). Garantías: Data Privacy Framework (DPF) UE-EE. UU. y cláusulas contractuales tipo.\n— IONOS SE: hosting web (weareprimari.com). Servidores en la UE. Garantías: cumplimiento del RGPD.\n\n7.2. Transferencias internacionales\n\nAlgunos de los prestadores indicados pueden tratar datos fuera del Espacio Económico Europeo (EEE). En tales casos, las transferencias se realizan con las garantías adecuadas conforme al Capítulo V del RGPD, incluyendo el marco del Data Privacy Framework (DPF) entre la UE y EE. UU. y/o cláusulas contractuales tipo aprobadas por la Comisión Europea.\n\n7.3. Comunicación externa entre usuarios\n\nEl contacto entre compradores y vendedores se produce de manera externa a la Plataforma, a través de un enlace a WhatsApp (servicio de Meta Platforms, Inc.). Prímari no gestiona, no almacena ni tiene acceso a las conversaciones mantenidas entre usuarios fuera de la Plataforma. El uso de WhatsApp está sujeto a los términos y la política de privacidad de Meta Platforms, Inc.'),

              _section('8. Derechos del usuario',
                  '— Acceso (art. 15 RGPD): obtener confirmación de si se están tratando sus datos y, en su caso, acceder a ellos.\n— Rectificación (art. 16 RGPD): solicitar la corrección de datos inexactos o incompletos.\n— Supresión (art. 17 RGPD): solicitar la eliminación de sus datos cuando ya no sean necesarios, se retire el consentimiento o el tratamiento sea ilícito.\n— Limitación (art. 18 RGPD): solicitar la limitación del tratamiento en determinadas circunstancias previstas en el RGPD.\n— Portabilidad (art. 20 RGPD): recibir sus datos en un formato estructurado, de uso común y lectura mecánica, y transmitirlos a otro responsable.\n— Oposición (art. 21 RGPD): oponerse al tratamiento de sus datos cuando se base en el interés legítimo del responsable.\n— Revocación del consentimiento: retirar en cualquier momento el consentimiento prestado, sin que ello afecte a la licitud del tratamiento previo.\n\n8.1. Cómo ejercer los derechos\n\nEl usuario podrá ejercer cualquiera de los derechos anteriores dirigiéndose al responsable del tratamiento a través del siguiente correo electrónico: info@weareprimari.com\n\nLa solicitud deberá incluir el nombre completo del usuario, su dirección de correo electrónico asociada a la cuenta y una descripción del derecho que desea ejercer. El responsable responderá en el plazo máximo de un mes desde la recepción de la solicitud, conforme al artículo 12.3 del RGPD.\n\nAsimismo, el usuario tiene derecho a presentar una reclamación ante la Agencia Española de Protección de Datos (AEPD), con sede en C/ Jorge Juan, 6, 28001 Madrid, y sitio web www.aepd.es, si considera que el tratamiento de sus datos vulnera la normativa vigente.'),

              _section('9. Uso de cookies',
                  'La versión web de la Plataforma (weareprimari.com) puede utilizar cookies técnicas o de sesión estrictamente necesarias para el funcionamiento del servicio, como la gestión de la autenticación del usuario.\n\nEstas cookies son necesarias para el correcto funcionamiento de la Plataforma y no requieren el consentimiento del usuario conforme al artículo 22.2 de la Ley 34/2002, de 11 de julio, de servicios de la sociedad de la información y de comercio electrónico (LSSI-CE), ya que están exentas por ser imprescindibles para la prestación del servicio.\n\nLa Plataforma no utiliza cookies de análisis, publicitarias ni de seguimiento de terceros. En caso de que en el futuro se implementen cookies adicionales, se actualizará la presente política y se solicitará el consentimiento del usuario cuando sea legalmente exigible.'),

              _section('10. Eliminación de cuenta y conservación de datos',
                  'El usuario puede solicitar en cualquier momento la eliminación de su cuenta desde la propia Plataforma. Al proceder a la eliminación:\n\na) Se eliminan de forma definitiva el perfil del usuario, las imágenes almacenadas en el servicio de almacenamiento (Storage) y los registros directamente asociados a la cuenta.\nb) Los productos publicados por el usuario se mantienen en estado de eliminación lógica («soft delete») con fines de trazabilidad interna, sin que sean visibles para otros usuarios.\nc) Se genera un registro de auditoría que conserva únicamente: identificador de usuario, dirección de correo electrónico, nombre visible, tipo de cuenta y fecha de eliminación.\n\nEste registro de auditoría se conserva durante un plazo máximo de tres (3) años desde la fecha de eliminación de la cuenta, salvo que una obligación legal exija su conservación durante un periodo superior. La base legal para esta conservación es el interés legítimo del responsable (art. 6.1.f RGPD) en materia de seguridad, prevención de fraudes y cumplimiento normativo.'),

              _section('11. Medidas de seguridad',
                  'Prímari aplica las medidas técnicas y organizativas apropiadas para proteger los datos personales frente a su pérdida, uso indebido, acceso no autorizado, divulgación, alteración o destrucción, de conformidad con el artículo 32 del RGPD. Entre otras:\n\n— Cifrado de contraseñas en el almacenamiento.\n— Transmisión de datos mediante protocolo seguro (HTTPS/TLS).\n— Control de acceso a la base de datos y al almacenamiento de imágenes.\n— Uso de proveedores de infraestructura que cumplen con el RGPD y disponen de certificaciones de seguridad reconocidas.'),

              _section('12. Datos de menores de edad',
                  'La Plataforma no está dirigida a menores de dieciséis (16) años, de conformidad con el artículo 8 del RGPD y el artículo 7 de la LOPDGDD. Prímari no recoge intencionadamente datos personales de menores de dicha edad. Si el responsable tuviera conocimiento de que se han recogido datos de un menor sin el consentimiento de su representante legal, procederá a su eliminación inmediata.'),

              _section('13. Modificaciones de la política de privacidad',
                  'Prímari se reserva el derecho a modificar la presente Política de Privacidad en cualquier momento para adaptarla a novedades legislativas, jurisprudenciales o a cambios en el funcionamiento de la Plataforma. Las modificaciones se publicarán en la Plataforma con indicación de la fecha de la última actualización.\n\nEn caso de que las modificaciones afecten de forma sustancial al tratamiento de datos personales, se informará al usuario a través de los medios disponibles en la Plataforma.'),

              _section('14. Contacto',
                  'Para cualquier consulta relacionada con la presente Política de Privacidad o con el tratamiento de sus datos personales, el usuario puede dirigirse al responsable del tratamiento a través de:\n\ninfo@weareprimari.com'),

              _section('15. Legislación aplicable',
                  'La presente Política de Privacidad se rige por el Reglamento (UE) 2016/679 (RGPD), la Ley Orgánica 3/2018 de Protección de Datos Personales y garantía de los derechos digitales (LOPDGDD), la Ley 34/2002 de servicios de la sociedad de la información y de comercio electrónico (LSSI-CE), y cualesquiera otras normas españolas y europeas que resulten de aplicación.'),

              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _title(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: SelectableText(
          text,
          style: GoogleFonts.notoSerif(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.onSurface,
            height: 1.3,
          ),
        ),
      );

  Widget _subtitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: SelectableText(
          text,
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.primary,
          ),
        ),
      );

  Widget _meta(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: SelectableText(
          text,
          style: GoogleFonts.manrope(
            fontSize: 12,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
      );

  Widget _section(String heading, String body) => Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(
              heading,
              style: GoogleFonts.manrope(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurface,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            SelectableText(
              body,
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: AppTheme.onSurface,
                height: 1.65,
              ),
            ),
          ],
        ),
      );
}
