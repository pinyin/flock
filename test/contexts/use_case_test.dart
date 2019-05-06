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
      final create1 = UseCaseCreated(Plus(1), UseCaseID.root);
      store.publish(create1);
      await Future<Object>.delayed(Duration(milliseconds: 10));
      expect(actual, [create1]);
      final create2 = UseCaseCreated(Plus(1), UseCaseID.root);
      store.publish(create2);
      await Future<Object>.delayed(Duration(milliseconds: 10));
      expect(actual, [create1, create2]);
      final create3 = UseCaseCreated(Plus(1), create2.context);
      store.publish(create3);
      await Future<Object>.delayed(Duration(milliseconds: 10));
      expect(actual, [create1, create2, create3, create3]);
      final end2 = UseCaseEnded(create2.context);
      store.publish(end2);
      final create4 = UseCaseCreated(Plus(1), create2.context);
      store.publish(create4);
      final update3 = UseCaseUpdated(create3.context, null);
      store.publish(update3);
      await Future<Object>.delayed(Duration(milliseconds: 10));
      expect(actual, [create1, create2, create3, create3, end2]);
    });
  });
}
