import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/atendimento_model.dart';

class AtendimentoRemoteDatasource {
  static const String baseUrl = 'https://oquetemnomeucosmetico.com.br/api';

  // RF13 - Upload de Atendimento em Multipart/Form-Data com Bearer Token
  Future<bool> enviarAtendimento(AtendimentoModel atendimento, String token) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/atendimento'),
      );

      // Cabeçalho com Bearer Token (RF13)
      request.headers['Authorization'] = 'Bearer $token';

      // Campos do formulário
      request.fields['chamado_id'] = atendimento.chamadoId.toString();
      request.fields['categoria_tecnica'] = atendimento.categoriaTecnica;
      request.fields['descricao_procedimento'] = atendimento.descricaoProcedimento;
      request.fields['data_conclusao'] = atendimento.dataConclusao;

      // Anexar o arquivo binário da foto (RF13)
      if (atendimento.fotoCaminho.isNotEmpty) {
        request.files.add(
          await http.MultipartFile.fromPath('foto', atendimento.fotoCaminho),
        );
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      // Retorno 201 Created indica sucesso na sincronização (RF13)
      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        print('Erro na API ao enviar atendimento: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Exceção ao sincronizar atendimento: $e');
      return false;
    }
  }
}