import 'dart:async';

import 'package:flock/flock.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_utils.dart';

void main() {
  group('withUseCase', () {
    test('should be able to transform events', () async {
      final store = createStore<MathEvent>([], [withUseCase(add1When3)]);
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

Stream<MathEvent> add1When3(Stream<MathEvent> events,
    P Function<P>(Projector<P, MathEvent> projector) project) async* {
  await for (final event in events) {
    yield event;
    if (project(sum) == 3) {
      yield Plus(1);
    }
  }
}
