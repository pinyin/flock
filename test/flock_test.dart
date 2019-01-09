import 'package:flock/flock.dart';
import 'package:flock/src/EventStorage.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matcher/matcher.dart' as Matcher;

void main() {
  group('EventStorage', () {
    final storage = EventStorage<EP>();
    test('should be empty in the beginning', () {
      expect(storage.cursor, 0);
    });
    test('should be able to accept published events', () {
      storage.publish(EP(0));
      storage.publish(EP(1));
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
    test('createStore should return a valid EventStore', () {
      expect(s, Matcher.TypeMatcher<Store<E>>());
    });
    test('should dispatch event to subscriber', () {
      var value = 0;
      final unsubscribe = s.subscribe((e) {
        if (e is EP) {
          value += e.v;
        }
      });

      s.publish(EM('1'));
      s.publish(EM('2'));
      s.publish(EP(3));
      s.publish(EP(4));

      unsubscribe();
      expect(value, 7);
    });

    test('should support projection', () {
      var projection = s.projectWith(p);
      expect(projection, 4);
      projection = s.get(p);
      expect(projection, 4);
    });
    test('should cache projection result for the same p', () {
      final before = projectCount;
      s.projectWith(p);
      expect(projectCount, before);
      s.publish(EM('1'));
      s.projectWith(p);
      expect(projectCount, before + 1);
    });
    test('should clean projection cache after events got replaced', () {
      final before = projectCount;
      (s as InnerStore<E>).replaceEvents([]);
      s.projectWith(p);
      expect(projectCount, before);
      s.publish(EM('1'));
      final result = s.projectWith(p);
      expect(projectCount, before + 1);
      expect(result, -1);
    });
  });

  group('Flutter integration', () {
    testWidgets('should show initial state', (WidgetTester tester) async {
      await tester.pumpWidget(W());
      final initialTester = find.text('-1');
      expect(initialTester, findsOneWidget);
    });

    testWidgets('should update widget with store', (WidgetTester tester) async {
      await tester.pumpWidget(W());
      final initialTester = find.text('-1');
      final updatedTester = find.text('0');
      expect(initialTester, findsOneWidget);
      expect(updatedTester, findsNothing);
      s.publish(EP(1));
      await tester.pump();
      expect(initialTester, findsNothing);
      expect(updatedTester, findsOneWidget);
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

final Store<E> s = createStore<E>();

var projectCount = 0;

int p(int prev, EventStack<E> events, Projectable<E> store) {
  var result = prev ?? 0;
  for (var event in events) {
    projectCount++;
    if (event is EP)
      result += event.v;
    else if (event is EM) result -= int.tryParse(event.value) ?? 0;
  }
  return result;
}

class W extends StoreWidget<E> {
  final Store<E> store = s;

  @override
  State<StatefulWidget> createState() {
    return S();
  }
}

class S extends StoreState<W, E> {
  @override
  Widget build(BuildContext context) {
    return Text(
      '${widget.store.get(p)}',
      textDirection: TextDirection.ltr,
    );
  }

  @override
  void setState(fn) {
    super.setState(fn);
  }
}
