import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

final geocodingServiceProvider =
    Provider<GeocodingService>((ref) => GeocodingService());

/// Geocodificación con Nominatim (OpenStreetMap, gratuito, sin API key).
/// Uso: convertir ciudad / código postal en coordenadas (lat, lng).
class GeocodingService {
  static const _base = 'https://nominatim.openstreetmap.org';
  // Nominatim exige un User-Agent identificativo
  static const _userAgent = 'PrimariApp/1.0 (weareprimari.com)';

  /// Devuelve (lat, lng) o null si no se encuentra o hay error.
  /// [query] puede ser ciudad, código postal o combinación "28001, Madrid".
  Future<(double, double)?> geocode(
    String query, {
    String countryCode = 'es',
  }) async {
    final q = query.trim();
    if (q.isEmpty) return null;

    try {
      final uri = Uri.parse('$_base/search').replace(
        queryParameters: {
          'q': q,
          'format': 'json',
          'limit': '1',
          'countrycodes': countryCode,
        },
      );

      final response = await http
          .get(uri, headers: {
            'User-Agent': _userAgent,
            'Accept-Language': 'es',
          })
          .timeout(const Duration(seconds: 6));

      if (response.statusCode != 200) return null;

      final data = json.decode(response.body);
      if (data is! List || data.isEmpty) return null;

      final lat = double.tryParse(data[0]['lat'] as String? ?? '');
      final lng = double.tryParse(data[0]['lon'] as String? ?? '');
      if (lat == null || lng == null) return null;

      return (lat, lng);
    } catch (_) {
      // Rate limit, red caída, timeout → fallback silencioso
      return null;
    }
  }
}
