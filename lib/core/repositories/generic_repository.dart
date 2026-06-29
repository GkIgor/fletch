import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Um repositório genérico responsável pelas operações de I/O em arquivos locais.
/// Realiza escritas atômicas e processamento de JSON em isolates em background.
class GenericRepository {
  /// Escreve [data] em formato JSON de maneira atômica no caminho especificado por [path].
  /// Utiliza `compute` para serializar o JSON em um isolate separado se for grande,
  /// e escreve em um arquivo temporário antes de renomeá-lo para evitar corrupção de dados.
  Future<void> writeJson(String path, Map<String, dynamic> data) async {
    final file = File(path);
    final directory = file.parent;
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    // Serializa o JSON em um background isolate para não travar a UI Thread
    final jsonString = await compute(_jsonEncodeIsolate, data);

    final tempFile = File('$path.tmp');
    // Escreve os dados no arquivo temporário e força o flush do buffer do SO
    await tempFile.writeAsString(jsonString, flush: true);
    // Renomeia atomicamente o arquivo temporário para o destino final
    await tempFile.rename(path);
  }

  /// Lê o arquivo especificado por [path] e retorna seu conteúdo decodificado como Map.
  /// Decodifica o JSON em um isolate separado para evitar travamentos na thread principal.
  Future<Map<String, dynamic>?> readJson(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      return null;
    }

    try {
      final content = await file.readAsString();
      if (content.trim().isEmpty) {
        return null;
      }
      final decoded = await compute(_jsonDecodeIsolate, content);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Remove o arquivo especificado por [path], se existir.
  Future<void> delete(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Retorna os caminhos de todos os arquivos `.json` no diretório [dirPath].
  Future<List<String>> listJsonFiles(String dirPath) async {
    final dir = Directory(dirPath);
    if (!await dir.exists()) {
      return [];
    }

    final List<String> paths = [];
    await for (final entity in dir.list()) {
      if (entity is File && entity.path.endsWith('.json')) {
        paths.add(entity.path);
      }
    }
    return paths;
  }

  /// Retorna o tamanho do arquivo em bytes.
  Future<int> getFileSize(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      return 0;
    }
    return await file.length();
  }
}

// Funções de nível superior necessárias para execução com `compute`

String _jsonEncodeIsolate(Map<String, dynamic> map) {
  return jsonEncode(map);
}

dynamic _jsonDecodeIsolate(String source) {
  return jsonDecode(source);
}
