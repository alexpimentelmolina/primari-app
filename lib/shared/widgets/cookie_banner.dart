import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/providers/cookie_consent_provider.dart';
import '../../core/theme/app_theme.dart';

// ─── Overlay principal ────────────────────────────────────────────────────────
// Gestiona todo el estado internamente: no usa Navigator ni showDialog.
// - _ready: espera 2100 ms tras el inicio (el splash dura 1800 ms)
// - _configOpen: alterna entre el banner inferior y el panel de configuración

class CookieBannerOverlay extends ConsumerStatefulWidget {
  const CookieBannerOverlay({super.key});

  @override
  ConsumerState<CookieBannerOverlay> createState() =>
      _CookieBannerOverlayState();
}

class _CookieBannerOverlayState extends ConsumerState<CookieBannerOverlay> {
  bool _ready = false;
  bool _configOpen = false;

  @override
  void initState() {
    super.initState();
    // El splash dura exactamente 1800 ms. Esperamos 2100 ms para garantizar
    // que el banner nunca se superpone visualmente con la animación de splash.
    Future.delayed(const Duration(milliseconds: 2100), () {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb || !_ready) return const SizedBox.shrink();

    final consentAsync = ref.watch(cookieConsentProvider);
    return consentAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
      data: (consent) {
        if (consent != null) return const SizedBox.shrink();

        final notifier = ref.read(cookieConsentProvider.notifier);

        if (_configOpen) {
          // Panel de configuración: ocupa la pantalla completa con backdrop
          return _ConfigPanel(
            notifier: notifier,
            onClose: () => setState(() => _configOpen = false),
          );
        }

        // Banner en la parte inferior.
        // La columna ocupa toda el área del Stack; IgnorePointer en la zona
        // transparente superior garantiza que los eventos de puntero pasan
        // a través hacia el contenido de la página.
        return Column(
          children: [
            const Expanded(
              child: IgnorePointer(child: SizedBox.expand()),
            ),
            _CookieBanner(
              notifier: notifier,
              onConfigure: () => setState(() => _configOpen = true),
            ),
          ],
        );
      },
    );
  }
}

// ─── Banner inferior ──────────────────────────────────────────────────────────

class _CookieBanner extends StatelessWidget {
  final CookieConsentNotifier notifier;
  final VoidCallback onConfigure;
  const _CookieBanner({required this.notifier, required this.onConfigure});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 700;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        border: const Border(
          top: BorderSide(color: AppTheme.outlineVariant, width: 1),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 20,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isWide ? 40 : 20,
            vertical: 18,
          ),
          child: isWide
              ? _WideLayout(notifier: notifier, onConfigure: onConfigure)
              : _NarrowLayout(notifier: notifier, onConfigure: onConfigure),
        ),
      ),
    );
  }
}

// ─── Layout ancho (escritorio) ────────────────────────────────────────────────

class _WideLayout extends StatelessWidget {
  final CookieConsentNotifier notifier;
  final VoidCallback onConfigure;
  const _WideLayout({required this.notifier, required this.onConfigure});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(Icons.cookie_outlined, color: AppTheme.primary, size: 20),
        const SizedBox(width: 14),
        Expanded(child: _BannerText()),
        const SizedBox(width: 24),
        _ConfigureBtn(onTap: onConfigure),
        const SizedBox(width: 10),
        _RejectBtn(notifier: notifier),
        const SizedBox(width: 10),
        _AcceptBtn(notifier: notifier),
      ],
    );
  }
}

// ─── Layout estrecho (móvil web / tablet) ─────────────────────────────────────

class _NarrowLayout extends StatelessWidget {
  final CookieConsentNotifier notifier;
  final VoidCallback onConfigure;
  const _NarrowLayout({required this.notifier, required this.onConfigure});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.cookie_outlined, color: AppTheme.primary, size: 18),
            const SizedBox(width: 8),
            Text(
              'Cookies',
              style: GoogleFonts.notoSerif(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.onSurface,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _BannerText(),
        const SizedBox(height: 14),
        Row(
          children: [
            _ConfigureBtn(onTap: onConfigure),
            const Spacer(),
            _RejectBtn(notifier: notifier),
            const SizedBox(width: 8),
            _AcceptBtn(notifier: notifier),
          ],
        ),
      ],
    );
  }
}

// ─── Texto descriptivo ────────────────────────────────────────────────────────
// TextDecoration.none explícito en todos los TextSpan para evitar que el
// renderer web herede o aplique subrayado por defecto.

class _BannerText extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: GoogleFonts.manrope(
          fontSize: 13,
          color: AppTheme.onSurfaceVariant,
          height: 1.5,
          decoration: TextDecoration.none,
        ),
        children: [
          const TextSpan(
            text:
                'Usamos cookies esenciales para el funcionamiento de la plataforma y, con tu permiso, '
                'cookies opcionales para mejorar tu experiencia. ',
          ),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: InkWell(
              onTap: () => context.push('/privacidad'),
              overlayColor: WidgetStatePropertyAll(Colors.transparent),
              child: Text(
                'Política de privacidad',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Botones del banner ───────────────────────────────────────────────────────

class _AcceptBtn extends StatelessWidget {
  final CookieConsentNotifier notifier;
  const _AcceptBtn({required this.notifier});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: notifier.accept,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        elevation: 0,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        'Aceptar todas',
        style: GoogleFonts.manrope(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }
}

class _RejectBtn extends StatelessWidget {
  final CookieConsentNotifier notifier;
  const _RejectBtn({required this.notifier});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: notifier.reject,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.onSurface,
        side: const BorderSide(color: AppTheme.outlineVariant),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        'Rechazar',
        style: GoogleFonts.manrope(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }
}

class _ConfigureBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _ConfigureBtn({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        'Configurar',
        style: GoogleFonts.manrope(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppTheme.onSurfaceVariant,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }
}

// ─── Panel de configuración (autocontenido, sin Navigator) ────────────────────
// Ocupa la pantalla completa. No depende de showDialog ni showModalBottomSheet.

class _ConfigPanel extends StatefulWidget {
  final CookieConsentNotifier notifier;
  final VoidCallback onClose;
  const _ConfigPanel({required this.notifier, required this.onClose});

  @override
  State<_ConfigPanel> createState() => _ConfigPanelState();
}

class _ConfigPanelState extends State<_ConfigPanel> {
  bool _analytics = false;
  bool _preferences = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Backdrop oscuro: toca fuera para cerrar
        Positioned.fill(
          child: GestureDetector(
            onTap: widget.onClose,
            child: const ColoredBox(color: Color(0x88000000)),
          ),
        ),
        // Tarjeta de configuración: centrada, max 520 px de ancho
        Center(
          child: SingleChildScrollView(
            child: GestureDetector(
              onTap: () {}, // absorbe taps para no cerrar al tocar la tarjeta
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                constraints: const BoxConstraints(maxWidth: 520),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 40,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Cabecera ──────────────────────────────────────────
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              'Configurar cookies',
                              style: GoogleFonts.notoSerif(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.onSurface,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: widget.onClose,
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                Icons.close,
                                size: 20,
                                color: AppTheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Elige qué tipos de cookies permites. Puedes cambiar tu elección en cualquier momento desde Aviso legal.',
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          color: AppTheme.onSurfaceVariant,
                          height: 1.5,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Categorías ────────────────────────────────────────
                      _CookieCategory(
                        title: 'Cookies necesarias',
                        description:
                            'Imprescindibles para el funcionamiento de la plataforma: autenticación, sesión y seguridad. No pueden desactivarse.',
                        value: true,
                        locked: true,
                        onChanged: null,
                      ),
                      const Divider(height: 28, color: AppTheme.outlineVariant),
                      _CookieCategory(
                        title: 'Cookies de análisis',
                        description:
                            'Nos ayudan a entender cómo se usa la plataforma para mejorarla.',
                        value: _analytics,
                        locked: false,
                        onChanged: (v) => setState(() => _analytics = v),
                      ),
                      const Divider(height: 28, color: AppTheme.outlineVariant),
                      _CookieCategory(
                        title: 'Cookies de preferencias',
                        description:
                            'Guardan ajustes personales como filtros de búsqueda o configuraciones de visualización.',
                        value: _preferences,
                        locked: false,
                        onChanged: (v) => setState(() => _preferences = v),
                      ),
                      const SizedBox(height: 28),

                      // ── Botones de acción ─────────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            widget.notifier.saveCustom();
                            widget.onClose();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                          ),
                          child: Text(
                            'Guardar preferencias',
                            style: GoogleFonts.manrope(
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            widget.notifier.reject();
                            widget.onClose();
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.onSurface,
                            side: const BorderSide(
                                color: AppTheme.outlineVariant),
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            'Rechazar no esenciales',
                            style: GoogleFonts.manrope(
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () {
                            widget.notifier.accept();
                            widget.onClose();
                          },
                          child: Text(
                            'Aceptar todas',
                            style: GoogleFonts.manrope(
                              color: AppTheme.primary,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Fila de categoría de cookie ──────────────────────────────────────────────

class _CookieCategory extends StatelessWidget {
  final String title;
  final String description;
  final bool value;
  final bool locked;
  final ValueChanged<bool>? onChanged;

  const _CookieCategory({
    required this.title,
    required this.description,
    required this.value,
    required this.locked,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.notoSerif(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurface,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: AppTheme.onSurfaceVariant,
                  height: 1.5,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Switch(
          value: value,
          onChanged: locked ? null : onChanged,
          activeThumbColor: AppTheme.primary,
          inactiveThumbColor: AppTheme.outline,
          inactiveTrackColor: AppTheme.surfaceVariant,
        ),
      ],
    );
  }
}
