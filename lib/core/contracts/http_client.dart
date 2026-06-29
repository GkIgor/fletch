import 'package:fletch/backend/requests/models/http_request.dart';
import 'package:fletch/backend/requests/models/http_response.dart';
import 'package:fletch/backend/requests/models/http_auth.dart';

abstract class IHttpClient {
  Future<HttpResponse> send(
    HttpRequest request, {
    Map<String, String>? variables,
    HttpAuth? resolvedAuth,
  });
}
