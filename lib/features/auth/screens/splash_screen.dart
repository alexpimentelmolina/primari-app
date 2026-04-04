import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _weAnim;
  late final Animation<double> _areAnim;
  late final Animation<double> _primariAnim;

  static const _kBg       = Color(0xFFF9F7EB);
  static const _kWe       = Color(0xFFEDD16F);
  static const _kAre      = Color(0xFFC1DBDA);
  static const _kPrimari  = Color(0xFF628474);
  static const _kFooter   = Color(0xFF1A1C1A);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // "we" → 0–300 ms
    _weAnim = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.00, 0.25, curve: Curves.easeOut),
    );
    // "are" → 220–580 ms (overlap ligero con "we")
    _areAnim = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.18, 0.48, curve: Curves.easeOut),
    );
    // "Prímari" → 440–880 ms
    _primariAnim = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.37, 0.73, curve: Curves.easeOut),
    );

    _ctrl.forward();
    _goHome();
  }

  Future<void> _goHome() async {
    // Animación termina ~880 ms + hold ~920 ms = 1800 ms total
    await Future.delayed(const Duration(milliseconds: 1800));
    if (mounted) context.go('/home');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _word(String text, Color color, bool italic, Animation<double> anim) {
    return AnimatedBuilder(
      animation: anim,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, 10 * (1 - anim.value)),
        child: Opacity(
          opacity: anim.value,
          child: Text(
            text,
            style: GoogleFonts.notoSerif(
              fontSize: 44,
              fontWeight: FontWeight.w400,
              fontStyle: italic ? FontStyle.italic : FontStyle.normal,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          // Composición central: we · are · Prímari
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                _word('we', _kWe, true, _weAnim),
                const SizedBox(width: 10),
                _word('are', _kAre, true, _areAnim),
                const SizedBox(width: 14),
                _word('Prímari', _kPrimari, false, _primariAnim),
              ],
            ),
          ),
          // Footer
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Text(
              'Prímari ©',
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: _kFooter.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
