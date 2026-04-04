import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/profile_provider.dart';
import '../../profile/models/profile.dart';

class CompleteProfileScreen extends ConsumerStatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  ConsumerState<CompleteProfileScreen> createState() =>
      _CompleteProfileScreenState();
}

class _CompleteProfileScreenState
    extends ConsumerState<CompleteProfileScreen> {
  bool _isBusiness = false;
  String _addressVisibility = 'city_only';
  bool _isLoading = false;
  String? _error;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _postalController = TextEditingController();
  final _addressController = TextEditingController();
  final _bioController = TextEditingController();
  int _bioChars = 0;

  @override
  void initState() {
    super.initState();
    _bioController.addListener(
        () => setState(() => _bioChars = _bioController.text.length));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _postalController.dispose();
    _addressController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final city = _cityController.text.trim();
    final postal = _postalController.text.trim();

    if (name.isEmpty || phone.isEmpty || city.isEmpty || postal.isEmpty) {
      setState(() => _error = 'Completa los campos obligatorios.');
      return;
    }

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final profile = Profile(
        id: user.id,
        accountType: _isBusiness ? 'business' : 'person',
        displayName: name,
        phone: phone,
        city: city,
        postalCode: postal,
        address: _isBusiness ? _addressController.text.trim() : null,
        addressVisibility: _addressVisibility,
        bio: _bioController.text.trim().isEmpty
            ? null
            : _bioController.text.trim(),
      );

      await ref.read(profileProvider.notifier).save(profile);
      // El RouterNotifier detecta el cambio y redirige a /home
    } catch (e) {
      setState(
          () => _error = 'Error al guardar el perfil. Inténtalo de nuevo.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSignOut() async {
    await ref.read(authServiceProvider).signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Prímari',
          style: GoogleFonts.notoSerif(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.primary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _handleSignOut,
            child: Text(
              'Cerrar sesión',
              style: GoogleFonts.manrope(
                fontSize: 13,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Completa tu perfil',
                  style: GoogleFonts.notoSerif(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Cuéntanos un poco sobre ti para empezar.',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),

                // Tipo de cuenta
                _SectionLabel(label: 'TIPO DE CUENTA'),
                const SizedBox(height: 12),
                _TypeSwitcher(
                  isBusiness: _isBusiness,
                  onToggle: (v) => setState(() => _isBusiness = v),
                ),
                const SizedBox(height: 32),

                // Nombre visible
                _FieldLabel(label: 'NOMBRE VISIBLE *'),
                const SizedBox(height: 8),
                _Field(
                  controller: _nameController,
                  hint: _isBusiness
                      ? 'Nombre de tu empresa'
                      : 'Tu nombre o apodo',
                ),
                const SizedBox(height: 24),

                // Teléfono
                _FieldLabel(label: 'TELÉFONO *'),
                const SizedBox(height: 8),
                _Field(
                  controller: _phoneController,
                  hint: '+34 600 000 000',
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'[0-9 +\-()]'))
                  ],
                ),
                const SizedBox(height: 24),

                // Ciudad
                _FieldLabel(label: 'CIUDAD *'),
                const SizedBox(height: 8),
                _Field(
                  controller: _cityController,
                  hint: 'Ej. Sevilla',
                ),
                const SizedBox(height: 24),

                // Código postal
                _FieldLabel(label: 'CÓDIGO POSTAL *'),
                const SizedBox(height: 8),
                _Field(
                  controller: _postalController,
                  hint: 'Ej. 41001',
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(5),
                  ],
                ),

                // Dirección (solo empresa)
                if (_isBusiness) ...[
                  const SizedBox(height: 24),
                  _FieldLabel(label: 'DIRECCIÓN'),
                  const SizedBox(height: 8),
                  _Field(
                    controller: _addressController,
                    hint: 'Calle, número, piso...',
                  ),
                ],

                // Visibilidad de dirección
                const SizedBox(height: 32),
                _SectionLabel(label: 'VISIBILIDAD DE UBICACIÓN'),
                const SizedBox(height: 8),
                Text(
                  'Elige qué información de tu ubicación ven otros usuarios.',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                _VisibilityPicker(
                  selected: _addressVisibility,
                  onChanged: (v) =>
                      setState(() => _addressVisibility = v),
                ),

                // Bio
                const SizedBox(height: 32),
                _FieldLabel(label: 'BIO'),
                const SizedBox(height: 8),
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    TextField(
                      controller: _bioController,
                      maxLength: 150,
                      maxLines: 3,
                      buildCounter: (ctx,
                              {required currentLength,
                              required isFocused,
                              maxLength}) =>
                          null,
                      decoration: _fieldDeco(
                          'Cuéntanos algo sobre ti o tu negocio...'),
                      style: GoogleFonts.manrope(fontSize: 14),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 12, bottom: 8),
                      child: Text(
                        '$_bioChars/150',
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          color: _bioChars > 140
                              ? AppTheme.error
                              : AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),

                // Error
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: AppTheme.error.withAlpha(80)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline,
                            color: AppTheme.error, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
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

                const SizedBox(height: 40),

                // Botón guardar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          AppTheme.primary.withAlpha(120),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Guardar y continuar',
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

InputDecoration _fieldDeco(String hint) => InputDecoration(
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

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final List<TextInputFormatter> inputFormatters;

  const _Field({
    required this.controller,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.inputFormatters = const [],
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: _fieldDeco(hint),
      style: GoogleFonts.manrope(fontSize: 14),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.manrope(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: AppTheme.secondary,
        letterSpacing: 1.4,
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.manrope(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: AppTheme.onSurface,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _TypeSwitcher extends StatelessWidget {
  final bool isBusiness;
  final void Function(bool) onToggle;

  const _TypeSwitcher({required this.isBusiness, required this.onToggle});

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
          _Tab(
              label: 'Persona',
              icon: Icons.person_outline,
              selected: !isBusiness,
              onTap: () => onToggle(false)),
          _Tab(
              label: 'Empresa',
              icon: Icons.business_outlined,
              selected: isBusiness,
              onTap: () => onToggle(true)),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _Tab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withAlpha(26),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16,
                  color:
                      selected ? AppTheme.primary : AppTheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color:
                      selected ? AppTheme.primary : AppTheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VisibilityPicker extends StatelessWidget {
  final String selected;
  final void Function(String) onChanged;

  static const _options = [
    ('exact', 'Dirección exacta', Icons.location_on),
    ('city_only', 'Solo ciudad', Icons.location_city),
    ('hidden', 'Oculta', Icons.visibility_off_outlined),
  ];

  const _VisibilityPicker(
      {required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _options.map((opt) {
        final (value, label, icon) = opt;
        final isSelected = selected == value;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onChanged(value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                    vertical: 12, horizontal: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryContainer.withAlpha(40)
                      : AppTheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primary
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(icon,
                        size: 20,
                        color: isSelected
                            ? AppTheme.primary
                            : AppTheme.onSurfaceVariant),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected
                            ? AppTheme.primary
                            : AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
