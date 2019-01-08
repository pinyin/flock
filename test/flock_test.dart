import 'package:flock/flock.dart';
import 'package:flock/src/EventStorage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matcher/matcher.dart';

void main() {
  group('EventStorage', () {
    final storage = EventStorage<EB>();
    test('should be empty in the beginning', () {
      expect(storage.cursor, 0);
    });
    test('should be able to accept published events', () {
      storage.publish(EB(0));
      storage.publish(EB(1));
      expect(storage.readUpTo(0).last.v, 0);
      expect(storage.readUpTo(0).first.v, 1);
    });
    test('should increase cursor after publish', () {
      expect(storage.cursor, 2);
    });
    test('should support cleanup events', () {
      storage.replaceEvents([]);
      expect(storage.cursor, 0);
      expect(storage.readUpTo(0).isEmpty, true);
    });
  });

  group('flock', () {
    final EventStore<E> eventStore = createEventStore<E>();
    test('should return a valid EventStore', () {
      expect(eventStore, TypeMatcher<EventStore<E>>());
    });
    test('should dispatch event to subscriber', () {
      var value = 0;
      final unsubscribe = eventStore.subscribe((e) {
        if (e is EB) {
          value += e.v;
        }
      });

      eventStore.publish(EA('1'));
      eventStore.publish(EA('2'));
      eventStore.publish(EB(3));
      eventStore.publish(EB(4));

      unsubscribe();
      expect(value, 7);
    });
    var projectCount = 0;
    final projector = (int prev, EventStack<E> events, Projectable<E> store) {
      var result = prev ?? 0;
      for (var event in events) {
        projectCount++;
        if (event is EB)
          result += event.v;
        else if (event is EA) result -= int.tryParse(event.value) ?? 0;
      }
      return result;
    };

    test('should support projection', () {
      final projection = eventStore.projectWith(projector);
      expect(projection, 4);
    });
    test('should cache projection result for the same projector', () {
      final before = projectCount;
      eventStore.projectWith(projector);
      expect(projectCount, before);
      eventStore.publish(EA('1'));
      eventStore.projectWith(projector);
      expect(projectCount, before + 1);
    });
    test('should clean projection cache after events got replaced', () {
      final before = projectCount;
      eventStore.replaceEvents([]);
      eventStore.projectWith(projector);
      expect(projectCount, before);
      eventStore.publish(EA('1'));
      final result = eventStore.projectWith(projector);
      expect(projectCount, before + 1);
      expect(result, -1);
    });
  });
}

class E {}

class EA extends E {
  EA(this.value);

  final String value;
}

class EB extends E {
  EB(this.v);

  final int v;
}
