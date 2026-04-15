import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/providers/cookie_consent_provider.dart';
import '../../core/theme/app_theme.dart';

// ─── Overlay que se coloca encima del árbol de rutas ─────────────────────────
// Usado en main.dart dentro del builder de MaterialApp.router

class CookieBannerOverlay extends ConsumerWidget {
  const CookieBannerOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!kIsWeb) return const SizedBox.shrink();

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
                  decoration: TextDecoration.underline,
                  decorationColor: AppTheme.primary,
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
      onPressed: () => _showConfigSheet(context, notifier),
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

// ─── Sheet de configuración por categorías ────────────────────────────────────

void _showConfigSheet(BuildContext context, CookieConsentNotifier notifier) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CookieConfigSheet(notifier: notifier),
  );
}

class _CookieConfigSheet extends StatefulWidget {
  final CookieConsentNotifier notifier;
  const _CookieConfigSheet({required this.notifier});

  @override
  State<_CookieConfigSheet> createState() => _CookieConfigSheetState();
}

class _CookieConfigSheetState extends State<_CookieConfigSheet> {
  bool _analytics = false;
  bool _preferences = false;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      maxChildSize: 0.92,
      minChildSize: 0.45,
      builder: (_, sc) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.outlineVariant,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                controller: sc,
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                children: [
                  Text(
                    'Configurar cookies',
                    style: GoogleFonts.notoSerif(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Elige qué tipos de cookies permites. Puedes cambiar tu elección en cualquier momento desde Aviso legal.',
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      color: AppTheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),

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

                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      widget.notifier.saveCustom();
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                    ),
                    child: Text(
                      'Guardar preferencias',
                      style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () {
                      widget.notifier.accept();
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      'Aceptar todas',
                      style: GoogleFonts.manrope(color: AppTheme.primary),
                    ),
                  ),
                ],
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
