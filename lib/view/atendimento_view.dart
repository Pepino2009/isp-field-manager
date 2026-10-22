import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../data/models/chamado_model.dart';
import '../viewmodel/atendimento_viewmodel.dart';

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

  late AtendimentoViewModel _viewModel;

  final List<String> _categorias = [
    'Instalação de Fibra',
    'Manutenção de Roteador',
    'Reparo de Cabo Rompido',
    'Substituição de ONU',
    'Suporte Técnico Geral'
  ];

  @override
  void initState() {
    super.initState();
    _viewModel = AtendimentoViewModel(chamado: widget.chamado);
    _viewModel.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  // RF11 - Capturar foto da câmera ou galeria
  Future<void> _capturarFoto(ImageSource source) async {
    final XFile? imagem = await _picker.pickImage(
      source: source,
      imageQuality: 70,
    );

    if (imagem != null) {
      setState(() {
        _fotoArquivo = File(imagem.path);
      });
    }
  }

  // RF10 & RF12 - Validar formulário e delegar salvamento para a ViewModel
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

      // Chama a lógica de negócio na ViewModel
      bool sucesso = await _viewModel.salvarAtendimento(
        categoriaTecnica: _categoriaSelecionada!,
        descricaoProcedimento: _descricaoController.text.trim(),
        fotoArquivo: _fotoArquivo!,
      );

      if (!mounted) return;

      if (sucesso) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Atendimento concluído e gravado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Retorna para a Home atualizando a lista
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_viewModel.mensagemErro.isNotEmpty ? _viewModel.mensagemErro : 'Erro ao salvar atendimento.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
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

                // Dropdown de Categoria Técnica com Validação
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

                // Campo de texto para descrição
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

                // Seção de Foto Comprobatória
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

                // Exibir pré-visualização da foto
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
                    onPressed: _viewModel.isLoading ? null : _concluirAtendimento,
                    child: _viewModel.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Finalizar e Salvar Offline',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}