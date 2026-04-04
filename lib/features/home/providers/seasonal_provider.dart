import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Configuración del banner estacional, gestionada desde Supabase.
/// Tabla: seasonal_widget_config  (is_active = true → fila vigente)
class SeasonalConfig {
  final String title;
  final String subtitle;
  final List<String> seasonalTerms;

  const SeasonalConfig({
    required this.title,
    required this.subtitle,
    required this.seasonalTerms,
  });

  /// Valores por defecto cuando no hay configuración activa o falla la lectura.
  static const fallback = SeasonalConfig(
    title: 'Productos de temporada',
    subtitle: 'Descubre productos frescos según el momento del año',
    seasonalTerms: [],
  );
}

/// Lee la fila activa de [seasonal_widget_config].
/// Si no existe o hay error, devuelve [SeasonalConfig.fallback] — nunca lanza.
final seasonalConfigProvider =
    FutureProvider.autoDispose<SeasonalConfig>((ref) async {
  try {
    final data = await Supabase.instance.client
        .from('seasonal_widget_config')
        .select('title, subtitle, seasonal_terms')
        .eq('is_active', true)
        .order('updated_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (data == null) return SeasonalConfig.fallback;

    return SeasonalConfig(
      title: (data['title'] as String?)?.trim().isNotEmpty == true
          ? data['title'] as String
          : SeasonalConfig.fallback.title,
      subtitle: (data['subtitle'] as String?)?.trim().isNotEmpty == true
          ? data['subtitle'] as String
          : SeasonalConfig.fallback.subtitle,
      seasonalTerms: (data['seasonal_terms'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  } catch (_) {
    return SeasonalConfig.fallback;
  }
});
