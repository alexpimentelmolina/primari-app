import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

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
          'Términos y Condiciones',
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
              _title('TÉRMINOS Y CONDICIONES DE USO'),
              _subtitle('Plataforma Prímari — weareprimari.com'),
              _meta('Última actualización: 02 de abril de 2026'),
              const SizedBox(height: 24),

              _section('1. Objeto y descripción de la Plataforma',
                  'Los presentes Términos y Condiciones de Uso (en adelante, «los Términos») regulan el acceso y la utilización de la plataforma Prímari (en adelante, «la Plataforma»), accesible a través del sitio web weareprimari.com y de la aplicación móvil para iOS, titularidad de ALEX PIMENTEL MOLINA, con NIF 73660428F y domicilio en Calle Gerardo Ferrando 4 (en adelante, «Prímari»).\n\nPrímari es un marketplace del sector primario que conecta a productores y vendedores de productos agrícolas, ganaderos y artesanales con compradores finales.\n\nLa Plataforma actúa exclusivamente como intermediaria tecnológica, proporcionando un espacio digital donde los usuarios pueden publicar, buscar y localizar productos del sector primario. Prímari no interviene en las transacciones, acuerdos, negociaciones ni relaciones comerciales que puedan establecerse entre los usuarios. En particular:\n\na) Prímari no gestiona ni procesa pagos de ningún tipo.\nb) Prímari no gestiona envíos ni logística.\nc) Prímari no dispone de mensajería interna entre usuarios.\nd) Prímari no formaliza contratos entre compradores y vendedores.\ne) Prímari no verifica la identidad real de los usuarios ni la autenticidad, calidad o legalidad de los productos publicados.\nf) Prímari no actúa como vendedor en ningún caso.\n\nEl contacto entre compradores y vendedores se realiza de forma externa a la Plataforma, a través de un enlace a WhatsApp facilitado en el perfil o anuncio del vendedor.'),

              _section('2. Aceptación de los Términos',
                  'El acceso y uso de la Plataforma implican la aceptación plena e incondicional de los presentes Términos por parte del usuario. Si el usuario no está de acuerdo con alguna de las condiciones aquí establecidas, deberá abstenerse de utilizar la Plataforma.\n\nPrímari se reserva el derecho a modificar los presentes Términos en cualquier momento, siendo efectivas las modificaciones desde su publicación en la Plataforma. El uso continuado de la Plataforma tras la publicación de modificaciones constituirá la aceptación de las mismas.'),

              _section('3. Condiciones de registro y uso de la cuenta',
                  '3.1. Registro\n\nPara utilizar las funcionalidades de la Plataforma, el usuario debe crear una cuenta mediante uno de los siguientes métodos:\n\na) Registro con correo electrónico y contraseña.\nb) Registro mediante Google Sign-In (OAuth2).\nc) Registro mediante Apple Sign-In (disponible en la aplicación iOS).\n\n3.2. Requisitos del usuario\n\nEl usuario declara y garantiza que:\n\na) Es mayor de dieciséis (16) años de edad, o cuenta con la autorización de su representante legal.\nb) La información proporcionada durante el registro y en su perfil es veraz, actual y completa.\nc) Es responsable de mantener la confidencialidad de sus credenciales de acceso.\nd) Es responsable de toda actividad que se realice desde su cuenta.\n\n3.3. Tipo de cuenta\n\nAl registrarse, el usuario debe seleccionar un tipo de cuenta:\n\na) Vendedor: Puede publicar productos, gestionar su perfil público y recibir contacto de compradores a través de medios externos (WhatsApp).\nb) Comprador: Puede buscar y visualizar productos, guardar favoritos, contactar a vendedores de forma externa y escribir reseñas sobre otros usuarios.'),

              _section('4. Roles de los usuarios y de la Plataforma',
                  '4.1. Plataforma (Prímari)\n\nPrímari actúa como intermediaria tecnológica. Su función se limita a proporcionar la infraestructura técnica que permite la publicación y búsqueda de productos y la visualización de perfiles de usuarios. Prímari no es parte en las relaciones comerciales entre usuarios.\n\n4.2. Usuario vendedor\n\nEl usuario vendedor es responsable de la veracidad, legalidad y exactitud de la información y las imágenes publicadas en sus anuncios. Asimismo, es responsable del cumplimiento de la normativa aplicable a la venta de productos del sector primario, incluyendo, en su caso, la normativa sanitaria, fitosanitaria, de etiquetado y de seguridad alimentaria.\n\n4.3. Usuario comprador\n\nEl usuario comprador es responsable de verificar directamente con el vendedor las condiciones del producto, su precio, forma de entrega y cualquier otra circunstancia relevante antes de formalizar cualquier acuerdo.'),

              _section('5. Normas de publicación de productos',
                  '5.1. Contenido permitido\n\nLos usuarios vendedores podrán publicar anuncios de productos del sector primario, incluyendo productos agrícolas, ganaderos, artesanales y agroalimentarios. Cada anuncio podrá incluir: título, descripción, precio, categoría, imágenes y localización aproximada.\n\n5.2. Contenido prohibido\n\nQueda expresamente prohibida la publicación de:\n\na) Productos ilegales, falsificados, robados o cuya venta esté prohibida por la legislación vigente.\nb) Productos que no guarden relación con el sector primario o la temática de la Plataforma.\nc) Contenido ofensivo, difamatorio, discriminatorio, violento, sexual o que vulnere los derechos de terceros.\nd) Información falsa, engañosa o fraudulenta sobre productos o servicios.\ne) Datos personales de terceros sin su consentimiento.\nf) Contenido que infrinja derechos de propiedad intelectual o industrial de terceros.\ng) Spam, publicidad no solicitada o contenido repetitivo con fines promocionales ajenos a la Plataforma.\n\nPrímari se reserva el derecho a retirar cualquier anuncio que incumpla las presentes normas, sin previo aviso y sin que ello genere derecho a indemnización alguna.'),

              _section('6. Funcionamiento del marketplace',
                  'La Plataforma permite a los vendedores publicar anuncios de productos y a los compradores buscar, visualizar y guardar como favoritos dichos anuncios. Cuando un comprador desea contactar con un vendedor, se le redirige a un enlace externo de WhatsApp para que la comunicación se produzca fuera de la Plataforma.\n\nPrímari no participa, media ni es responsable de los acuerdos, negociaciones, compromisos, pagos, entregas, garantías, devoluciones ni de ninguna otra obligación derivada de la relación entre comprador y vendedor. Toda transacción se realiza bajo la exclusiva responsabilidad de las partes implicadas.'),

              _section('7. Reseñas',
                  '7.1. Normas de uso\n\nLos usuarios compradores pueden escribir reseñas sobre otros usuarios (vendedores) de la Plataforma. Las reseñas deben reflejar experiencias reales y respetar las siguientes normas:\n\na) Ser veraces, respetuosas y estar relacionadas con la experiencia de compra o interacción con el vendedor.\nb) No contener lenguaje ofensivo, difamatorio, discriminatorio, amenazante ni vulnerar los derechos de terceros.\nc) No incluir datos personales de terceros, contenido publicitario ni información falsa.\n\n7.2. Moderación\n\nPrímari se reserva el derecho a eliminar o moderar reseñas que incumplan las normas anteriores, sin previo aviso. La Plataforma no se responsabiliza del contenido de las reseñas publicadas por los usuarios, que reflejan únicamente la opinión de sus autores.'),

              _section('8. Reportes de contenido',
                  'Los usuarios pueden reportar productos que consideren que infringen los presentes Términos o la legislación vigente. Para ello, deberán indicar el motivo del reporte y una descripción del problema.\n\nPrímari revisará los reportes recibidos y podrá adoptar las medidas que considere oportunas, incluyendo la retirada del anuncio, la suspensión o eliminación de la cuenta del infractor, o la comunicación del hecho a las autoridades competentes.\n\nEl sistema de reportes está diseñado para colaborar en la integridad de la Plataforma. El uso abusivo o fraudulento del sistema de reportes podrá dar lugar a la suspensión de la cuenta del usuario que lo ejerza.'),

              _section('9. Conducta prohibida',
                  'Queda expresamente prohibido:\n\na) Utilizar la Plataforma para fines ilegales, fraudulentos o contrarios a los presentes Términos.\nb) Suplantar la identidad de otro usuario o de cualquier persona física o jurídica.\nc) Acceder, intentar acceder o interferir en cuentas, datos o sistemas de otros usuarios o de la Plataforma.\nd) Utilizar mecanismos automatizados (bots, scrapers, etc.) para acceder a la Plataforma o extraer datos de la misma.\ne) Publicar contenido que contenga virus, malware u otro código malicioso.\nf) Acosar, amenazar, difamar o discriminar a otros usuarios.\ng) Realizar prácticas que puedan dañar la reputación, el funcionamiento o la imagen de Prímari.\nh) Utilizar la Plataforma para fines distintos de los previstos en el presente documento (compraventa de productos del sector primario).\n\nEl incumplimiento de las presentes prohibiciones podrá dar lugar a la suspensión temporal o definitiva de la cuenta del usuario infractor, sin perjuicio de las acciones legales que pudieran corresponder.'),

              _section('10. Limitación de responsabilidad',
                  'Prímari, en su condición de intermediaria tecnológica, no será responsable de:\n\na) La veracidad, exactitud, legalidad, calidad o idoneidad de los productos publicados por los usuarios vendedores.\nb) El cumplimiento de las obligaciones asumidas entre compradores y vendedores, incluyendo pagos, entregas, devoluciones o garantías.\nc) Los daños y perjuicios de cualquier naturaleza derivados de las relaciones establecidas entre usuarios fuera de la Plataforma.\nd) El contenido de las comunicaciones mantenidas entre usuarios a través de medios externos (WhatsApp u otros).\ne) Las interrupciones, errores técnicos, virus o fallos de seguridad que puedan afectar a la Plataforma, salvo cuando sean directamente imputables a Prímari.\nf) La conducta de los usuarios en la Plataforma o fuera de ella.\ng) La verificación de la identidad real de los usuarios ni de la autenticidad de los productos.\n\nLa Plataforma se ofrece «tal cual» (as is) y «según disponibilidad» (as available). Prímari no garantiza la disponibilidad ininterrumpida ni la ausencia de errores en el funcionamiento de la Plataforma, y se reserva el derecho a suspender temporal o definitivamente el servicio por razones técnicas, de mantenimiento o de seguridad.'),

              _section('11. Eliminación de cuenta y efectos',
                  'El usuario puede eliminar su cuenta en cualquier momento desde la propia Plataforma. Asimismo, Prímari podrá suspender o eliminar la cuenta de un usuario en caso de incumplimiento de los presentes Términos, sin necesidad de previo aviso.\n\nAl eliminar la cuenta:\n\na) Se eliminarán el perfil del usuario, las imágenes almacenadas y los registros directamente asociados.\nb) Los productos publicados se mantendrán en estado de eliminación lógica («soft delete») con fines de trazabilidad interna, sin ser visibles para otros usuarios.\nc) Se conservará un registro de auditoría con datos mínimos (identificador, email, nombre visible, tipo de cuenta y fecha de eliminación) conforme a la Política de Privacidad.\n\nLa eliminación de la cuenta no exime al usuario de las responsabilidades u obligaciones contraídas con anterioridad frente a otros usuarios o frente a Prímari.'),

              _section('12. Propiedad intelectual',
                  '12.1. Propiedad de la Plataforma\n\nTodos los elementos de la Plataforma (diseño, código fuente, logotipos, marcas, textos, gráficos y demás contenidos) son propiedad de Prímari o de sus legítimos titulares, y están protegidos por la legislación española e internacional en materia de propiedad intelectual e industrial.\n\nQueda prohibida la reproducción, distribución, comunicación pública, transformación o cualquier otra forma de explotación de dichos elementos sin la autorización expresa y por escrito de Prímari.\n\n12.2. Contenidos subidos por los usuarios\n\nLos usuarios conservan la titularidad de los derechos de propiedad intelectual sobre los contenidos que suban a la Plataforma (imágenes de productos, textos descriptivos, reseñas, fotografía de perfil, biografía, etc.).\n\nAl subir contenido a la Plataforma, el usuario concede a Prímari una licencia no exclusiva, gratuita, mundial y por la duración del uso de la Plataforma, para reproducir, almacenar, mostrar y distribuir dicho contenido en el ámbito de la prestación del servicio. Esta licencia finalizará cuando el usuario elimine el contenido o su cuenta, salvo que la conservación sea necesaria por obligación legal o por razones de trazabilidad conforme a lo previsto en estos Términos.\n\nEl usuario declara y garantiza que es titular de los derechos de propiedad intelectual sobre los contenidos que sube, o que cuenta con las autorizaciones necesarias para ello, y que dichos contenidos no infringen derechos de terceros.'),

              _section('13. Enlaces a servicios externos',
                  'La Plataforma contiene enlaces a servicios de terceros, en particular a WhatsApp, para facilitar el contacto entre usuarios. Prímari no controla ni se responsabiliza del funcionamiento, contenido, políticas de privacidad o prácticas de servicios de terceros. El acceso y uso de dichos servicios se rige por sus propios términos y condiciones.'),

              _section('14. Protección de datos personales',
                  'El tratamiento de los datos personales de los usuarios se rige por la Política de Privacidad de Prímari, disponible en la propia Plataforma, que forma parte integrante de los presentes Términos. Se recomienda al usuario la lectura detenida de dicha política antes de utilizar la Plataforma.'),

              _section('15. Modificaciones de los Términos',
                  'Prímari se reserva el derecho a modificar los presentes Términos en cualquier momento para adaptarlos a cambios legislativos, jurisprudenciales o funcionales de la Plataforma. Las modificaciones entrarán en vigor desde su publicación en la Plataforma, con indicación de la fecha de la última actualización.\n\nEn caso de modificaciones sustanciales, Prímari informará a los usuarios a través de los medios disponibles en la Plataforma. El uso continuado de la Plataforma tras la publicación de los Términos modificados constituirá la aceptación de los mismos.'),

              _section('16. Nulidad parcial',
                  'Si alguna de las cláusulas de los presentes Términos fuese declarada nula o inaplicable por un tribunal competente, dicha nulidad no afectará a la validez del resto de cláusulas, que permanecerán en pleno vigor y efecto.'),

              _section('17. Ley aplicable y jurisdicción competente',
                  'Los presentes Términos se rigen e interpretan conforme a la legislación española.\n\nPara la resolución de cualquier controversia derivada del acceso o uso de la Plataforma o de la interpretación y aplicación de los presentes Términos, las partes se someten a los Juzgados y Tribunales del domicilio del usuario, siempre que este tenga la condición de consumidor conforme al Real Decreto Legislativo 1/2007, de 16 de noviembre, por el que se aprueba el texto refundido de la Ley General para la Defensa de los Consumidores y Usuarios. En caso contrario, las partes se someten a los Juzgados y Tribunales de Lliria.\n\nAsimismo, se informa al usuario consumidor de la existencia de la plataforma de resolución de litigios en línea de la Comisión Europea, accesible en https://ec.europa.eu/consumers/odr, a la que puede acudir como vía alternativa de resolución de conflictos.'),

              _section('18. Contacto',
                  'Para cualquier consulta relacionada con los presentes Términos, el usuario puede dirigirse a:\n\ninfo@weareprimari.com'),

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
