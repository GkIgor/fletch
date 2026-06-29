import 'package:fletch/models/http_request.dart';
import 'package:fletch/models/http_response.dart';
import 'package:fletch/models/http_auth.dart';

abstract class IHttpClient {
  Future<HttpResponse> send(
    HttpRequest request, {
    Map<String, String>? variables,
    HttpAuth? resolvedAuth,
  });
}
