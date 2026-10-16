import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../data/datasources/local/database_helper.dart';
import '../data/models/chamado_model.dart';
import '../data/repositories/auth_repository.dart';
import '../data/datasources/remote/auth_remote_datasource.dart';
import 'atendimento_view.dart'; // Importação da tela de atendimento (RF08)

class HomeView extends StatefulWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  List<ChamadoModel> _chamados = [];
  bool _isLoading = true;
  Position? _posicaoAtual;

  @override
  void initState() {
    super.initState();
    _carregarDadosHome();
  }

  // RF06 & RF07 - Carregar chamados locais e obter geolocalização
  Future<void> _carregarDadosHome() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Obter localização GPS (RF07)
      _posicaoAtual = await _obterLocalizacaoAtual();

      // 2. Buscar chamados abertos do SQLite (RF06)
      List<ChamadoModel> chamadosLocais =
          await DatabaseHelper.instance.listarChamadosAbertos();

      // 3. Ordenar por proximidade do GPS (RF07)
      if (_posicaoAtual != null) {
        chamadosLocais.sort((a, b) {
          double distA = Geolocator.distanceBetween(
              _posicaoAtual!.latitude, _posicaoAtual!.longitude, a.latitude, a.longitude);
          double distB = Geolocator.distanceBetween(
              _posicaoAtual!.latitude, _posicaoAtual!.longitude, b.latitude, b.longitude);
          return distA.compareTo(distB);
        });
      }

      setState(() {
        _chamados = chamadosLocais;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Erro ao carregar home: $e');
    }
  }

  // Permissão e captura do GPS
  Future<Position?> _obterLocalizacaoAtual() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }

    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ordens de Serviço (Offline-First)'),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarDadosHome,
            tooltip: 'Atualizar Lista',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final authRepo = AuthRepository(
                remoteDatasource: AuthRemoteDatasource(),
                databaseHelper: DatabaseHelper.instance,
              );
              await authRepo.fazerLogout();
              if (!mounted) return;
              Navigator.pushReplacementNamed(context, '/login');
            },
            tooltip: 'Sair',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _chamados.isEmpty
              ? const Center(
                  child: Text(
                    'Nenhum chamado aberto encontrado offline.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: _chamados.length,
                  itemBuilder: (context, index) {
                    final chamado = _chamados[index];

                    // RF07 & RF08 - Cálculo da distância em km para exibição
                    String distanciaStr = 'GPS indisponível';
                    if (_posicaoAtual != null) {
                      double distanciaKm = Geolocator.distanceBetween(
                            _posicaoAtual!.latitude,
                            _posicaoAtual!.longitude,
                            chamado.latitude,
                            chamado.longitude,
                          ) /
                          1000;
                      distanciaStr = '${distanciaKm.toStringAsFixed(2)} km de distância';
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 3,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(
                          'Cliente: ${chamado.nomeCliente}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 6),
                            Text('Código: ${chamado.codigoCliente} | Categoria: ${chamado.categoria}'),
                            const SizedBox(height: 4),
                            Text('Problema: ${chamado.resumoProblema}'),
                            const SizedBox(height: 4),
                            Text('Endereço: ${chamado.endereco}'),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 16, color: Colors.red),
                                const SizedBox(width: 4),
                                Text(
                                  distanciaStr,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500, color: Colors.blue),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        
                        // RF08 - Navegação para a Tela de Atendimento
                        onTap: () async {
                          bool? atualizado = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AtendimentoView(chamado: chamado),
                            ),
                          );

                          // Se o atendimento for concluído com sucesso, recarrega a lista para remover o chamado concluído
                          if (atualizado == true) {
                            _carregarDadosHome();
                          }
                        },
                      ),
                    );
                  },
                ),
    );
  }
}