import 'package:flock/flock.dart';
import 'package:test/test.dart';

import '../test_utils.dart';

void main() {
  group('use case context', () {
    // todo add more tests
    test('should automatically create use case hierachy', () async {
      final effectLog = <Object>[];
      final store = createStore(enhancers: [
        withUseCaseActors((_) {
          return (events, store) async* {
            await for (final event in events) {
              effectLog.add(event);
            }
          };
        }),
      ]);
      store.publish(Plus(1));
      await Future<Object>.delayed(Duration(milliseconds: 10));
      expect(effectLog.length, 0);
      final create1 = UseCaseCreated(UseCaseID.root);
      store.publish(create1);
      await Future<Object>.delayed(Duration(milliseconds: 10));
      expect(effectLog, [create1]);
      final create2 = UseCaseCreated(UseCaseID.root);
      store.publish(create2);
      await Future<Object>.delayed(Duration(milliseconds: 10));
      expect(effectLog, [create1, create2]);
      final create3 = UseCaseCreated(create2.context);
      store.publish(create3);
      await Future<Object>.delayed(Duration(milliseconds: 10));
      expect(effectLog, [create1, create2, create3, create3]);
      final end2 = UseCaseEnded(create2.context);
      store.publish(end2);
      final create4 = UseCaseCreated(create2.context);
      store.publish(create4);
      final update3 = UseCaseUpdated(create2.context);
      store.publish(update3);
      await Future<Object>.delayed(Duration(milliseconds: 10));
      expect(effectLog, [create1, create2, create3, create3, end2]);
    });

    test('should restart use case hierachy after cursor update', () async {
      final effectLog = <Object>[];
      final store = createStore(enhancers: [
        withUseCaseActors((create) {
          return (events, store) async* {
            final useCaseMap = store.project(toUseCaseMap);
            useCaseMap.events(create.context).forEach(effectLog.add);
          };
        }),
      ]);
      final create1 = UseCaseCreated(UseCaseID.root);
      final create2 = UseCaseCreated(create1.context);
      final end2 = UseCaseEnded(create2.context);

      store.publish(create1);
      store.publish(create2);
      store.publish(end2);
      await Future<Object>.delayed(Duration(milliseconds: 10));
      expect(effectLog, [create1, create2, end2, create2, end2]);
      effectLog.clear();

      store.rewriteHistory(
          QueueList.from([create1, create2, end2]), store.cursor + 3);
      await Future<Object>.delayed(Duration(milliseconds: 10));
      expect(effectLog, [create1, create2, end2]);
    });
  });
}
