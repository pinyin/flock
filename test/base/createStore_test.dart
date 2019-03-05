import 'package:flock/flock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matcher/matcher.dart' as Matcher;

import '../MathEvent.dart';

void main() {
  group('createStore', () {
    test('should return a valid EventStore', () {
      final Store<MathEvent> s = createStore<MathEvent>([]);
      expect(s, Matcher.TypeMatcher<Store<MathEvent>>());
    });

    test('should dispatch event to subscriber', () {
      final Store<MathEvent> s = createStore<MathEvent>([]);
      var value = 0;
      final unsubscribe = s.subscribe(() {
        value += 1;
      });

      s.publish(Minus('1'));
      s.publish(Minus('2'));
      s.publish(Plus(3));
      s.publish(Plus(4));

      unsubscribe();
      expect(value, 4);
    });

    test('should return projection', () {
      final Store<MathEvent> s = createStore<MathEvent>([]);
      s.publish(Minus('1'));
      s.publish(Minus('2'));
      s.publish(Plus(3));
      s.publish(Plus(4));
      var state = s.project(sum);
      expect(state, 4);
    });

    test('should cache state result for the same projector', () {
      final Store<MathEvent> s = createStore<MathEvent>([]);
      var projectCount = 0;
      final Projector<int, MathEvent> projector =
          (prev, events) => projectCount++;
      final Projector<int, MathEvent> projector2 =
          (prev, events) => projectCount++;
      s.publish(Minus('1'));
      s.publish(Minus('2'));
      s.publish(Plus(3));
      s.project(projector);
      s.publish(Plus(4));
      s.project(projector);
      expect(projectCount, 2);
      s.project(projector);
      expect(projectCount, 2);
      s.publish(Plus(4));
      s.project(projector2);
      expect(projectCount, 3);
      s.project(projector2);
      expect(projectCount, 3);
    });

    test('should clean state cache after events got replaced', () {
      final Store<MathEvent> s = createStore<MathEvent>([]);
      var projectCount = 0;
      final Projector<int, MathEvent> projector =
          (prev, events) => projectCount++;
      s.publish(Minus('1'));
      s.publish(Minus('2'));
      s.publish(Plus(3));
      s.project(projector);
      s.publish(Plus(4));
      s.project(projector);
      expect(projectCount, 2);
      s.project(projector);
      expect(projectCount, 2);
      (s as StoreForEnhancer<MathEvent>).replaceEvents([], 0);
      s.project(projector);
      expect(projectCount, 3);
      s.project(projector);
      expect(projectCount, 3);
    });
  });
}
