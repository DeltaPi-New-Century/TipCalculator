import 'package:flutter_test/flutter_test.dart';
import 'package:tip_calculator/schemas/tip.dart';
import 'package:tip_calculator/service/tip_advisor.dart';

void main() {
  group('TipAdvice.fromJson', () {
    test('accepts a well-formed integer response', () {
      final advice = TipAdvice.fromJson({'min': 15, 'avg': 18, 'max': 20});
      expect(advice, isNotNull);
      expect(advice!.avgVal, 18);
    });

    test('accepts percentage strings, which the model still sometimes sends', () {
      final advice = TipAdvice.fromJson({
        'min': '15%',
        'avg': '18%',
        'max': '20%',
      });
      expect(advice?.minVal, 15);
      expect(advice?.maxVal, 20);
    });

    test('accepts zero, for countries where tipping is not customary', () {
      final advice = TipAdvice.fromJson({'min': 0, 'avg': 0, 'max': 0});
      expect(advice, isNotNull);
      expect(advice!.avgVal, 0);
    });

    test('rejects non-numeric text instead of throwing', () {
      // The old implementation called int.parse here and crashed.
      expect(TipAdvice.fromJson({'min': 'lots', 'avg': 'a bit', 'max': '?'}),
          isNull);
    });

    test('rejects missing fields', () {
      expect(TipAdvice.fromJson({'min': 10, 'avg': 15}), isNull);
      expect(TipAdvice.fromJson(const {}), isNull);
    });

    test('rejects out-of-range percentages', () {
      expect(TipAdvice.fromJson({'min': 10, 'avg': 20, 'max': 300}), isNull);
      expect(TipAdvice.fromJson({'min': -5, 'avg': 10, 'max': 20}), isNull);
    });

    test('rejects an incoherent ordering', () {
      // A model that answers min > avg has misunderstood; showing it would be
      // worse than showing nothing.
      expect(TipAdvice.fromJson({'min': 25, 'avg': 10, 'max': 30}), isNull);
      expect(TipAdvice.fromJson({'min': 5, 'avg': 30, 'max': 20}), isNull);
    });

    test('rounds a fractional percentage', () {
      expect(TipAdvice.fromJson({'min': 12.4, 'avg': 17.6, 'max': 20})?.avgVal,
          18);
    });
  });

  group('TipAdvisor.extractJsonObject', () {
    test('returns a bare object unchanged', () {
      expect(
        TipAdvisor.extractJsonObject('{"min":15,"avg":18,"max":20}'),
        '{"min":15,"avg":18,"max":20}',
      );
    });

    test('ignores prose before the object', () {
      // Observed in the wild: the model answered "Here is the JSON" first.
      expect(
        TipAdvisor.extractJsonObject('Here is the JSON:\n{"min":5}'),
        '{"min":5}',
      );
    });

    test('strips a markdown fence', () {
      expect(
        TipAdvisor.extractJsonObject('```json\n{"min":5,"avg":10}\n```'),
        '{"min":5,"avg":10}',
      );
    });

    test('handles a nested object', () {
      expect(
        TipAdvisor.extractJsonObject('x {"a":{"b":1},"c":2} y'),
        '{"a":{"b":1},"c":2}',
      );
    });

    test('is not fooled by braces inside strings', () {
      expect(
        TipAdvisor.extractJsonObject(r'{"note":"a } brace","min":5}'),
        r'{"note":"a } brace","min":5}',
      );
    });

    test('is not fooled by an escaped quote', () {
      expect(
        TipAdvisor.extractJsonObject(r'{"note":"say \"hi\" }","min":5}'),
        r'{"note":"say \"hi\" }","min":5}',
      );
    });

    test('returns null when there is no object', () {
      expect(TipAdvisor.extractJsonObject('Here'), isNull);
      expect(TipAdvisor.extractJsonObject(''), isNull);
    });

    test('returns null on an unbalanced object', () {
      // A truncated response must fail, not yield half a payload.
      expect(TipAdvisor.extractJsonObject('{"min":15,"avg":'), isNull);
    });
  });

  group('message', () {
    test('substitutes every placeholder', () {
      const advice = TipAdvice(minVal: 15, avgVal: 18, maxVal: 20);
      expect(
        advice.message(r'$min-$max% is customary, $avg% typical'),
        '15-20% is customary, 18% typical',
      );
    });

    test('leaves an unrelated template untouched', () {
      const advice = TipAdvice(minVal: 15, avgVal: 18, maxVal: 20);
      expect(advice.message('No placeholders here'), 'No placeholders here');
    });
  });
}
