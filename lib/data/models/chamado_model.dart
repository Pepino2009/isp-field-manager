class ChamadoModel {
  final int id;
  final String codigoCliente;
  final String nomeCliente;
  final String categoria;
  final String resumoProblema;
  final String endereco;
  final double latitude;
  final double longitude;
  String status; // 'aberto' ou 'atendido'

  ChamadoModel({
    required this.id,
    required this.codigoCliente,
    required this.nomeCliente,
    required this.categoria,
    required this.resumoProblema,
    required this.endereco,
    required this.latitude,
    required this.longitude,
    required this.status,
  });

  // Mapeamento para API REST (JSON)
  factory ChamadoModel.fromJson(Map<String, dynamic> json) {
    return ChamadoModel(
      id: json['id'] ?? 0,
      codigoCliente: json['codigo_cliente'] ?? '',
      nomeCliente: json['nome_cliente'] ?? '',
      categoria: json['categoria'] ?? '',
      resumoProblema: json['resumo_problema'] ?? '',
      endereco: json['endereco'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'aberto',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'codigo_cliente': codigoCliente,
      'nome_cliente': nomeCliente,
      'categoria': categoria,
      'resumo_problema': resumoProblema,
      'endereco': endereco,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
    };
  }

  // Mapeamento para Banco de Dados Local SQLite (Map)
  factory ChamadoModel.fromMap(Map<String, dynamic> map) {
    return ChamadoModel(
      id: map['id'] ?? 0,
      codigoCliente: map['codigo_cliente'] ?? '',
      nomeCliente: map['nome_cliente'] ?? '',
      categoria: map['categoria'] ?? '',
      resumoProblema: map['resumo_problema'] ?? '',
      endereco: map['endereco'] ?? '',
      latitude: map['latitude'] ?? 0.0,
      longitude: map['longitude'] ?? 0.0,
      status: map['status'] ?? 'aberto',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'codigo_cliente': codigoCliente,
      'nome_cliente': nomeCliente,
      'categoria': categoria,
      'resumo_problema': resumoProblema,
      'endereco': endereco,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
    };
  }
}