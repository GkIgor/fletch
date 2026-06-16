import 'package:flutter_test/flutter_test.dart';
import 'package:fletch/models/visual_script.dart';
import 'package:fletch/utils/graph_validator.dart';

void main() {
  group('GraphValidator Reachability & Cycle Detection Tests', () {
    test('Should detect reachable and unreachable nodes correctly', () {
      final script = VisualScript(
        name: 'Test Script',
        startNodeId: 'start',
        nodes: {
          'start': StartStep(id: 'start', name: 'Start', nextStepId: 'step1'),
          'step1': SetVariableStep(id: 'step1', name: 'Set Var', nextStepId: 'step2'),
          'step2': AssertValueStep(id: 'step2', name: 'Assert', nextStepId: null),
          // Orphaned sub-graph
          'stepOrphan1': DelayStep(id: 'stepOrphan1', name: 'Delay Orphan', nextStepId: 'stepOrphan2'),
          'stepOrphan2': EndStep(id: 'stepOrphan2', name: 'End Orphan', nextStepId: null),
        },
      );

      final reachable = GraphValidator.getReachableNodeIds(script);
      expect(reachable, contains('start'));
      expect(reachable, contains('step1'));
      expect(reachable, contains('step2'));
      expect(reachable, isNot(contains('stepOrphan1')));
      expect(reachable, isNot(contains('stepOrphan2')));

      final validationErrors = GraphValidator.validate(script);
      final warnings = validationErrors.where((e) => e.severity == ValidationErrorSeverity.warning).toList();
      expect(warnings.any((w) => w.nodeId == 'stepOrphan1'), isTrue);
      expect(warnings.any((w) => w.nodeId == 'stepOrphan2'), isTrue);
    });

    test('Should check wouldCreateCycle correctly to prevent loops', () {
      final script = VisualScript(
        name: 'Cycle Script',
        startNodeId: 'start',
        nodes: {
          'start': StartStep(id: 'start', name: 'Start', nextStepId: 'step1'),
          'step1': IfStep(id: 'step1', name: 'If Node', trueStepId: 'step2', falseStepId: 'step3'),
          'step2': SetVariableStep(id: 'step2', name: 'Set Var', nextStepId: null),
          'step3': AssertValueStep(id: 'step3', name: 'Assert', nextStepId: null),
        },
      );

      // Connecting 'step2' -> 'start' would create a cycle (start -> step1 -> step2 -> start)
      expect(GraphValidator.wouldCreateCycle(script, 'step2', 'start'), isTrue);

      // Connecting 'step2' -> 'step1' would create a cycle (step1 -> step2 -> step1)
      expect(GraphValidator.wouldCreateCycle(script, 'step2', 'step1'), isTrue);

      // Connecting 'step2' -> 'step3' is safe (start -> step1 -> step2 -> step3, no loop)
      expect(GraphValidator.wouldCreateCycle(script, 'step2', 'step3'), isFalse);
    });
  });
}
