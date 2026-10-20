class UsuarioModel {
  final int id;
  final String email;
  final String token;

  UsuarioModel({
    required this.id,
    required this.email,
    required this.token,
  });

  factory UsuarioModel.fromJson(Map<String, dynamic> json) {
    print('JSON recebido do login: $json');
    
    // Extrai de forma segura caso venha encapsulado em 'dados' ou na raiz
    final dados = json['dados'] is Map<String, dynamic> ? json['dados'] as Map<String, dynamic> : json;
    final usuario = dados['usuario'] is Map<String, dynamic> ? dados['usuario'] as Map<String, dynamic> : dados;

    return UsuarioModel(
      id: usuario['id'] ?? dados['id'] ?? 0,
      email: usuario['email'] ?? dados['email'] ?? '',
      token: dados['token'] ?? usuario['token'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'token': token,
    };
  }
}