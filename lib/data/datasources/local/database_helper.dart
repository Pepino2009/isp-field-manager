import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../models/chamado_model.dart';
import '../../models/atendimento_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('isp_field_manager.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // Tabela de Chamados (RF05)
    await db.execute('''
      CREATE TABLE chamados (
        id INTEGER PRIMARY KEY,
        codigo_cliente TEXT,
        nome_cliente TEXT,
        categoria TEXT,
        resumo_problema TEXT,
        endereco TEXT,
        latitude REAL,
        longitude REAL,
        status TEXT
      )
    ''');

    // Tabela de Atendimentos (RF05 e RF12)
    await db.execute('''
      CREATE TABLE atendimentos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        chamado_id INTEGER,
        categoria_tecnica TEXT,
        descricao_procedimento TEXT,
        data_conclusao TEXT,
        foto_caminho TEXT,
        sincronizado INTEGER
      )
    ''');
  }

  // --- MÉTODOS PARA CHAMADOS ---

  Future<void> inserirChamadosEmLote(List<ChamadoModel> chamados) async {
    final db = await instance.database;
    final batch = db.batch();
    for (var chamado in chamados) {
      batch.insert(
        'chamados',
        chamado.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<ChamadoModel>> listarChamadosAbertos() async {
  final db = await instance.database;

  final result = await db.query(
    'chamados',
    where: "LOWER(TRIM(status)) = ?",
    whereArgs: ['aberto'],
  );

  return result
      .map((json) => ChamadoModel.fromMap(json))
      .toList();
}

  Future<void> atualizarStatusChamado(int id, String novoStatus) async {
    final db = await instance.database;
    await db.update(
      'chamados',
      {'status': novoStatus},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- MÉTODOS PARA ATENDIMENTOS ---

  Future<int> inserirAtendimento(AtendimentoModel atendimento) async {
    final db = await instance.database;
    return await db.insert('atendimentos', atendimento.toMap());
  }

  Future<List<AtendimentoModel>> listarAtendimentosPendentes() async {
    final db = await instance.database;
    final result = await db.query(
      'atendimentos',
      where: 'sincronizado = ?',
      whereArgs: [0],
    );
    return result.map((json) => AtendimentoModel.fromMap(json)).toList();
  }

  Future<List<AtendimentoModel>> listarTodoHistorico() async {
    final db = await instance.database;
    final result = await db.query('atendimentos', orderBy: 'id DESC');
    return result.map((json) => AtendimentoModel.fromMap(json)).toList();
  }

  Future<void> marcarAtendimentoComoSincronizado(int id) async {
    final db = await instance.database;
    await db.update(
      'atendimentos',
      {'sincronizado': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}