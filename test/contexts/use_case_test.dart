import 'package:flock/flock.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_utils.dart';

void main() {
  group('use case context', () {
    // todo add more tests
    test('should automatically create use case hierachy', () async {
      final actual = <Object>[];
      final store = createStore(enhancers: [
        withUseCaseEffects((_) {
          return (events, store) async* {
            await for (final event in events) {
              actual.add(event);
            }
          };
        }),
      ]);
      store.publish(Plus(1));
      await Future<Object>.delayed(Duration(milliseconds: 10));
      expect(actual.length, 0);
      final event1 = UseCaseCreated(Plus(1), UseCaseID.root);
      store.publish(event1);
      await Future<Object>.delayed(Duration(milliseconds: 10));
      expect(actual, [event1]);
      final event2 = UseCaseCreated(Plus(1), UseCaseID.root);
      store.publish(event2);
      await Future<Object>.delayed(Duration(milliseconds: 10));
      expect(actual, [event1, event2]);
      final event3 = UseCaseCreated(Plus(1), event2.context);
      store.publish(event3);
      await Future<Object>.delayed(Duration(milliseconds: 10));
      expect(actual, [event1, event2, event3, event3]);
      final end2Event = UseCaseEnded(event2.context);
      store.publish(end2Event);
      final event4 = UseCaseCreated(Plus(1), event2.context);
      store.publish(event4);
      await Future<Object>.delayed(Duration(milliseconds: 10));
      expect(actual, [event1, event2, event3, event3, end2Event]);
    });
  });
}
