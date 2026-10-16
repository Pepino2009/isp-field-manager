import 'package:flutter/material.dart';
import '../data/repositories/auth_repository.dart';
import '../data/datasources/remote/auth_remote_datasource.dart';
import '../data/datasources/local/database_helper.dart';

class SplashView extends StatefulWidget {
  const SplashView({Key? key}) : super(key: key);

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  final AuthRepository _authRepository = AuthRepository(
    remoteDatasource: AuthRemoteDatasource(),
    databaseHelper: DatabaseHelper.instance,
  );

  @override
  void initState() {
    super.initState();
    _verificarSessao();
  }

  // RF02 - Verificação de Sessão (Auto-login)
  Future<void> _verificarSessao() async {
    // Aguarda 2 segundos para exibir a logo/splash
    await Future.delayed(const Duration(seconds: 2));

    String? token = await _authRepository.recuperarToken();

    if (!mounted) return;

    if (token != null && token.isNotEmpty) {
      // Token existe: Redireciona para a Home (Tela 03)
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      // Token não existe: Redireciona para o Login (Tela 02)
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade900,
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cell_tower,
              size: 80,
              color: Colors.white,
            ),
            SizedBox(height: 20),
            Text(
              'ISP Field Manager',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Carregando sistema offline...',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 30),
            CircularProgressIndicator(
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}