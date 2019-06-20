import 'dart:async';

import 'package:flock/flock.dart';
import 'package:test/test.dart';

import '../test_utils.dart';

void main() {
  group('withSideEffect', () {
    test('should be able to transform events', () async {
      final store = createStore(enhancers: [withSideEffect(add1When3)]);
      store.publish(Plus(1));
      store.publish(Plus(1));
      await Future(() {});
      expect(store.project(sum), 2);
      store.publish(Plus(1));
      await Future(() {});
      expect(store.project(sum), 4);
    });
  });
}

Stream<MathEvent> add1When3(Stream events, Projectable store) async* {
  await for (final event in events) {
    if (store.project(sum) == 3) {
      yield Plus(1);
    }
  }
}
