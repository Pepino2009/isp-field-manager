class AtendimentoModel {
  final int? id;
  final int chamadoId;
  final String categoriaTecnica;
  final String descricaoProcedimento;
  final String dataConclusao;
  final String fotoCaminho;
  int sincronizado; // 0 = pendente, 1 = sincronizado

  AtendimentoModel({
    this.id,
    required this.chamadoId,
    required this.categoriaTecnica,
    required this.descricaoProcedimento,
    required this.dataConclusao,
    required this.fotoCaminho,
    this.sincronizado = 0,
  });

  factory AtendimentoModel.fromJson(Map<String, dynamic> json) {
    return AtendimentoModel(
      id: json['id'],
      chamadoId: json['chamado_id'] ?? 0,
      categoriaTecnica: json['categoria_tecnica'] ?? '',
      descricaoProcedimento: json['descricao_procedimento'] ?? '',
      dataConclusao: json['data_conclusao'] ?? '',
      fotoCaminho: json['foto_caminho'] ?? '',
      sincronizado: json['sincronizado'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chamado_id': chamadoId,
      'categoria_tecnica': categoriaTecnica,
      'descricao_procedimento': descricaoProcedimento,
      'data_conclusao': dataConclusao,
    };
  }

  factory AtendimentoModel.fromMap(Map<String, dynamic> map) {
    return AtendimentoModel(
      id: map['id'],
      chamadoId: map['chamado_id'] ?? 0,
      categoriaTecnica: map['categoria_tecnica'] ?? '',
      descricaoProcedimento: map['descricao_procedimento'] ?? '',
      dataConclusao: map['data_conclusao'] ?? '',
      fotoCaminho: map['foto_caminho'] ?? '',
      sincronizado: map['sincronizado'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'chamado_id': chamadoId,
      'categoria_tecnica': categoriaTecnica,
      'descricao_procedimento': descricaoProcedimento,
      'data_conclusao': dataConclusao,
      'foto_caminho': fotoCaminho,
      'sincronizado': sincronizado,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }
}