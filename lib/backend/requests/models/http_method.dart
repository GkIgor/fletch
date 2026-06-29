/// Enumeração de métodos HTTP suportados
enum HttpMethod {
  get('GET'),
  post('POST'),
  put('PUT'),
  delete('DELETE'),
  patch('PATCH');

  const HttpMethod(this.value);
  final String value;

  @override
  String toString() => value;
}
