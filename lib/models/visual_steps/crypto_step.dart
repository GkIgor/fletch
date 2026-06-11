import '../visual_script.dart';

class CryptoStep extends VisualStep {
  String operation; // "hashMD5", "hashSHA256", "hmacSHA256", "encryptAES", "decryptAES"
  ValueSource valueSource;
  ValueSource? keySource;
  String saveToVariable;

  CryptoStep({
    super.id,
    super.name = 'Crypto',
    super.enabled,
    super.nextStepId,
    this.operation = 'hashSHA256',
    ValueSource? valueSource,
    this.keySource,
    this.saveToVariable = '',
  })  : valueSource = valueSource ?? ValueSource(),
        super(type: VisualStepType.crypto);

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'name': name,
        'enabled': enabled,
        'nextStepId': nextStepId,
        'operation': operation,
        'valueSource': valueSource.toJson(),
        'keySource': keySource?.toJson(),
        'saveToVariable': saveToVariable,
      };

  factory CryptoStep.fromJson(Map<String, dynamic> json) => CryptoStep(
        id: json['id'] as String?,
        name: json['name'] as String? ?? 'Crypto',
        enabled: json['enabled'] as bool? ?? true,
        nextStepId: json['nextStepId'] as String?,
        operation: json['operation'] as String? ?? 'hashSHA256',
        valueSource: json['valueSource'] != null
            ? ValueSource.fromJson(Map<String, dynamic>.from(json['valueSource']))
            : ValueSource(),
        keySource: json['keySource'] != null
            ? ValueSource.fromJson(Map<String, dynamic>.from(json['keySource']))
            : null,
        saveToVariable: json['saveToVariable'] as String? ?? '',
      );
}
