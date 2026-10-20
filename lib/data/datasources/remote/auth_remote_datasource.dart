import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import '../../models/usuario_model.dart';
import '../../models/chamado_model.dart';

class AuthRemoteDatasource {
  static const String baseUrl = 'https://oquetemnomeucosmetico.com.br/api';
  static const String chaveSecreta = r'ISP_TECH_SENAI_2026_xK9#mQ2$vL8!zP4';

  // RF03 - Criptografia HMAC-SHA256 garantindo o tratamento correto de caracteres especiais
  String _criptografarSenha(String senha) {
    // Remove espaços acidentais nas pontas que possam vir do input do campo
    final senhaTratada = senha.trim();
    
    var key = utf8.encode(chaveSecreta);
    var bytes = utf8.encode(senhaTratada);
    var hmacSha256 = Hmac(sha256, key);
    var digest = hmacSha256.convert(bytes);
    
    return digest.toString();
  }

  // Restante do código de login...
  // Restante dos métodos de login e chamados...

  // RF03 & RF04 - Realizar Login na API
  Future<UsuarioModel> login(String email, String senha) async {
  final senhaTratada = senha.trim();
  final senhaCriptografada = _criptografarSenha(senhaTratada);

  final url = Uri.parse('$baseUrl/login');
  final corpoRequisicao = jsonEncode({
    'email': email.trim(),
    'senha': senhaCriptografada,
  });

  print('================ DEBUG LOGIN ================');
  print('URL: $url');
  print('Payload enviado: $corpoRequisicao');
  print('=============================================');

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: corpoRequisicao,
  );

  print('Status Code da API: ${response.statusCode}');
  print('Corpo da Resposta da API: ${response.body}');
  print('=============================================');

  if (response.statusCode == 200 || response.statusCode == 201) {
    final data = jsonDecode(response.body);
    return UsuarioModel.fromJson(data);
  } else {
    throw Exception('Erro ${response.statusCode}: ${response.body}');
  }
}
// RF04 - Carga inicial dos chamados da API
Future<List<ChamadoModel>> buscarChamadosRemotos(String token) async {
  final url = Uri.parse('$baseUrl/chamados');
  print('A carregar chamados de: $url');

  final response = await http.get(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  print('Status Code Chamados: ${response.statusCode}');
  print('Resposta Chamados: ${response.body}');

  if (response.statusCode == 200) {
    final decoded = jsonDecode(response.body);
    
    // Extrai a lista de chamados independentemente de vir na raiz ou dentro de 'dados' / 'chamados'
    List<dynamic> listaDinamica;
    if (decoded is List) {
      listaDinamica = decoded;
    } else if (decoded is Map<String, dynamic>) {
      listaDinamica = decoded['dados'] ?? decoded['chamados'] ?? decoded['data'] ?? [];
    } else {
      listaDinamica = [];
    }

    return listaDinamica.map((json) => ChamadoModel.fromJson(json)).toList();
  } else {
    throw Exception('Erro ao carregar chamados da API: ${response.statusCode} - ${response.body}');
  }
}
}