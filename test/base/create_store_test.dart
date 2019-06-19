import 'package:flock/flock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matcher/matcher.dart' as Matcher;

import '../test_utils.dart';

void main() {
  group('createStore', () {
    test('should return a valid EventStore', () {
      final Store s = createStore();
      expect(s, Matcher.TypeMatcher<Store>());
    });

    test('should dispatch event to subscriber', () {
      final Store s = createStore();
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
      final Store s = createStore();
      s.publish(Minus('1'));
      s.publish(Minus('2'));
      s.publish(Plus(3));
      s.publish(Plus(4));
      var state = s.project(sum);
      expect(state, 4);
    });

    test('should cache state result for the same projector', () {
      final Store s = createStore();
      var projectCount = 0;
      final Projector<int> projector = (prev, events, _) => projectCount++;
      final Projector<int> projector2 = (prev, events, _) => projectCount++;
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

    test('should clean cache iff events got replaced & cursor was changed', () {
      final Store s = createStore();
      var eventsCount = 0;
      final Projector<int> projector =
          (prev, events, _) => eventsCount += events.length;
      s.publish(Minus('1'));
      s.publish(Minus('2'));
      s.publish(Plus(3));
      s.project(projector);
      s.publish(Plus(4));
      s.project(projector);
      expect(eventsCount, 4);
      (s as StoreForEnhancer).rewriteHistory(QueueList()..add(Plus(1)), 1);
      s.project(projector);
      expect(eventsCount, 5);
      (s as StoreForEnhancer).rewriteHistory(QueueList()..add(Plus(1)), 1);
      s.project(projector);
      expect(eventsCount, 5);
    });
  });
}
