import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/providers/cookie_consent_provider.dart';
import '../../../core/theme/app_theme.dart';

class AvisoLegalScreen extends StatelessWidget {
  const AvisoLegalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Aviso legal',
          style: GoogleFonts.notoSerif(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.onSurface,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _LegalItem(
              icon: Icons.article_outlined,
              title: 'Términos y condiciones',
              onTap: () => context.push('/terminos'),
            ),
            const SizedBox(height: 12),
            _LegalItem(
              icon: Icons.privacy_tip_outlined,
              title: 'Política de privacidad',
              onTap: () => context.push('/privacidad'),
            ),
            if (kIsWeb) ...[
              const SizedBox(height: 12),
              Consumer(
                builder: (context, ref, _) => _LegalItem(
                  icon: Icons.cookie_outlined,
                  title: 'Gestionar cookies',
                  onTap: () async {
                    await ref.read(cookieConsentProvider.notifier).reset();
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LegalItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _LegalItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppTheme.primary, size: 22),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.notoSerif(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurface,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: AppTheme.outline, size: 22),
          ],
        ),
      ),
    );
  }
}
