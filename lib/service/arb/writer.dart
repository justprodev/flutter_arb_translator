import 'dart:convert';
import 'dart:io';

import '../log/logger.dart';

import '../../models/arb_content.dart';

/// Responsible for writing [ARBContent] to a given file
class ARBWriter {
  final ARBContent content;
  final Logger logger;

  const ARBWriter(
    this.content, {
    required this.logger,
  });

  /// [filePath] - absolute path to which [content] should be written to
  void writeToFile(String filePath) {
    logger.info('Write arb content fo file $filePath');
    final json = _encodeToJson();
    final fileContent = _insertLineBreaks(json);

    final f = File(filePath);
    f.writeAsStringSync(fileContent);
  }

  String _encodeToJson() {
    final items = content.items.toList();
    logger.info('Encode ${items.length} items');

    items.sort((x, y) => x.number.compareTo(y.number));

    final encodedItems = items.map((x) => _arbItemToJson(x)).toList();

    if (content.locale != null) {
      encodedItems.insert(0, {
        '@@locale': content.locale!,
      });
    }

    final merged = Map.fromEntries(encodedItems.expand((m) => m.entries));

    logger.info('Total json entries count: ${merged.length}');

    final jsonEncoder = JsonEncoder.withIndent('  ');

    return jsonEncoder.convert(merged);
  }

  String _insertLineBreaks(String json) {
    if (content.lineBreaks.isEmpty) {
      logger.info('No line breaks to insert');
      return json;
    }

    final lines = json.split('\n');
    for (final lineBreakIndex in content.lineBreaks) {
      if (lineBreakIndex >= 0 && lineBreakIndex < lines.length) {
        lines.insert(lineBreakIndex, '');
      }
    }

    return lines.join('\n');
  }

  Map<String, dynamic> _arbItemToJson(ARBItem item) {
    Map<String, dynamic> result = {};
    result[item.key] = item.value;
    if (item.annotation != null && item.annotation?.isAutoGen == false) {
      result['@${item.key}'] = _annotationToJson(item.annotation!);
    }
    return result;
  }

  Map<String, dynamic> _annotationToJson(ARBItemAnnotation annotation) {
    Map<String, dynamic> annotationEntries = {};

    if (annotation.description != null) {
      annotationEntries['description'] = annotation.description!;
    }

    if (annotation.placeholders.isNotEmpty) {
      final placeholdersJson =
          annotation.placeholders.map((x) => _placeholderToJson(x)).toList();
      final merged = Map.fromEntries(placeholdersJson.expand((m) => m.entries));
      annotationEntries['placeholders'] = merged;
    }

    return annotationEntries;
  }

  Map<String, dynamic> _placeholderToJson(
      ARBItemAnnotationPlaceholder placeholder) {
    Map<String, dynamic> placeholderEntries = {};

    if (placeholder.type != null) {
      placeholderEntries['type'] = placeholder.type;
    }

    if (placeholder.example != null) {
      placeholderEntries['example'] = placeholder.example;
    }

    if (placeholder.format != null) {
      placeholderEntries['format'] = placeholder.format!;
    }

    return {placeholder.key: placeholderEntries};
  }
}
