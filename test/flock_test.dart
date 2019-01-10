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
    test('should be able to accept dispatched events', () {
      storage.publish(EP(0));
      storage.publish(EP(1));
      expect(storage.readUpTo(0).last.v, 0);
      expect(storage.readUpTo(0).first.v, 1);
    });
    test('should increase cursor after dispatch', () {
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

    test('should support projection', () {
      var projection = s.getState(p);
      expect(projection, 4);
    });
    test('should cache projection result for the same p', () {
      final before = projectCount;
      s.getState(p);
      expect(projectCount, before);
      s.dispatch(EM('1'));
      s.getState(p);
      expect(projectCount, before + 1);
    });
    test('should clean projection cache after events got replaced', () {
      final before = projectCount;
      (s as InnerStore<E>).replaceEvents([]);
      s.getState(p);
      expect(projectCount, before);
      s.dispatch(EM('1'));
      final result = s.getState(p);
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
      s.dispatch(EP(1));
      await tester.pump();
      expect(initialTester, findsNothing);
      expect(updatedTester, findsOneWidget);
    });

    testWidgets('should support builder pattern', (WidgetTester tester) async {
      await tester.pumpWidget(BW());
      expect(find.text('0'), findsOneWidget);
      s.dispatch(EP(1));
      await tester.pump();
      expect(find.text('1'), findsOneWidget);
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
      '${widget.store.getState(p)}',
      textDirection: TextDirection.ltr,
    );
  }

  @override
  void setState(fn) {
    super.setState(fn);
  }
}

class BW extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StoreBuilder(
      build: (BuildContext context, int p) =>
          Text(
            '$p',
            textDirection: TextDirection.ltr,
          ),
      store: s,
      projector: p,
    );
  }
}
