import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../data/datasources/local/database_helper.dart';
import '../data/models/atendimento_model.dart';
import '../data/datasources/remote/atendimento_remote_datasource.dart';

class HistoricoView extends StatefulWidget {
  const HistoricoView({Key? key}) : super(key: key);

  @override
  State<HistoricoView> createState() => _HistoricoViewState();
}

class _HistoricoViewState extends State<HistoricoView> {
  List<AtendimentoModel> _historico = [];
  List<AtendimentoModel> _historicoFiltrado = [];
  bool _isLoading = true;
  bool _isSincronizando = false;
  final TextEditingController _buscaController = TextEditingController();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final AtendimentoRemoteDatasource _remoteDatasource = AtendimentoRemoteDatasource();

  @override
  void initState() {
    super.initState();
    _carregarHistorico();
    _buscaController.addListener(_filtrarHistorico);
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  // RF14 - Listagem de Atendimentos a partir do SQLite
  Future<void> _carregarHistorico() async {
    setState(() {
      _isLoading = true;
    });

    final lista = await DatabaseHelper.instance.listarTodoHistorico();

    setState(() {
      _historico = lista;
      _historicoFiltrado = lista;
      _isLoading = false;
    });
  }

  // RF15 - Filtro de Busca em Tempo Real por ID do Chamado
  void _filtrarHistorico() {
    final query = _buscaController.text.toLowerCase();
    setState(() {
      _historicoFiltrado = _historico.where((atendimento) {
        final chamadoIdStr = atendimento.chamadoId.toString();
        return chamadoIdStr.contains(query) ||
            atendimento.categoriaTecnica.toLowerCase().contains(query);
      }).toList();
    });
  }

  // RF13 & RF16 - Rotina de Sincronização em Nuvem dos itens pendentes
  Future<void> _sincronizarPendentes() async {
    setState(() {
      _isSincronizando = true;
    });

    try {
      final token = await _secureStorage.read(key: 'auth_token');
      if (token == null) {
        throw Exception('Token de autenticação não encontrado.');
      }

      final pendentes = await DatabaseHelper.instance.listarAtendimentosPendentes();

      if (pendentes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nenhum atendimento pendente para sincronizar.')),
        );
        setState(() => _isSincronizando = false);
        return;
      }

      int sucessos = 0;
      for (var atendimento in pendentes) {
        bool enviado = await _remoteDatasource.enviarAtendimento(atendimento, token);
        if (enviado && atendimento.id != null) {
          await DatabaseHelper.instance.marcarAtendimentoComoSincronizado(atendimento.id!);
          sucessos++;
        }
      }

      await _carregarHistorico();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sincronização concluída: $sucessos de ${pendentes.length} enviados.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro na sincronização: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isSincronizando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Atendimentos'),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_sync),
            onPressed: _isSincronizando ? null : _sincronizarPendentes,
            tooltip: 'Sincronizar Pendentes',
          ),
        ],
      ),
      body: Column(
        children: [
          // RF15 - Barra de Pesquisa em Tempo Real
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _buscaController,
              decoration: const InputDecoration(
                labelText: 'Pesquisar por ID do Chamado ou Categoria',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          if (_isSincronizando)
            const LinearProgressIndicator(),
          
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _historicoFiltrado.isEmpty
                    ? const Center(child: Text('Nenhum atendimento encontrado.'))
                    : ListView.builder(
                        itemCount: _historicoFiltrado.length,
                        itemBuilder: (context, index) {
                          final item = _historicoFiltrado[index];
                          bool sincronizado = item.sincronizado == 1;

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: ListTile(
                              title: Text(
                                'OS ID: #${item.chamadoId} - ${item.categoriaTecnica}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text('Procedimento: ${item.descricaoProcedimento}'),
                                  const SizedBox(height: 4),
                                  Text('Data: ${item.dataConclusao.substring(0, 10)}'),
                                  const SizedBox(height: 6),
                                  // RF14 - Badge visual de status de envio
                                  Chip(
                                    label: Text(
                                      sincronizado ? 'Sincronizado' : 'Pendente de Envio',
                                      style: const TextStyle(color: Colors.white, fontSize: 12),
                                    ),
                                    backgroundColor: sincronizado ? Colors.green : Colors.orange,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ],
                              ),
                              trailing: const Icon(Icons.visibility),
                              onTap: () {
                                // RF16 - Visualização Detalhada e Renderização de Fotos
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DetalheHistoricoView(atendimento: item),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

// RF16 - Tela de Detalhes e Renderização de Fotos
class DetalheHistoricoView extends StatelessWidget {
  final AtendimentoModel atendimento;

  const DetalheHistoricoView({Key? key, required this.atendimento}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool sincronizado = atendimento.sincronizado == 1;

    return Scaffold(
      appBar: AppBar(
        title: Text('Detalhes OS #${atendimento.chamadoId}'),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Categoria: ${atendimento.categoriaTecnica}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text('Procedimento realizado:', style: TextStyle(color: Colors.grey.shade700)),
            Text(atendimento.descricaoProcedimento, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 15),
            Text('Data de Conclusão: ${atendimento.dataConclusao}',
                style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 20),
            const Text('Foto Comprobatória:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            
            // RF16 - Renderização da foto (local via Image.file ou remota via Image.network)
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: !sincronizado && File(atendimento.fotoCaminho).existsSync()
                    ? Image.file(
                        File(atendimento.fotoCaminho),
                        fit: BoxFit.cover,
                      )
                    : Image.network(
                        atendimento.fotoCaminho.startsWith('http')
                            ? atendimento.fotoCaminho
                            : 'https://oquetemnomeucosmetico.com.br/storage/${atendimento.fotoCaminho}',
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(child: CircularProgressIndicator());
                        },
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback se a imagem de rede falhar mas existir localmente
                          if (File(atendimento.fotoCaminho).existsSync()) {
                            return Image.file(File(atendimento.fotoCaminho), fit: BoxFit.cover);
                          }
                          return const Center(child: Text('Foto não disponível'));
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}