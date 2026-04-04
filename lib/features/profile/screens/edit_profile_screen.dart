import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/profile_provider.dart';
import '../models/profile.dart';
import '../services/delete_account_service.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _displayNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _postalCodeCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  String _addressVisibility = 'city_only';

  bool _initialized = false;
  bool _isLoading = false;
  bool _isDeletingAccount = false;
  String? _error;

  @override
  void dispose() {
    _displayNameCtrl.dispose();
    _phoneCtrl.dispose();
    _cityCtrl.dispose();
    _postalCodeCtrl.dispose();
    _addressCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  void _initFromProfile(Profile profile) {
    if (_initialized) return;
    _initialized = true;
    _displayNameCtrl.text = profile.displayName;
    _phoneCtrl.text = profile.phone;
    _cityCtrl.text = profile.city;
    _postalCodeCtrl.text = profile.postalCode;
    _addressCtrl.text = profile.address ?? '';
    _bioCtrl.text = profile.bio ?? '';
    _addressVisibility = profile.addressVisibility;
  }

  String? _validate() {
    if (_cityCtrl.text.trim().isEmpty) return 'La ciudad es obligatoria.';
    if (_postalCodeCtrl.text.trim().isEmpty) {
      return 'El código postal es obligatorio.';
    }
    if (_bioCtrl.text.length > 150) {
      return 'La bio no puede superar 150 caracteres.';
    }
    return null;
  }

  Future<void> _save(Profile current) async {
    final error = _validate();
    if (error != null) {
      setState(() => _error = error);
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final updated = Profile(
        id: current.id,
        accountType: current.accountType,
        displayName: _displayNameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        postalCode: _postalCodeCtrl.text.trim(),
        address: _addressCtrl.text.trim().isEmpty
            ? null
            : _addressCtrl.text.trim(),
        addressVisibility: _addressVisibility,
        avatarUrl: current.avatarUrl,
        bio: _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
        isActive: current.isActive,
      );
      await ref.read(profileProvider.notifier).save(updated);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        setState(
            () => _error = 'Error al guardar. Inténtalo de nuevo.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Eliminar cuenta',
          style: GoogleFonts.notoSerif(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.onSurface,
          ),
        ),
        content: Text(
          'Esta acción es irreversible. Se eliminarán tu perfil y todos tus productos publicados. ¿Estás seguro de que quieres continuar?',
          style: GoogleFonts.manrope(
            fontSize: 14,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancelar',
              style: GoogleFonts.manrope(color: AppTheme.onSurfaceVariant),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Eliminar',
              style: GoogleFonts.manrope(
                color: AppTheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isDeletingAccount = true);
    try {
      await DeleteAccountService().deleteAccount();
      // El usuario ya no existe en Auth: signOut local para limpiar la sesión.
      // Puede fallar si el JWT ya es inválido → se ignora silenciosamente.
      try {
        await Supabase.instance.client.auth.signOut();
      } catch (_) {}
      if (mounted) context.go('/login');
    } catch (e) {
      if (mounted) {
        final message = e is Exception
            ? e.toString().replaceFirst('Exception: ', '')
            : 'No se pudo eliminar la cuenta. Inténtalo de nuevo.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              message,
              style: GoogleFonts.manrope(),
            ),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDeletingAccount = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);

    return profileAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppTheme.background,
        body:
            Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      ),
      error: (e, st) => Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Text('Error al cargar perfil',
              style: GoogleFonts.manrope(color: AppTheme.error)),
        ),
      ),
      data: (profile) {
        if (profile == null) {
          return Scaffold(
            backgroundColor: AppTheme.background,
            body: Center(
              child: Text('Sin perfil',
                  style: GoogleFonts.manrope(
                      color: AppTheme.onSurfaceVariant)),
            ),
          );
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_initialized) setState(() => _initFromProfile(profile));
        });

        return Scaffold(
          backgroundColor: AppTheme.background,
          extendBodyBehindAppBar: true,
          appBar: _ProfileEditAppBar(
            onClose: () => context.pop(),
            isLoading: _isLoading,
            onSave: _isLoading ? null : () => _save(profile),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 88),
                // ── Datos personales ──────────────────────────────────
                const _SectionHeader(
                  title: 'Datos personales',
                  subtitle: 'Nombre visible y teléfono de contacto',
                ),
                const SizedBox(height: 16),
                _FormCard(
                  children: [
                    const _FieldLabel(label: 'NOMBRE VISIBLE'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _displayNameCtrl,
                      decoration: _fieldDeco(
                          'Tu nombre o nombre del negocio'),
                      style: GoogleFonts.manrope(fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    const _FieldLabel(label: 'TELÉFONO'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: _fieldDeco('+34 600 000 000'),
                      style: GoogleFonts.manrope(fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // ── Ubicación ─────────────────────────────────────────
                const _SectionHeader(
                  title: 'Ubicación',
                  subtitle:
                      'Indica dónde estás para que compradores te encuentren',
                ),
                const SizedBox(height: 16),
                _FormCard(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _FieldLabel(label: 'CIUDAD *'),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _cityCtrl,
                                decoration: _fieldDeco('Ej. Madrid'),
                                style: GoogleFonts.manrope(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _FieldLabel(label: 'CÓDIGO POSTAL *'),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _postalCodeCtrl,
                                keyboardType: TextInputType.number,
                                decoration: _fieldDeco('28001'),
                                style: GoogleFonts.manrope(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const _FieldLabel(label: 'DIRECCIÓN'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _addressCtrl,
                      decoration:
                          _fieldDeco('Calle, número... (opcional)'),
                      style: GoogleFonts.manrope(fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    const _FieldLabel(label: 'VISIBILIDAD DE DIRECCIÓN'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _addressVisibility,
                      decoration: _fieldDeco(''),
                      style: GoogleFonts.manrope(
                          fontSize: 14, color: AppTheme.onSurface),
                      items: const [
                        DropdownMenuItem(
                            value: 'city_only',
                            child: Text('Solo ciudad')),
                        DropdownMenuItem(
                            value: 'exact',
                            child: Text('Dirección exacta')),
                        DropdownMenuItem(
                            value: 'hidden', child: Text('Oculta')),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          setState(() => _addressVisibility = v);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // ── Bio ───────────────────────────────────────────────
                const _SectionHeader(
                  title: 'Sobre ti',
                  subtitle: 'Una breve descripción de tu actividad',
                ),
                const SizedBox(height: 16),
                _FormCard(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const _FieldLabel(label: 'BIO'),
                        Text(
                          '${_bioCtrl.text.length}/150',
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            color: _bioCtrl.text.length > 150
                                ? AppTheme.error
                                : AppTheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _bioCtrl,
                      maxLines: 4,
                      maxLength: 150,
                      onChanged: (_) => setState(() {}),
                      decoration: _fieldDeco(
                              'Cuéntanos brevemente quién eres y qué produces...')
                          .copyWith(counterText: ''),
                      style: GoogleFonts.manrope(fontSize: 14),
                    ),
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  _ErrorBanner(message: _error!),
                ],
                const SizedBox(height: 40),
                _DeleteAccountButton(
                  isLoading: _isDeletingAccount,
                  onTap: _isDeletingAccount ? null : _confirmDeleteAccount,
                ),
                const SizedBox(height: 120),
              ],
            ),
          ),
          bottomNavigationBar: _SaveBottomBar(
            onSave: _isLoading ? null : () => _save(profile),
            isLoading: _isLoading,
          ),
        );
      },
    );
  }
}

// ── AppBar ────────────────────────────────────────────────────────────────────

class _ProfileEditAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final VoidCallback onClose;
  final VoidCallback? onSave;
  final bool isLoading;

  const _ProfileEditAppBar({
    required this.onClose,
    required this.onSave,
    this.isLoading = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          color: AppTheme.background.withAlpha(204),
          child: SafeArea(
            child: SizedBox(
              height: 72,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      color: AppTheme.onSurface,
                      onPressed: onClose,
                    ),
                    const Spacer(),
                    Text(
                      'Editar perfil',
                      style: GoogleFonts.notoSerif(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                color: AppTheme.primary, strokeWidth: 2),
                          )
                        : TextButton(
                            onPressed: onSave,
                            style: TextButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 8),
                            ),
                            child: Text(
                              'Guardar',
                              style: GoogleFonts.manrope(
                                  fontWeight: FontWeight.bold),
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

// ── Save bottom bar ───────────────────────────────────────────────────────────

class _SaveBottomBar extends StatelessWidget {
  final VoidCallback? onSave;
  final bool isLoading;

  const _SaveBottomBar({required this.onSave, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: AppTheme.background,
        border: Border(
            top: BorderSide(color: AppTheme.outlineVariant, width: 1)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppTheme.primary.withAlpha(100),
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(vertical: 18),
          ),
          child: isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
              : Text(
                  'Guardar cambios',
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

InputDecoration _fieldDeco(String hint) => InputDecoration(
      hintText: hint,
      hintStyle:
          GoogleFonts.manrope(fontSize: 14, color: AppTheme.onSurfaceVariant),
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
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );

class _FormCard extends StatelessWidget {
  final List<Widget> children;
  const _FormCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.notoSerif(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: GoogleFonts.manrope(
            fontSize: 13,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: GoogleFonts.manrope(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppTheme.onSurface,
          letterSpacing: 1.2,
        ),
      );
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.error.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.error.withAlpha(80)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppTheme.error, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeleteAccountButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onTap;

  const _DeleteAccountButton({required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.error.withAlpha(12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.error.withAlpha(60)),
        ),
        child: Row(
          children: [
            if (isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: AppTheme.error, strokeWidth: 2),
              )
            else
              Icon(Icons.delete_forever_outlined,
                  color: AppTheme.error, size: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Eliminar cuenta',
                style: GoogleFonts.manrope(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
