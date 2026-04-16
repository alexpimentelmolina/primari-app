import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/providers/cookie_consent_provider.dart';
import '../../core/theme/app_theme.dart';

// ─── Overlay que se coloca encima del árbol de rutas ─────────────────────────
// Usado en main.dart dentro del builder de MaterialApp.router

class CookieBannerOverlay extends ConsumerStatefulWidget {
  const CookieBannerOverlay({super.key});

  @override
  ConsumerState<CookieBannerOverlay> createState() =>
      _CookieBannerOverlayState();
}

class _CookieBannerOverlayState extends ConsumerState<CookieBannerOverlay> {
  // The splash screen lasts ~1800 ms. We wait 2100 ms before allowing the
  // banner to render so it never overlaps visually with the splash animation.
  bool _ready = false;

  @override
  void initState() {
    super.initState();
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
      data: (consent) =>
          consent != null ? const SizedBox.shrink() : const _CookieBanner(),
    );
  }
}

// ─── Banner principal ─────────────────────────────────────────────────────────

class _CookieBanner extends ConsumerWidget {
  const _CookieBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(cookieConsentProvider.notifier);
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
              ? _WideLayout(notifier: notifier)
              : _NarrowLayout(notifier: notifier),
        ),
      ),
    );
  }
}

// ─── Layout ancho (escritorio) ────────────────────────────────────────────────

class _WideLayout extends StatelessWidget {
  final CookieConsentNotifier notifier;
  const _WideLayout({required this.notifier});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(Icons.cookie_outlined, color: AppTheme.primary, size: 20),
        const SizedBox(width: 14),
        Expanded(child: _BannerText()),
        const SizedBox(width: 24),
        _ConfigureBtn(notifier: notifier),
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
  const _NarrowLayout({required this.notifier});

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
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _BannerText(),
        const SizedBox(height: 14),
        Row(
          children: [
            _ConfigureBtn(notifier: notifier),
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

class _BannerText extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: GoogleFonts.manrope(
          fontSize: 13,
          color: AppTheme.onSurfaceVariant,
          height: 1.5,
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
            child: GestureDetector(
              onTap: () => context.push('/privacidad'),
              child: Text(
                'Política de privacidad',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Botones ──────────────────────────────────────────────────────────────────

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
        style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.bold),
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
        style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ConfigureBtn extends StatelessWidget {
  final CookieConsentNotifier notifier;
  const _ConfigureBtn({required this.notifier});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => _showConfigDialog(context, notifier),
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
        ),
      ),
    );
  }
}

// ─── Diálogo de configuración por categorías ─────────────────────────────────
// showDialog uses the root navigator and renders above the banner Stack.

void _showConfigDialog(BuildContext context, CookieConsentNotifier notifier) {
  showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) => _CookieConfigDialog(notifier: notifier),
  );
}

class _CookieConfigDialog extends StatefulWidget {
  final CookieConsentNotifier notifier;
  const _CookieConfigDialog({required this.notifier});

  @override
  State<_CookieConfigDialog> createState() => _CookieConfigDialogState();
}

class _CookieConfigDialogState extends State<_CookieConfigDialog> {
  bool _analytics = false;
  bool _preferences = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 0),
              child: Row(
                children: [
                  Text(
                    'Configurar cookies',
                    style: GoogleFonts.notoSerif(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    color: AppTheme.onSurfaceVariant,
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            // Scrollable body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Elige qué tipos de cookies permites. Puedes cambiar tu elección en cualquier momento desde Aviso legal.',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        color: AppTheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Necesarias (always on, locked)
                    _CookieCategory(
                      title: 'Cookies necesarias',
                      description:
                          'Imprescindibles para el funcionamiento de la plataforma: autenticación, sesión y seguridad. No pueden desactivarse.',
                      value: true,
                      locked: true,
                      onChanged: null,
                    ),
                    const Divider(height: 28, color: AppTheme.outlineVariant),
                    // Análisis (optional)
                    _CookieCategory(
                      title: 'Cookies de análisis',
                      description:
                          'Nos ayudan a entender cómo se usa la plataforma para mejorarla. Actualmente no empleamos cookies de análisis de terceros.',
                      value: _analytics,
                      locked: false,
                      onChanged: (v) => setState(() => _analytics = v),
                    ),
                    const Divider(height: 28, color: AppTheme.outlineVariant),
                    // Preferencias (optional)
                    _CookieCategory(
                      title: 'Cookies de preferencias',
                      description:
                          'Guardan ajustes personales como filtros de búsqueda o configuraciones de visualización.',
                      value: _preferences,
                      locked: false,
                      onChanged: (v) => setState(() => _preferences = v),
                    ),
                    const SizedBox(height: 28),
                    // ── Botones de acción ──────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          widget.notifier.saveCustom();
                          Navigator.of(context).pop();
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
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          widget.notifier.reject();
                          Navigator.of(context).pop();
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
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () {
                          widget.notifier.accept();
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          'Aceptar todas',
                          style: GoogleFonts.manrope(
                              color: AppTheme.primary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: AppTheme.onSurfaceVariant,
                  height: 1.5,
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
