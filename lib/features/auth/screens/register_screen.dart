import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  bool _obscurePassword = true;
  bool _isIndividual = true;
  bool _acceptedTerms = false;
  bool _isLoading = false;
  bool _emailSent = false;
  String? _error;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _traducirError(String msg) {
    if (msg.contains('User already registered') ||
        msg.contains('already been registered')) {
      return 'Ya existe una cuenta con este email.';
    }
    if (msg.contains('Password should be at least')) {
      return 'La contraseña debe tener al menos 6 caracteres.';
    }
    if (msg.contains('invalid email') ||
        msg.contains('Unable to validate email')) {
      return 'El formato del email no es válido.';
    }
    return msg;
  }

  Future<void> _handleRegister() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Completa todos los campos.');
      return;
    }
    if (!_acceptedTerms) {
      setState(
          () => _error = 'Acepta los términos para continuar.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ref.read(authServiceProvider).signUp(
            email: email,
            password: password,
          );

      if (response.session != null) {
        // Sesión activa inmediata → router redirige a /completar-perfil
      } else {
        // Supabase requiere confirmación por email
        setState(() => _emailSent = true);
      }
    } on AuthException catch (e) {
      setState(() => _error = _traducirError(e.message));
    } catch (_) {
      setState(() => _error = 'Error inesperado. Inténtalo de nuevo.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: LayoutBuilder(
        builder: (ctx, constraints) {
          final isWide = constraints.maxWidth > 768;
          if (isWide) {
            return Row(
              children: [
                const Expanded(child: _LeftPanel()),
                Expanded(
                  child: _FormPanel(
                    emailController: _emailController,
                    passwordController: _passwordController,
                    obscurePassword: _obscurePassword,
                    isIndividual: _isIndividual,
                    acceptedTerms: _acceptedTerms,
                    isLoading: _isLoading,
                    emailSent: _emailSent,
                    error: _error,
                    onTogglePassword: () => setState(
                        () => _obscurePassword = !_obscurePassword),
                    onToggleAccountType: (v) =>
                        setState(() => _isIndividual = v),
                    onTermsChanged: (val) =>
                        setState(() => _acceptedTerms = val ?? false),
                    onRegister: _handleRegister,
                  ),
                ),
              ],
            );
          } else {
            return _FormPanel(
              emailController: _emailController,
              passwordController: _passwordController,
              obscurePassword: _obscurePassword,
              isIndividual: _isIndividual,
              acceptedTerms: _acceptedTerms,
              isLoading: _isLoading,
              emailSent: _emailSent,
              error: _error,
              onTogglePassword: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              onToggleAccountType: (v) =>
                  setState(() => _isIndividual = v),
              onTermsChanged: (val) =>
                  setState(() => _acceptedTerms = val ?? false),
              onRegister: _handleRegister,
            );
          }
        },
      ),
    );
  }
}

class _LeftPanel extends StatelessWidget {
  const _LeftPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.secondaryContainer,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'The Digital Provenance',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.onSecondaryContainer,
                ),
              ),
            ),
            const SizedBox(height: 32),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Arraigado en la\n',
                    style: GoogleFonts.notoSerif(
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                      height: 1.1,
                    ),
                  ),
                  TextSpan(
                    text: 'Autenticidad.',
                    style: GoogleFonts.notoSerif(
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                      color: AppTheme.secondary,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Únete a nuestra comunidad de productores artesanales y consumidores conscientes que valoran la calidad y el origen local.',
              style: GoogleFonts.manrope(
                fontSize: 16,
                color: AppTheme.onSurfaceVariant,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 48),
            Row(
              children: [
                Expanded(
                  child: _FeatureCard(
                    icon: Icons.eco,
                    title: 'Sostenible',
                    description:
                        'Productos cultivados con respeto por el medio ambiente.',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _FeatureCard(
                    icon: Icons.handshake,
                    title: 'Artesanal',
                    description:
                        'Elaborado con dedicación y técnicas tradicionales.',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primary, size: 28),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.notoSerif(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
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
    );
  }
}

class _FormPanel extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool isIndividual;
  final bool acceptedTerms;
  final bool isLoading;
  final bool emailSent;
  final String? error;
  final VoidCallback onTogglePassword;
  final void Function(bool individual) onToggleAccountType;
  final ValueChanged<bool?> onTermsChanged;
  final VoidCallback onRegister;

  const _FormPanel({
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.isIndividual,
    required this.acceptedTerms,
    required this.isLoading,
    required this.emailSent,
    required this.error,
    required this.onTogglePassword,
    required this.onToggleAccountType,
    required this.onTermsChanged,
    required this.onRegister,
  });

  static InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.manrope(
        fontSize: 14,
        color: AppTheme.onSurfaceVariant,
      ),
      filled: true,
      fillColor: AppTheme.surfaceContainerHighest,
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
    return Container(
      color: Colors.white,
      child: Center(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: emailSent
                ? _EmailSentView(email: emailController.text.trim())
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Prímari',
                        style: GoogleFonts.notoSerif(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 48,
                        height: 3,
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Crea tu cuenta',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.notoSerif(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Elige tu camino en el marketplace',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 32),
                      _AccountTypeSwitcher(
                        isIndividual: isIndividual,
                        onToggle: onToggleAccountType,
                      ),
                      const SizedBox(height: 40),
                      _FieldLabel(label: 'CORREO ELECTRÓNICO'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration:
                            _fieldDecoration('correo@ejemplo.com'),
                        style: GoogleFonts.manrope(fontSize: 14),
                      ),
                      const SizedBox(height: 24),
                      _FieldLabel(label: 'CONTRASEÑA'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: passwordController,
                        obscureText: obscurePassword,
                        decoration:
                            _fieldDecoration('••••••••').copyWith(
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
                      const SizedBox(height: 24),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Checkbox(
                            value: acceptedTerms,
                            activeColor: AppTheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            onChanged: onTermsChanged,
                          ),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: GoogleFonts.manrope(
                                  fontSize: 13,
                                  color: AppTheme.onSurface,
                                ),
                                children: [
                                  const TextSpan(text: 'Acepto los '),
                                  TextSpan(
                                    text: 'Términos de uso',
                                    style: GoogleFonts.manrope(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primary,
                                      decoration: TextDecoration.underline,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () => context.push('/terminos'),
                                  ),
                                  const TextSpan(text: ' y '),
                                  TextSpan(
                                    text: 'Política de privacidad',
                                    style: GoogleFonts.manrope(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primary,
                                      decoration: TextDecoration.underline,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () => context.push('/privacidad'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (error != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.error.withAlpha(20),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: AppTheme.error.withAlpha(80)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline,
                                  color: AppTheme.error, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  error!,
                                  style: GoogleFonts.manrope(
                                    fontSize: 13,
                                    color: AppTheme.error,
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
                        child: ElevatedButton.icon(
                          onPressed: isLoading ? null : onRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                AppTheme.primary.withAlpha(120),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(
                                vertical: 20),
                            elevation: 4,
                            shadowColor:
                                AppTheme.primary.withAlpha(100),
                          ),
                          icon: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.arrow_forward,
                                  size: 20),
                          label: Text(
                            'Crear cuenta',
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
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
                              const TextSpan(text: '¿Ya tienes cuenta? '),
                              WidgetSpan(
                                child: GestureDetector(
                                  onTap: () => context.go('/login'),
                                  child: Text(
                                    'Inicia sesión',
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
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          const Expanded(
                              child: Divider(
                                  color: AppTheme.outlineVariant)),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16),
                            child: Text(
                              'Hecho para la comunidad',
                              style: GoogleFonts.manrope(
                                fontSize: 11,
                                color: AppTheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          const Expanded(
                              child: Divider(
                                  color: AppTheme.outlineVariant)),
                        ],
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _EmailSentView extends StatelessWidget {
  final String email;
  const _EmailSentView({required this.email});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.mark_email_unread_outlined,
            size: 64, color: AppTheme.primary),
        const SizedBox(height: 24),
        Text(
          'Revisa tu correo',
          style: GoogleFonts.notoSerif(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Te hemos enviado un enlace de confirmación a:',
          textAlign: TextAlign.center,
          style: GoogleFonts.manrope(
            fontSize: 14,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          email,
          textAlign: TextAlign.center,
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.onSurface,
          ),
        ),
        const SizedBox(height: 32),
        TextButton(
          onPressed: () => context.go('/login'),
          child: Text(
            'Volver al inicio de sesión',
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}

class _AccountTypeSwitcher extends StatelessWidget {
  final bool isIndividual;
  final void Function(bool individual) onToggle;

  const _AccountTypeSwitcher({
    required this.isIndividual,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => onToggle(true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isIndividual ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isIndividual
                      ? [
                          BoxShadow(
                            color: Colors.black.withAlpha(26),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : [],
                ),
                child: Text(
                  'Individual',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isIndividual
                        ? AppTheme.primary
                        : AppTheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => onToggle(false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color:
                      !isIndividual ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: !isIndividual
                      ? [
                          BoxShadow(
                            color: Colors.black.withAlpha(26),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : [],
                ),
                child: Text(
                  'Empresa',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: !isIndividual
                        ? AppTheme.primary
                        : AppTheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: GoogleFonts.manrope(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppTheme.onSurface,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
