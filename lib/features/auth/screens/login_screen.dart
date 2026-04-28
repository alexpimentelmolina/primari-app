import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final String? errorParam;
  const LoginScreen({super.key, this.errorParam});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _error;
  bool _isSuspended = false;

  @override
  void initState() {
    super.initState();
    if (widget.errorParam == 'suspended') {
      _isSuspended = true;
      _error = 'Tu cuenta ha sido suspendida. Revisa tu correo electrónico o contacta con soporte en hola@weareprimari.com';
    }
  }

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  static const String _bgImageUrl =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuDk08OKBk_rd9HHhOA4NzW8mrN1rCEUlygG_u6CLhDKpTWSZZPuNx9Tzm7s3DJwTeLdwHkTPORDdQjZ29ev92hQ4ZX1O2M_xhXZl-GK_2ZGXRQvPbLI-3Aq4PMtpuLHUOrFtDTuAYac_-On_F5f-9_zHi3sW7vd9uIFEB_r3o07blqRiLYetPG1XM0jMtyOFzSAfuLNpAlfaAGqUwKwz0pHBz06uqCa-DWe1XkxLiIJzW-akKgCOlut8MCrpfZ8lfw7L2XP71BHPvv';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _traducirError(String msg) {
    if (msg.contains('Invalid login credentials')) {
      return 'Email o contraseña incorrectos.';
    }
    if (msg.contains('Email not confirmed')) {
      return 'Confirma tu email antes de iniciar sesión.';
    }
    if (msg.contains('Too many requests')) {
      return 'Demasiados intentos. Espera un momento.';
    }
    if (msg.contains('Unsupported provider') || msg.contains('provider is not enabled')) {
      return 'Este método de acceso todavía no está disponible.';
    }
    if (msg.contains('banned') || msg.contains('suspended')) {
      _isSuspended = true;
      return 'Tu cuenta ha sido suspendida. Revisa tu correo electrónico o contacta con soporte en hola@weareprimari.com';
    }
    return msg;
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      await ref.read(authServiceProvider).signInWithGoogle();
      // En web la página navega a Google y vuelve; Supabase procesa el token automáticamente.
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = _traducirError(e.message));
    } catch (_) {
      if (mounted) setState(() => _error = 'Error al conectar con Google. Inténtalo de nuevo.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAppleSignIn() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      await ref.read(authServiceProvider).signInWithApple();
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = _traducirError(e.message));
    } catch (_) {
      if (mounted) setState(() => _error = 'Error al conectar con Apple. Inténtalo de nuevo.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Completa todos los campos.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await ref.read(authServiceProvider).signIn(
            email: email,
            password: password,
          );
      // El RouterNotifier detecta el cambio de sesión y redirige
    } on AuthException catch (e) {
      setState(() => _error = _traducirError(e.message));
    } catch (_) {
      setState(() => _error = 'Error inesperado. Inténtalo de nuevo.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.manrope(
        fontSize: 14,
        color: AppTheme.onSurfaceVariant,
      ),
      filled: true,
      fillColor: AppTheme.surfaceContainerLow,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          LayoutBuilder(
            builder: (ctx, constraints) {
              final isWide = constraints.maxWidth > 768;
              if (isWide) {
                return Row(
                  children: [
                    Expanded(child: _LeftPanel(bgImageUrl: _bgImageUrl)),
                    Expanded(
                      child: _FormPanel(
                        emailController: _emailController,
                        passwordController: _passwordController,
                        obscurePassword: _obscurePassword,
                        onTogglePassword: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                        fieldDecoration: _fieldDecoration,
                        isLoading: _isLoading,
                        error: _error,
                        isSuspended: _isSuspended,
                        onLogin: _handleLogin,
                        onGoogleSignIn: _handleGoogleSignIn,
                        onAppleSignIn: _handleAppleSignIn,
                      ),
                    ),
                  ],
                );
              } else {
                return _FormPanel(
                  emailController: _emailController,
                  passwordController: _passwordController,
                  obscurePassword: _obscurePassword,
                  onTogglePassword: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  fieldDecoration: _fieldDecoration,
                  isLoading: _isLoading,
                  error: _error,
                  isSuspended: _isSuspended,
                  onLogin: _handleLogin,
                  onGoogleSignIn: _handleGoogleSignIn,
                  onAppleSignIn: _handleAppleSignIn,
                );
              }
            },
          ),
          const SafeArea(
            child: Padding(
              padding: EdgeInsets.all(8),
              child: _AuthBackButton(fallback: '/home'),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthBackButton extends StatelessWidget {
  final String fallback;
  const _AuthBackButton({required this.fallback});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.outlineVariant),
      ),
      child: IconButton(
        onPressed: () =>
            context.canPop() ? context.pop() : context.go(fallback),
        icon: const Icon(Icons.arrow_back_ios_new, size: 18),
        color: AppTheme.primary,
        tooltip: 'Volver',
      ),
    );
  }
}

class _LeftPanel extends StatelessWidget {
  final String bgImageUrl;
  const _LeftPanel({required this.bgImageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surfaceContainer,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Opacity(
            opacity: 0.1,
            child: Image.network(
              bgImageUrl,
              fit: BoxFit.cover,
              errorBuilder: (ctx, err, st) => const SizedBox.shrink(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'El valor de lo artesanal, en un solo lugar.',
                  style: GoogleFonts.notoSerif(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Conectamos a productores locales con consumidores que valoran la autenticidad y la calidad.',
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    color: AppTheme.onSurfaceVariant,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(153),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.eco,
                          size: 16, color: AppTheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        '100% Comunidad Local',
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FormPanel extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onTogglePassword;
  final InputDecoration Function(String hint) fieldDecoration;
  final bool isLoading;
  final String? error;
  final bool isSuspended;
  final VoidCallback onLogin;
  final VoidCallback onGoogleSignIn;
  final VoidCallback onAppleSignIn;

  const _FormPanel({
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onTogglePassword,
    required this.fieldDecoration,
    required this.isLoading,
    required this.error,
    required this.isSuspended,
    required this.onLogin,
    required this.onGoogleSignIn,
    required this.onAppleSignIn,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(48),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 448),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Prímari',
                  style: GoogleFonts.notoSerif(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Accede a tu cuenta para explorar productos artesanales.',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  'CORREO ELECTRÓNICO',
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.onSurface,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: fieldDecoration('ejemplo@correo.com'),
                  style: GoogleFonts.manrope(fontSize: 14),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'CONTRASEÑA',
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.onSurface,
                        letterSpacing: 1.2,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        '¿Olvidaste tu contraseña?',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          color: AppTheme.primaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  decoration: fieldDecoration('••••••••').copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: AppTheme.onSurfaceVariant,
                        size: 20,
                      ),
                      onPressed: onTogglePassword,
                    ),
                  ),
                  style: GoogleFonts.manrope(fontSize: 14),
                ),
                if (error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSuspended
                          ? const Color(0xFFFFF3CD)
                          : AppTheme.error.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: isSuspended
                              ? const Color(0xFFFFB300)
                              : AppTheme.error.withAlpha(80)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSuspended ? Icons.block : Icons.error_outline,
                          color: isSuspended
                              ? const Color(0xFFE65100)
                              : AppTheme.error,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            error!,
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              color: isSuspended
                                  ? const Color(0xFFE65100)
                                  : AppTheme.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : onLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          AppTheme.primary.withAlpha(120),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding:
                          const EdgeInsets.symmetric(vertical: 20),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Iniciar Sesión',
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Expanded(
                        child: Divider(color: AppTheme.outline)),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'o continúa con',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          color: AppTheme.outline,
                        ),
                      ),
                    ),
                    const Expanded(
                        child: Divider(color: AppTheme.outline)),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isLoading ? null : onGoogleSignIn,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: AppTheme.outlineVariant),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const _GoogleLogo(size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Google',
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isLoading ? null : onAppleSignIn,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: AppTheme.outlineVariant),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.apple,
                                size: 20, color: AppTheme.onSurface),
                            const SizedBox(width: 8),
                            Text(
                              'Apple',
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Center(
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        color: AppTheme.onSurfaceVariant,
                      ),
                      children: [
                        const TextSpan(text: '¿Aún no eres parte? '),
                        WidgetSpan(
                          child: GestureDetector(
                            onTap: () => context.go('/registro'),
                            child: Text(
                              'Crea una cuenta en Prímari',
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                              ),
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
        ),
      ),
    );
  }
}

// ── Logo oficial de Google (SVG embebido, sin red) ────────────────────────────

class _GoogleLogo extends StatelessWidget {
  final double size;
  const _GoogleLogo({this.size = 20});

  // SVG oficial de Google (viewBox 24×24) — mismo que usa "Sign in with Google"
  static const _svg = '''
<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
  <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/>
  <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
  <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"/>
  <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/>
</svg>
''';

  @override
  Widget build(BuildContext context) => SvgPicture.string(
        _svg,
        width: size,
        height: size,
      );
}
