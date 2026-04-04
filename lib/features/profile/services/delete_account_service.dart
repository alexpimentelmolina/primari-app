import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DeleteAccountService {
  SupabaseClient get _client => Supabase.instance.client;

  Future<void> deleteAccount() async {
    final session = _client.auth.currentSession;

    debugPrint('[DELETE_ACCOUNT] session exists: ${session != null}');
    if (session == null) {
      debugPrint('[DELETE_ACCOUNT] no session');
      throw Exception('No hay sesión activa.');
    }

    final accessToken = session.accessToken;
    debugPrint('[DELETE_ACCOUNT] token length: ${accessToken.length}');
    debugPrint('[DELETE_ACCOUNT] invoking with auth token');

    try {
      final response = await _client.functions.invoke(
        'delete-account',
        method: HttpMethod.post,
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      debugPrint('[DELETE_ACCOUNT] status: ${response.status}');
      debugPrint('[DELETE_ACCOUNT] data: ${response.data}');

      if (response.status != 200) {
        final body = response.data;
        final message =
            (body is Map ? body['error'] : null) as String? ??
                'Error al eliminar la cuenta (código ${response.status}).';
        debugPrint('[DELETE_ACCOUNT] error en respuesta: $message');
        throw Exception(message);
      }
    } on FunctionException catch (e) {
      debugPrint(
          '[DELETE_ACCOUNT] FunctionException → status=${e.status}  details=${e.details}');
      final details = e.details;
      final message =
          (details is Map ? details['error'] : null) as String? ??
              'Error al invocar la función de borrado (${e.status}).';
      throw Exception(message);
    } catch (e) {
      debugPrint('[DELETE_ACCOUNT] error inesperado: $e');
      rethrow;
    }
  }
}
