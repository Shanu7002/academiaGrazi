import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

/// Interface injetável: facilita testar o cadastro sem abrir a galeria real.
abstract class SeletorImagemExercicio {
  Future<Uint8List?> selecionarDaGaleria();
}

class SeletorImagemExercicioPadrao implements SeletorImagemExercicio {
  final ImagePicker _picker;

  SeletorImagemExercicioPadrao({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  @override
  Future<Uint8List?> selecionarDaGaleria() async {
    final XFile? arquivo = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 80,
      requestFullMetadata: false,
    );

    if (arquivo == null) return null;

    final bytes = await arquivo.readAsBytes();
    if (bytes.isEmpty) {
      throw const FormatException('O arquivo selecionado está vazio.');
    }
    if (bytes.lengthInBytes > 8 * 1024 * 1024) {
      throw const FormatException('Selecione uma imagem de até 8 MB.');
    }
    return bytes;
  }
}
