import 'dart:convert';
import 'package:xml/xml.dart' as xml_pkg;
import 'package:fletch/utils/script_compiler.dart';

class CompiledXmlConvertStep extends CompiledStep {
  final String? nextStepId;
  final String operation;
  final CompiledValueSource valueSource;
  final String saveToVariable;

  CompiledXmlConvertStep({
    required super.id,
    required super.name,
    this.nextStepId,
    required this.operation,
    required this.valueSource,
    required this.saveToVariable,
  });

  @override
  Future<ExecutionResult> execute(ExecutionContext context, Map<String, CompiledStep> nodes) async {
    final value = valueSource.resolve(context);

    try {
      if (operation == 'xmlToJson') {
        final document = xml_pkg.XmlDocument.parse(value);
        final Map<String, dynamic> result = _xmlNodeToMap(document.rootElement);
        context.variables[saveToVariable] = jsonEncode(result);
        context.log(id, name, 'XML convertido para JSON em "$saveToVariable".', level: LogLevel.info);
      } else {
        final decoded = jsonDecode(value);
        final builder = xml_pkg.XmlBuilder();
        builder.processing('xml', 'version="1.0" encoding="UTF-8"');
        _buildXmlFromJson(builder, 'root', decoded);
        final xmlDoc = builder.buildDocument();
        context.variables[saveToVariable] = xmlDoc.toXmlString(pretty: true);
        context.log(id, name, 'JSON convertido para XML em "$saveToVariable".', level: LogLevel.info);
      }
    } catch (e) {
      context.log(id, name, 'Erro na conversão XML ($operation): $e', level: LogLevel.error);
      return ExecutionResult(success: false, error: e.toString());
    }

    return ExecutionResult(success: true, nextNodeId: nextStepId);
  }

  Map<String, dynamic> _xmlNodeToMap(xml_pkg.XmlElement element) {
    final Map<String, dynamic> map = {};
    for (var attr in element.attributes) {
      map['@${attr.name.local}'] = attr.value;
    }
    
    final children = element.children.whereType<xml_pkg.XmlElement>();
    if (children.isEmpty) {
      if (map.isEmpty) {
        return {'#text': element.innerText};
      } else {
        map['#text'] = element.innerText;
        return map;
      }
    }

    for (var child in children) {
      final childMap = _xmlNodeToMap(child);
      final key = child.name.local;
      if (map.containsKey(key)) {
        if (map[key] is List) {
          (map[key] as List).add(childMap);
        } else {
          map[key] = [map[key], childMap];
        }
      } else {
        map[key] = childMap;
      }
    }
    return map;
  }

  void _buildXmlFromJson(xml_pkg.XmlBuilder builder, String name, dynamic data) {
    if (data is Map) {
      builder.element(name, nest: () {
        data.forEach((k, v) {
          if (k.startsWith('@')) {
            builder.attribute(k.substring(1), v.toString());
          } else if (k == '#text') {
            builder.text(v.toString());
          } else if (v is List) {
            for (var item in v) {
              _buildXmlFromJson(builder, k, item);
            }
          } else {
            _buildXmlFromJson(builder, k, v);
          }
        });
      });
    } else if (data is List) {
      for (var item in data) {
        _buildXmlFromJson(builder, name, item);
      }
    } else {
      builder.element(name, nest: () {
        builder.text(data.toString());
      });
    }
  }
}
