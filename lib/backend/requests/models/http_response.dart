/// Modelo de resposta HTTP
class HttpResponse {
  final int statusCode;
  final String statusMessage;
  final Map<String, dynamic> headers;
  final dynamic body;
  final int responseTime; // em milissegundos
  final int contentLength; // em bytes

  HttpResponse({
    required this.statusCode,
    required this.statusMessage,
    required this.headers,
    required this.body,
    required this.responseTime,
    required this.contentLength,
  });

  /// Retorna se a resposta foi bem-sucedida (2xx)
  bool get isSuccess => statusCode >= 200 && statusCode < 300;

  /// Retorna se a resposta foi um erro do cliente (4xx)
  bool get isClientError => statusCode >= 400 && statusCode < 500;

  /// Retorna se a resposta foi um erro do servidor (5xx)
  bool get isServerError => statusCode >= 500 && statusCode < 600;

  /// Retorna uma descrição formatada do tamanho
  String get formattedSize {
    if (contentLength < 1024) {
      return '$contentLength B';
    } else if (contentLength < 1024 * 1024) {
      return '${(contentLength / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(contentLength / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  /// Retorna uma descrição formatada do tempo
  String get formattedTime {
    if (responseTime < 1000) {
      return '${responseTime}ms';
    } else {
      return '${(responseTime / 1000).toStringAsFixed(2)}s';
    }
  }

  /// Converte para JSON
  Map<String, dynamic> toJson() {
    return {
      'statusCode': statusCode,
      'statusMessage': statusMessage,
      'headers': headers,
      'body': body,
      'responseTime': responseTime,
      'contentLength': contentLength,
    };
  }

  /// Cria a partir de JSON
  factory HttpResponse.fromJson(Map<String, dynamic> json) {
    return HttpResponse(
      statusCode: json['statusCode'] as int,
      statusMessage: json['statusMessage'] as String,
      headers: Map<String, dynamic>.from(json['headers'] ?? {}),
      body: json['body'],
      responseTime: json['responseTime'] as int,
      contentLength: json['contentLength'] as int,
    );
  }
}
