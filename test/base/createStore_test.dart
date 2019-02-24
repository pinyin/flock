import 'package:flock/flock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matcher/matcher.dart' as Matcher;

void main() {
  group('createStore', () {
    test('should return a valid EventStore', () {
      expect(s, Matcher.TypeMatcher<Store<E>>());
    });
    test('should dispatch event to subscriber', () {
      var value = 0;
      final unsubscribe = s.subscribe(() {
        value += 1;
      });

      s.dispatch(EM('1'));
      s.dispatch(EM('2'));
      s.dispatch(EP(3));
      s.dispatch(EP(4));

      unsubscribe();
      expect(value, 4);
    });

    test('should support state', () {
      var state = s.getState(r, i);
      expect(state, 4);
    });
    test('should cache state result for the same p', () {
      final before = reduceCount;
      final v1 = s.getState(r, i);
      expect(reduceCount, before);
      s.dispatch(EM('1'));
      final v2 = s.getState(r, i);
      expect(v1 - 1, v2);
      expect(reduceCount, before + 1);
    });
    test('should clean state cache after events got replaced', () {
      final before = reduceCount;
      (s as StoreForEnhancer<E>).replaceEvents([]);
      s.getState(r, i);
      expect(reduceCount, before);
      s.dispatch(EM('1'));
      final result = s.getState(r, i);
      expect(reduceCount, before + 1);
      expect(result, -1);
    });
  });
}

class E {}

class EM extends E {
  EM(this.value);

  final String value;
}

class EP extends E {
  EP(this.v);

  final int v;
}

class EQ extends E {
  EQ(this.v);

  final int v;
}

final Store<E> s = createStore<E>([]);

var reduceCount = 0;

int r(int prev, E event) {
  var next = prev;
  reduceCount++;
  if (event is EP)
    next += event.v;
  else if (event is EM)
    next -= int.tryParse(event.value) ?? 0;
  else if (event is EQ) {
    next = event.v;
  }
  return next;
}

int i(List<E> events) {
  return events.fold(0, r);
}

var bBuildCount = 0;
