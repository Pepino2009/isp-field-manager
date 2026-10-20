import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../viewmodel/home_viewmodel.dart';
import '../data/repositories/auth_repository.dart';
import '../data/datasources/remote/auth_remote_datasource.dart';
import '../data/datasources/local/database_helper.dart';
import 'atendimento_view.dart';
import 'historico_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final HomeViewModel _viewModel = HomeViewModel();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel.carregarDados();
    // Atualiza a tela sempre que a ViewModel chamar notifyListeners()
    _viewModel.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listaExibicao = _viewModel.chamados;

    return GestureDetector(
      // Fecha o teclado ao tocar em qualquer área fora dos inputs
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Ordens de Serviço'),
          backgroundColor: Colors.blue.shade900,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _viewModel.carregarDados(),
              tooltip: 'Atualizar',
            ),
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HistoricoView()),
                );
              },
              tooltip: 'Histórico',
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
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (valor) => _viewModel.filtrar(valor),
                      decoration: InputDecoration(
                        hintText: 'Pesquisar (ex: Florianópolis)...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  _viewModel.filtrar('');
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () async {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('A atualizar localização...')),
                      );
                      await _viewModel.atualizarProximidade();
                    },
                    icon: const Icon(Icons.near_me, size: 18),
                    label: const Text('Mais Próximos'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade800,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _viewModel.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : listaExibicao.isEmpty
                      ? const Center(
                          child: Text(
                            'Nenhum projeto encontrado.',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: listaExibicao.length,
                          itemBuilder: (context, index) {
                            final chamado = listaExibicao[index];

                            String distanciaStr = 'A calcular distância...';
                            if (_viewModel.posicaoAtual != null) {
                              try {
                                double distanciaKm = Geolocator.distanceBetween(
                                      _viewModel.posicaoAtual!.latitude,
                                      _viewModel.posicaoAtual!.longitude,
                                      chamado.latitude,
                                      chamado.longitude,
                                    ) /
                                    1000;
                                distanciaStr = '${distanciaKm.toStringAsFixed(2)} km de distância';
                              } catch (_) {
                                distanciaStr = 'Coordenadas indisponíveis';
                              }
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
                                onTap: () async {
                                  FocusScope.of(context).unfocus();
                                  bool? atualizado = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AtendimentoView(chamado: chamado),
                                    ),
                                  );

                                  if (atualizado == true) {
                                    _viewModel.carregarDados();
                                  }
                                },
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}