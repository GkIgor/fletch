import 'dart:convert';
import 'package:crypto/crypto.dart' as crypto_pkg;
import 'package:fletch/utils/script_compiler.dart';

class CompiledCryptoStep extends CompiledStep {
  final String? nextStepId;
  final String operation;
  final CompiledValueSource valueSource;
  final CompiledValueSource? keySource;
  final String saveToVariable;

  CompiledCryptoStep({
    required super.id,
    required super.name,
    this.nextStepId,
    required this.operation,
    required this.valueSource,
    this.keySource,
    required this.saveToVariable,
  });

  @override
  Future<ExecutionResult> execute(ExecutionContext context, Map<String, CompiledStep> nodes) async {
    final value = valueSource.resolve(context);
    final key = keySource?.resolve(context) ?? '';

    String result = '';
    try {
      switch (operation) {
        case 'hashMD5':
          result = crypto_pkg.md5.convert(utf8.encode(value)).toString();
          break;
        case 'hashSHA256':
          result = crypto_pkg.sha256.convert(utf8.encode(value)).toString();
          break;
        case 'hmacSHA256':
          if (key.isEmpty) {
            context.log(id, name, 'Chave HMAC está vazia.', level: LogLevel.warn);
          }
          final hmac = crypto_pkg.Hmac(crypto_pkg.sha256, utf8.encode(key));
          result = hmac.convert(utf8.encode(value)).toString();
          break;
        default:
          context.log(id, name, 'Operação criptográfica "$operation" não suportada.', level: LogLevel.error);
          return ExecutionResult(success: false, error: 'Unsupported crypto operation: $operation');
      }
      context.variables[saveToVariable] = result;
      context.log(id, name, 'Crypto executado ($operation). Resultado salvo em "$saveToVariable".', level: LogLevel.info);
    } catch (e) {
      context.log(id, name, 'Erro na operação criptográfica: $e', level: LogLevel.error);
      return ExecutionResult(success: false, error: e.toString());
    }

    return ExecutionResult(success: true, nextNodeId: nextStepId);
  }
}
