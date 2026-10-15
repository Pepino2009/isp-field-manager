import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import '../../models/usuario_model.dart';
import '../../models/chamado_model.dart';

class AuthRemoteDatasource {
  static const String baseUrl = 'https://oquetemnomeucosmetico.com.br/api';
  // Chave Secreta Compartilhada da Turma exigida pelo projeto (Seção 4.2)
  static const String chaveSecreta = 'ISP_TECH_SENAI_2026_xK9#mQ2\$vL8!zP4';

  // RF03 - Criptografia da senha com HMAC-SHA256
  String _criptografarSenha(String senha) {
    var key = utf8.encode(chaveSecreta);
    var bytes = utf8.encode(senha);
    var hmacSha256 = Hmac(sha256, key);
    var digest = hmacSha256.convert(bytes);
    return digest.toString();
  }

  // RF03 & RF04 - Realizar Login na API
  Future<UsuarioModel> login(String email, String senha) async {
    final senhaCriptografada = _criptografarSenha(senha);

    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'senha': senhaCriptografada,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return UsuarioModel.fromJson(data);
    } else {
      throw Exception('Falha no login: ${response.body}');
    }
  }

  // RF04 - Carga inicial dos chamados da API
  Future<List<ChamadoModel>> buscarChamadosRemotos(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/chamados'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> lista = jsonDecode(response.body);
      return lista.map((json) => ChamadoModel.fromJson(json)).toList();
    } else {
      throw Exception('Erro ao carregar chamados da API: ${response.statusCode}');
    }
  }
}