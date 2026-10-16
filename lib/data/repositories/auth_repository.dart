import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../datasources/remote/auth_remote_datasource.dart';
import '../datasources/local/database_helper.dart';

class AuthRepository {
  final AuthRemoteDatasource remoteDatasource;
  final DatabaseHelper databaseHelper;
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  AuthRepository({
    required this.remoteDatasource,
    required this.databaseHelper,
  });

  // RF03 & RF04 - Login, salvamento seguro do Token e Carga Inicial dos Chamados
  Future<bool> login(String email, String senha) async {
    try {
      // 1. Autentica na API com HMAC-SHA256
      final usuario = await remoteDatasource.login(email, senha);

      // 2. Salva o token de forma segura (RF04)
      await secureStorage.write(key: 'auth_token', value: usuario.token);

      // 3. Busca os chamados na nuvem e salva no SQLite local (Carga Inicial - RF04)
      final chamadosRemotos = await remoteDatasource.buscarChamadosRemotos(usuario.token);
      await databaseHelper.inserirChamadosEmLote(chamadosRemotos);

      return true;
    } catch (e) {
      print('Erro no login/sincronização inicial: $e');
      return false;
    }
  }

  // RF02 - Verificar se existe token salvo (Auto-login)
  Future<String?> recuperarToken() async {
    return await secureStorage.read(key: 'auth_token');
  }

  // Logout / Limpeza de sessão
  Future<void> fazerLogout() async {
    await secureStorage.delete(key: 'auth_token');
  }
}