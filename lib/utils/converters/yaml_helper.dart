import 'package:yaml/yaml.dart';

class YamlHelper {
  static dynamic yamlToDart(dynamic node) {
    if (node is YamlMap) {
      return node.map((key, value) => MapEntry(key.toString(), yamlToDart(value)));
    } else if (node is YamlList) {
      return node.map(yamlToDart).toList();
    } else {
      return node;
    }
  }

  static dynamic parse(String content) {
    final yaml = loadYaml(content);
    return yamlToDart(yaml);
  }

  static String toYaml(dynamic value, {int indentLevel = 0}) {
    if (value == null) {
      return 'null';
    }
    if (value is bool) {
      return value ? 'true' : 'false';
    }
    if (value is num) {
      return value.toString();
    }
    if (value is String) {
      if (value.isEmpty) {
        return '""';
      }
      if (value.contains('\n')) {
        final endsWithNewline = value.endsWith('\n');
        final indicator = endsWithNewline ? '|\n' : '|-\n';
        final lines = endsWithNewline
            ? value.substring(0, value.length - 1).split('\n')
            : value.split('\n');

        final indent = '  ' * (indentLevel + 1);
        final buffer = StringBuffer(indicator);
        for (var i = 0; i < lines.length; i++) {
          buffer.write(indent);
          buffer.write(lines[i]);
          if (i < lines.length - 1) {
            buffer.write('\n');
          }
        }
        return buffer.toString();
      }
      // Check if it needs quotes
      final isReserved = ['true', 'false', 'null'].contains(value.toLowerCase());
      final isNumeric = double.tryParse(value) != null;
      final hasSpecialChar = value.contains(RegExp(r'''[:#\[\]\{\},*&!|>\'"%@`]''')) ||
          value.startsWith('-') ||
          value.startsWith('?') ||
          value.startsWith(' ') ||
          value.endsWith(' ');

      if (isReserved || isNumeric || hasSpecialChar) {
        final escaped = value
            .replaceAll('\\', '\\\\')
            .replaceAll('"', '\\"')
            .replaceAll('\r', '\\r')
            .replaceAll('\t', '\\t');
        return '"$escaped"';
      }
      return value;
    }
    if (value is List) {
      if (value.isEmpty) {
        return '[]';
      }
      final buffer = StringBuffer();
      final indent = '  ' * indentLevel;
      var first = true;
      for (var item in value) {
        if (!first) {
          buffer.write('\n');
        }
        first = false;
        buffer.write('$indent-');
        if (item is Map) {
          if (item.isEmpty) {
            buffer.write(' {}');
          } else {
            final mapEntries = item.entries.toList();
            final firstEntry = mapEntries.first;
            buffer.write(' ${firstEntry.key}:');
            if (firstEntry.value is Map || firstEntry.value is List) {
              if (firstEntry.value.isEmpty) {
                buffer.write(firstEntry.value is Map ? ' {}' : ' []');
              } else {
                buffer.write('\n');
                buffer.write(toYaml(firstEntry.value, indentLevel: indentLevel + 2));
              }
            } else {
              buffer.write(' ${toYaml(firstEntry.value, indentLevel: indentLevel + 2)}');
            }
            for (var i = 1; i < mapEntries.length; i++) {
              final entry = mapEntries[i];
              final entryIndent = '  ' * (indentLevel + 1);
              buffer.write('\n$entryIndent${entry.key}:');
              if (entry.value is Map || entry.value is List) {
                if (entry.value.isEmpty) {
                  buffer.write(entry.value is Map ? ' {}' : ' []');
                } else {
                  buffer.write('\n');
                  buffer.write(toYaml(entry.value, indentLevel: indentLevel + 2));
                }
              } else {
                buffer.write(' ${toYaml(entry.value, indentLevel: indentLevel + 2)}');
              }
            }
          }
        } else if (item is List) {
          if (item.isEmpty) {
            buffer.write(' []');
          } else {
            buffer.write('\n');
            buffer.write(toYaml(item, indentLevel: indentLevel + 1));
          }
        } else {
          buffer.write(' ${toYaml(item, indentLevel: indentLevel + 1)}');
        }
      }
      return buffer.toString();
    }
    if (value is Map) {
      if (value.isEmpty) {
        return '{}';
      }
      final buffer = StringBuffer();
      final indent = '  ' * indentLevel;
      var first = true;
      value.forEach((k, v) {
        if (!first) {
          buffer.write('\n');
        }
        first = false;
        buffer.write('$indent$k:');
        if (v is Map || v is List) {
          if (v.isEmpty) {
            buffer.write(v is Map ? ' {}' : ' []');
          } else {
            buffer.write('\n');
            buffer.write(toYaml(v, indentLevel: indentLevel + 1));
          }
        } else {
          buffer.write(' ${toYaml(v, indentLevel: indentLevel + 1)}');
        }
      });
      return buffer.toString();
    }
    return value.toString();
  }
}

