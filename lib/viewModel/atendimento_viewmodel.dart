import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../data/datasources/local/database_helper.dart';
import '../data/models/chamado_model.dart';
import '../data/models/atendimento_model.dart';

class AtendimentoViewModel extends ChangeNotifier {
  final ChamadoModel chamado;

  bool _isLoading = false;
  String _mensagemErro = '';
  final _secureStorage = const FlutterSecureStorage();

  bool get isLoading => _isLoading;
  String get mensagemErro => _mensagemErro;

  AtendimentoViewModel({required this.chamado});

  Future<bool> salvarAtendimento({
    required String categoriaTecnica,
    required String descricaoProcedimento,
    required File fotoArquivo,
  }) async {
    _isLoading = true;
    _mensagemErro = '';
    notifyListeners();

    bool sucessoApi = false;

    // 1. Tenta enviar para a API oficial do professor
    try {
      String? token = await _secureStorage.read(key: 'auth_token');

      final bodyData = {
        'chamado_id': chamado.id,
        'categoria_tecnica': categoriaTecnica,
        'descricao_procedimento': descricaoProcedimento,
        'data_conclusao': DateTime.now().toIso8601String(),
        'foto_caminho': fotoArquivo.path,
      };

      final response = await http.post(
        Uri.parse('https://oquetemnomeuscosmetico.com.br/api/atendimentos'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(bodyData),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        sucessoApi = true;
      }
    } catch (e) {
      print('Erro ao enviar atendimento para API (será sincronizado depois): $e');
    }

    // 2. Gravar no SQLite local (RF12)
    try {
      final atendimento = AtendimentoModel(
        chamadoId: chamado.id,
        categoriaTecnica: categoriaTecnica,
        descricaoProcedimento: descricaoProcedimento,
        dataConclusao: DateTime.now().toIso8601String(),
        fotoCaminho: fotoArquivo.path,
        sincronizado: sucessoApi ? 1 : 0,
      );

      await DatabaseHelper.instance.inserirAtendimento(atendimento);
      await DatabaseHelper.instance.atualizarStatusChamado(chamado.id, 'concluido');
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _mensagemErro = 'Erro ao salvar no banco local: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}