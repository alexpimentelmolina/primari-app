import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/profile_provider.dart';
import '../../../shared/widgets/bottom_nav.dart';
import '../../products/providers/products_provider.dart';
import '../../reviews/providers/reviews_provider.dart';

class MyProfileScreen extends ConsumerWidget {
  const MyProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return profileAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: Text('Error al cargar perfil',
              style: GoogleFonts.manrope(color: AppTheme.error)),
        ),
      ),
      data: (profile) {
        final displayName = profile?.displayName ?? 'Sin nombre';
        final city = profile?.city ?? '';
        final isBusiness = profile?.accountType == 'business';

        Future<void> handleLogout() async {
          await ref.read(authServiceProvider).signOut();
          // RouterNotifier detecta signout y redirige
        }

        return Scaffold(
          backgroundColor: AppTheme.background,
          extendBodyBehindAppBar: true,
          appBar: _FrostedAppBar(),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 96),
                _ProfileHeader(
                  displayName: displayName,
                  city: city,
                  isBusiness: isBusiness,
                  avatarUrl: profile?.avatarUrl,
                ),
                const SizedBox(height: 40),
                _NavigationGrid(onLogout: handleLogout),
                const SizedBox(height: 32),
                _StatsBento(),
                const SizedBox(height: 32),
              ],
            ),
          ),
          bottomNavigationBar: const BottomNav(currentIndex: 3),
        );
      },
    );
  }
}

class _FrostedAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          color: AppTheme.background.withAlpha(179),
          child: SafeArea(
            child: SizedBox(
              height: 72,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    Text(
                      'Prímari',
                      style: GoogleFonts.notoSerif(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends ConsumerStatefulWidget {
  final String displayName;
  final String city;
  final bool isBusiness;
  final String? avatarUrl;

  const _ProfileHeader({
    required this.displayName,
    required this.city,
    required this.isBusiness,
    this.avatarUrl,
  });

  @override
  ConsumerState<_ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends ConsumerState<_ProfileHeader> {
  bool _uploading = false;
  final _picker = ImagePicker();

  Future<void> _pickAndUpload() async {
    if (_uploading) return;
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 85,
    );
    if (file == null || !mounted) return;

    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return;

    setState(() => _uploading = true);
    try {
      final url = await ref
          .read(profileServiceProvider)
          .uploadAvatar(file, userId);
      await ref.read(profileProvider.notifier).updateAvatar(url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo subir la foto. Inténtalo de nuevo.',
                style: GoogleFonts.manrope()),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = widget.displayName;
    final city = widget.city;
    final isBusiness = widget.isBusiness;
    final avatarUrl = widget.avatarUrl;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.surfaceContainer,
                  width: 4,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 64,
                    backgroundImage: avatarUrl != null
                        ? NetworkImage(avatarUrl) as ImageProvider
                        : null,
                    onBackgroundImageError:
                        avatarUrl != null ? (err, st) {} : null,
                    backgroundColor: AppTheme.surfaceContainerHigh,
                    child: avatarUrl == null
                        ? Text(
                            displayName.isNotEmpty
                                ? displayName[0].toUpperCase()
                                : '?',
                            style: GoogleFonts.notoSerif(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                          )
                        : null,
                  ),
                  if (_uploading)
                    const CircleAvatar(
                      radius: 64,
                      backgroundColor: Color(0x80000000),
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 3),
                    ),
                ],
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _pickAndUpload,
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.primary,
                  child: const Icon(
                    Icons.edit,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          displayName,
          style: GoogleFonts.notoSerif(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppTheme.onSurface,
          ),
        ),
        if (city.isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_on,
                  size: 14, color: AppTheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                city.toUpperCase(),
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  letterSpacing: 1.2,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.tertiaryFixed,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isBusiness ? Icons.business : Icons.eco,
                size: 14,
                color: AppTheme.tertiary,
              ),
              const SizedBox(width: 8),
              Text(
                isBusiness ? 'EMPRESA VERIFICADA' : 'PRODUCTOR VERIFICADO',
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.tertiary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NavigationGrid extends StatelessWidget {
  final VoidCallback onLogout;

  const _NavigationGrid({required this.onLogout});

  void _showContactDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceContainerLow,
        title: Text(
          'Contacto',
          style: GoogleFonts.notoSerif(
            fontWeight: FontWeight.w600,
            color: AppTheme.onSurface,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Para cualquier consulta, escríbenos a:',
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            SelectableText(
              'info@weareprimari.com',
              style: GoogleFonts.manrope(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.primary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cerrar',
              style: GoogleFonts.manrope(color: AppTheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _NavItem(
          circleColor: AppTheme.primaryContainer,
          icon: Icons.inventory_2,
          title: 'Mis productos',
          subtitle: 'Artículos publicados',
          onTap: () => context.push('/mis-productos'),
        ),
        const SizedBox(height: 12),
        _NavItem(
          circleColor: AppTheme.secondaryContainer,
          icon: Icons.favorite,
          title: 'Mis favoritos',
          subtitle: 'Tesoros guardados',
          onTap: () => context.push('/favoritos'),
        ),
        const SizedBox(height: 12),
        _NavItem(
          circleColor: AppTheme.surfaceVariant,
          icon: Icons.settings,
          title: 'Configuración',
          subtitle: 'Cuenta y notificaciones',
          onTap: () => context.push('/configuracion'),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'AYUDA',
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
        ),
        _NavItem(
          circleColor: AppTheme.surfaceVariant,
          icon: Icons.mail_outline,
          title: 'Contacto',
          subtitle: 'info@weareprimari.com',
          onTap: () => _showContactDialog(context),
        ),
        const SizedBox(height: 12),
        _NavItem(
          circleColor: AppTheme.surfaceVariant,
          icon: Icons.description_outlined,
          title: 'Aviso legal',
          subtitle: 'Términos y privacidad',
          onTap: () => context.push('/aviso-legal'),
        ),
        const SizedBox(height: 12),
        _LogoutNavItem(onLogout: onLogout),
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  final Color circleColor;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _NavItem({
    required this.circleColor,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isWebMobile = kIsWeb && MediaQuery.of(context).size.width < 600;
    final cardPadding = isWebMobile ? 14.0 : 24.0;
    final iconSize = isWebMobile ? 40.0 : 48.0;
    final gap = isWebMobile ? 12.0 : 20.0;
    final titleFontSize = isWebMobile ? 14.0 : 16.0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(cardPadding),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                color: circleColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppTheme.primary, size: 22),
            ),
            SizedBox(width: gap),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.notoSerif(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppTheme.outline, size: 22),
          ],
        ),
      ),
    );
  }
}

class _LogoutNavItem extends StatelessWidget {
  final VoidCallback onLogout;

  const _LogoutNavItem({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final isWebMobile = kIsWeb && MediaQuery.of(context).size.width < 600;
    final cardPadding = isWebMobile ? 14.0 : 24.0;
    final gap = isWebMobile ? 12.0 : 20.0;
    final titleFontSize = isWebMobile ? 14.0 : 16.0;

    return InkWell(
      onTap: onLogout,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(cardPadding),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(Icons.logout, color: AppTheme.error, size: 22),
            SizedBox(width: gap),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cerrar sesión',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.notoSerif(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  Text(
                    'Salir de tu cuenta',
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      color: AppTheme.onSurfaceVariant,
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

class _StatsBento extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserProvider)?.id;
    final summaryAsync = userId != null
        ? ref.watch(sellerRatingSummaryProvider(userId))
        : null;
    final activeAsync = ref.watch(myActiveProductsProvider);

    final (avg, count) = summaryAsync?.valueOrNull ?? (0.0, 0);
    final ratingLabel = count == 0 ? '—' : avg.toStringAsFixed(1);
    final activeCount = activeAsync.valueOrNull?.length ?? 0;

    final isWebDesktop = kIsWeb && MediaQuery.of(context).size.width > 600;
    final statsRow = Row(
      children: [
        Expanded(
          child: AspectRatio(
            aspectRatio: 1,
            child: GestureDetector(
              onTap: () => context.push('/listados-activos'),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.inventory_2,
                        color: Colors.white, size: 32),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activeCount.toString(),
                          style: GoogleFonts.notoSerif(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'LISTADOS ACTIVOS',
                          style: GoogleFonts.manrope(
                            fontSize: 10,
                            color: Colors.white.withAlpha(204),
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AspectRatio(
            aspectRatio: 1,
            child: GestureDetector(
              onTap: userId != null
                  ? () => context.push('/vendedor/$userId/resenas')
                  : null,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryFixed,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.stars,
                        color: Color(0xFF2C1600), size: 32),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ratingLabel,
                          style: GoogleFonts.notoSerif(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2C1600),
                          ),
                        ),
                        Text(
                          count > 0 ? '$count RESEÑAS' : 'VALORACIÓN',
                          style: GoogleFonts.manrope(
                            fontSize: 10,
                            color: const Color(0xFF2C1600),
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
    if (isWebDesktop) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: statsRow,
        ),
      );
    }
    return statsRow;
  }
}
