import 'runner_item_state.dart';

class RunnerSession {
  final String id;
  final List<RunnerItemState> items;
  final Map<String, String> variables;
  bool isCurrentlyRunning;
  int currentIndex;
  int delayMs;
  bool stopExecution;

  RunnerSession({
    required this.id,
    required this.items,
    Map<String, String>? variables,
    this.isCurrentlyRunning = false,
    this.currentIndex = -1,
    this.delayMs = 0,
    this.stopExecution = false,
  }) : variables = Map<String, String>.from(variables ?? {});
}
