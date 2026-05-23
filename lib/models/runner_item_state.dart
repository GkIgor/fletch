import 'package:fletch/models/http_request.dart';
import 'package:fletch/models/http_response.dart';

class RunnerItemState {
  final HttpRequest request;
  bool isSelected;
  String status; // 'pending', 'running', 'success', 'failure'
  HttpResponse? response;
  String? errorMessage;

  RunnerItemState({
    required this.request,
    this.isSelected = true,
    this.status = 'pending',
    this.response,
    this.errorMessage,
  });

  void reset() {
    status = 'pending';
    response = null;
    errorMessage = null;
  }
}
