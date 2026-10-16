import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../data/datasources/local/database_helper.dart';
import '../data/models/chamado_model.dart';
import '../data/models/atendimento_model.dart';

class AtendimentoView extends StatefulWidget {
  final ChamadoModel chamado;

  const AtendimentoView({Key? key, required this.chamado}) : super(key: key);

  @override
  State<AtendimentoView> createState() => _AtendimentoViewState();
}

class _AtendimentoViewState extends State<AtendimentoView> {
  final _formKey = GlobalKey<FormState>();
  final _descricaoController = TextEditingController();
  
  String? _categoriaSelecionada;
  File? _fotoArquivo;
  final ImagePicker _picker = ImagePicker();

  final List<String> _categorias = [
    'Instalação de Fibra',
    'Manutenção de Roteador',
    'Reparo de Cabo Rompido',
    'Substituição de ONU',
    'Suporte Técnico Geral'
  ];

  // RF11 - Capturar foto da câmera ou galeria
  Future<void> _capturarFoto(ImageSource source) async {
    final XFile? imagem = await _picker.pickImage(
      source: source,
      imageQuality: 70, // Compressão para otimizar armazenamento
    );

    if (imagem != null) {
      setState(() {
        _fotoArquivo = File(imagem.path);
      });
    }
  }

  // RF10 & RF12 - Validar formulário estrito e gravar offline no SQLite
  Future<void> _concluirAtendimento() async {
    if (_formKey.currentState!.validate()) {
      if (_fotoArquivo == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor, anexe uma foto comprobatória do atendimento.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      try {
        final dataAtual = DateTime.now().toIso8601String();

        // 1. Criar o objeto AtendimentoModel com flag sincronizado = 0 (pendente)
        AtendimentoModel atendimento = AtendimentoModel(
          chamadoId: widget.chamado.id,
          categoriaTecnica: _categoriaSelecionada!,
          descricaoProcedimento: _descricaoController.text.trim(),
          dataConclusao: dataAtual,
          fotoCaminho: _fotoArquivo!.path,
          sincronizado: 0,
        );

        // 2. Gravar o atendimento no SQLite local (RF12)
        await DatabaseHelper.instance.inserirAtendimento(atendimento);

        // 3. Atualizar o status do chamado para 'atendido' no SQLite (RF12)
        await DatabaseHelper.instance.atualizarStatusChamado(widget.chamado.id, 'atendido');

        if (!mounted) return;

        // SnackBar de confirmação e retorno para a Home
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Atendimento concluído e gravado offline com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );

        // Retorna para a tela anterior (Home) atualizando a lista
        Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar atendimento: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Atendimento OS #${widget.chamado.id}'),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho com dados da OS (RF09)
              Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cliente: ${widget.chamado.nomeCliente}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 6),
                      Text('Código: ${widget.chamado.codigoCliente}'),
                      const SizedBox(height: 4),
                      Text('Problema: ${widget.chamado.resumoProblema}'),
                      const SizedBox(height: 4),
                      Text('Endereço: ${widget.chamado.endereco}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Dropdown de Categoria Técnica com Validação (RF09 & RF10)
              DropdownButtonFormField<String>(
                value: _categoriaSelecionada,
                decoration: const InputDecoration(
                  labelText: 'Categoria do Parecer Técnico *',
                  border: OutlineInputBorder(),
                ),
                items: _categorias.map((String categoria) {
                  return DropdownMenuItem<String>(
                    value: categoria,
                    child: Text(categoria),
                  );
                }).toList(),
                onChanged: (String? novoValor) {
                  setState(() {
                    _categoriaSelecionada = novoValor;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Selecione a categoria técnica obrigatória';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Campo de texto multilinhas para descrição (RF09 & RF10 - Mínimo 10 caracteres)
              TextFormField(
                controller: _descricaoController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Descrição do Procedimento Realizado *',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().length < 10) {
                    return 'A descrição deve ter no mínimo 10 caracteres válidos';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Seção de Foto Comprobatória (RF11)
              const Text(
                'Foto Comprobatória do Serviço *',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _capturarFoto(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Câmera'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => _capturarFoto(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Galeria'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Exibir pré-visualização da foto se capturada
              if (_fotoArquivo != null)
                Center(
                  child: Stack(
                    children: [
                      Container(
                        height: 180,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _fotoArquivo!,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: CircleAvatar(
                          backgroundColor: Colors.red,
                          child: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.white),
                            onPressed: () {
                              setState(() {
                                _fotoArquivo = null;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 30),

              // Botão de Conclusão do Atendimento
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _concluirAtendimento,
                  child: const Text(
                    'Finalizar e Salvar Offline',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}