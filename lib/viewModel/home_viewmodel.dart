import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../data/datasources/local/database_helper.dart';
import '../data/models/chamado_model.dart';

class HomeViewModel extends ChangeNotifier {
  List<ChamadoModel> _chamados = [];
  bool _isLoading = false;
  Position? _posicaoAtual;
  String _filtroTexto = '';
  
  final _secureStorage = const FlutterSecureStorage();

  List<ChamadoModel> get chamados => _chamadosFiltrados;
  bool get isLoading => _isLoading;
  Position? get posicaoAtual => _posicaoAtual;

  // Carrega os dados (tenta do SQLite e da API oficial do professor)
  Future<void> carregarDados() async {
    _isLoading = true;
    notifyListeners();

    List<ChamadoModel> listaTemporaria = [];

    // 1. Tenta buscar do SQLite local
    try {
      listaTemporaria = await DatabaseHelper.instance.listarChamadosAbertos();
    } catch (_) {}

    // 2. Se vazio, busca da API oficial com o Bearer Token
    if (listaTemporaria.isEmpty) {
      try {
        String? token = await _secureStorage.read(key: 'auth_token');

        final response = await http.get(
          Uri.parse('https://oquetemnomeucosmetico.com.br/api/chamados'),
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ).timeout(const Duration(seconds: 10));
        debugPrint('STATUS: ${response.statusCode}');
        debugPrint('RESPOSTA: ${response.body}');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          var itens = data['dados'] ?? data;
          if (itens is List) {
            for (var jsonItem in itens) {
            
              try {
                final mapSeguro = {
                  'id': jsonItem['id'],
                  'codigo_cliente': jsonItem['codigo_cliente'] ?? jsonItem['codigo'] ?? '',
                  'nome_cliente': jsonItem['nome_cliente'] ?? jsonItem['cliente'] ?? '',
                  'categoria': jsonItem['categoria'] ?? jsonItem['categoria_informada'] ?? 'Geral',
                  'resumo_problema': jsonItem['resumo_problema'] ?? jsonItem['descricao_problema'] ?? '',
                  'endereco': jsonItem['endereco'] ?? jsonItem['endereco_cliente'] ?? '',
                  'latitude': double.tryParse(jsonItem['latitude'].toString()) ?? 0.0,
                  'longitude': double.tryParse(jsonItem['longitude'].toString()) ?? 0.0,
                  'status': jsonItem['status'] ?? 'ativo',
                };
                listaTemporaria.add(ChamadoModel.fromMap(mapSeguro));
              } catch (e) {
                print('Erro ao mapear item: $e');
              }
            }
            if (listaTemporaria.isNotEmpty) {
             await DatabaseHelper.instance
             .inserirChamadosEmLote(listaTemporaria);
           }
         }
        }
      } catch (e) {
        print('Erro na API: $e');
      }
    }

    _chamados = listaTemporaria;
    _isLoading = false;
    notifyListeners();

    // Obtém o GPS em segundo plano para calcular distâncias
    _obterGps();
  }

  // Lógica de GPS e ordenação por proximidade
  Future<void> _obterGps() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      Position? posicao = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 4),
      );

      if (posicao != null) {
        _posicaoAtual = posicao;
        if (_chamados.isNotEmpty) {
          _chamados.sort((a, b) {
            double distA = Geolocator.distanceBetween(
                posicao.latitude, posicao.longitude, a.latitude, a.longitude);
            double distB = Geolocator.distanceBetween(
                posicao.latitude, posicao.longitude, b.latitude, b.longitude);
            return distA.compareTo(distB);
          });
        }
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> atualizarProximidade() async {
    await _obterGps();
  }

  // Filtragem para a barra de pesquisa
  void filtrar(String texto) {
    _filtroTexto = texto;
    notifyListeners();
  }

  List<ChamadoModel> get _chamadosFiltrados {
    if (_filtroTexto.isEmpty) return _chamados;
    final query = _filtroTexto.toLowerCase();

    return _chamados.where((c) {
      final nome = (c.nomeCliente ?? '').toLowerCase();
      final endereco = (c.endereco ?? '').toLowerCase();
      final resumo = (c.resumoProblema ?? '').toLowerCase();
      final categoria = (c.categoria ?? '').toLowerCase();

      return nome.contains(query) ||
             endereco.contains(query) ||
             resumo.contains(query) ||
             categoria.contains(query);
    }).toList();
  }
}