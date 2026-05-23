import 'package:flutter_test/flutter_test.dart';
import 'package:fletch/utils/converters/format_detector.dart';

void main() {
  group('FormatDetector', () {
    // ── Native ────────────────────────────────────────────────────────────────

    group('native format', () {
      test('detects a list with workspaceId key as native', () {
        final input = [
          {'id': '1', 'workspaceId': 'ws-1', 'name': 'col', 'requests': []},
        ];
        expect(FormatDetector.detect(input), CollectionFormat.native);
      });

      test('detects a list with requests key as native', () {
        final input = [
          {'id': '1', 'requests': [], 'name': 'col'},
        ];
        expect(FormatDetector.detect(input), CollectionFormat.native);
      });

      test('returns native for an empty list', () {
        expect(FormatDetector.detect([]), CollectionFormat.native);
      });
    });

    // ── Postman ───────────────────────────────────────────────────────────────

    group('postman format', () {
      test('detects info.schema containing postman.com', () {
        final input = {
          'info': {
            'name': 'My API',
            'schema': 'https://schema.getpostman.com/json/collection/v2.1.0/',
          },
          'item': [],
        };
        expect(FormatDetector.detect(input), CollectionFormat.postman);
      });

      test('detects item + info without schema as postman fallback', () {
        final input = {
          'info': {'name': 'My API'},
          'item': [],
        };
        expect(FormatDetector.detect(input), CollectionFormat.postman);
      });

      test('does not detect as postman when info is absent', () {
        final input = {'item': []};
        expect(FormatDetector.detect(input), isNot(CollectionFormat.postman));
      });
    });

    // ── Insomnia ──────────────────────────────────────────────────────────────

    group('insomnia format', () {
      test('detects resources + __export_format as insomnia', () {
        final input = {
          '__export_format': 4,
          'resources': [],
        };
        expect(FormatDetector.detect(input), CollectionFormat.insomnia);
      });

      test('detects type containing "insomnia" as insomnia', () {
        // Note: check against the actual key used by FormatDetector
        final input2 = {
          'type': 'insomnia/3',
          'resources': [],
        };
        expect(FormatDetector.detect(input2), CollectionFormat.insomnia);
      });

      test('detects schema_version + collection as insomnia', () {
        final input = {
          'schema_version': '2.1',
          'collection': {},
        };
        expect(FormatDetector.detect(input), CollectionFormat.insomnia);
      });
    });

    // ── Unknown ───────────────────────────────────────────────────────────────

    group('unknown format', () {
      test('returns unknown for an empty map', () {
        expect(FormatDetector.detect({}), CollectionFormat.unknown);
      });

      test('returns unknown for unrecognised list items', () {
        final input = [
          {'foo': 'bar'},
        ];
        expect(FormatDetector.detect(input), CollectionFormat.unknown);
      });

      test('returns unknown for a plain string', () {
        expect(FormatDetector.detect('not-valid'), CollectionFormat.unknown);
      });

      test('returns unknown for null', () {
        expect(FormatDetector.detect(null), CollectionFormat.unknown);
      });
    });
  });
}
