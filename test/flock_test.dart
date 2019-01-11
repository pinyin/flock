import 'package:flock/flock.dart';
import 'package:flock/src/base/EventStorage.dart';
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
      expect(storage
          .readSince(0)
          .first
          .v, 0);
      expect(storage
          .readSince(0)
          .last
          .v, 1);
      expect(storage
          .readSince(0)
          .reversed
          .first
          .v, 1);
      expect(storage
          .readSince(0)
          .reversed
          .last
          .v, 0);
      expect(storage
          .readSince(1)
          .first
          .v, 1);
    });
    test('should increase cursor after dispatch', () {
      expect(storage.cursor, 2);
    });
    test('should support cleanup events', () {
      storage.replaceEvents([]);
      expect(storage.cursor, 0);
      expect(storage
          .readSince(0)
          .isEmpty, true);
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

  group('Flutter State integration', () {
    testWidgets('should create projection on build',
            (WidgetTester tester) async {
          s.dispatch(EQ(0));
          await tester.pumpWidget(B());
          expect(find.text('0'), findsOneWidget);
        });

    testWidgets('should update widget with store', (WidgetTester tester) async {
      s.dispatch(EQ(0));
      await tester.pumpWidget(B());
      expect(find.text('0'), findsOneWidget);
      s.dispatch(EP(1));
      await tester.pump();
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('should not rebuild widgets unless projection is changed',
            (WidgetTester tester) async {
          await tester.pumpWidget(B());
          var buildCount = bBuildCount;
          s.dispatch(EP(0));
          await tester.pump();
          expect(bBuildCount, buildCount);
          s.dispatch(EP(1));
          await tester.pump();
          expect(bBuildCount, buildCount + 1);
          s.dispatch(EP(0));
          await tester.pump();
          expect(bBuildCount, buildCount + 1);
        });
  });

  group('Flutter Builder integration', () {
    testWidgets('should create projection on build',
            (WidgetTester tester) async {
          s.dispatch(EQ(0));
          await tester.pumpWidget(BW());
          expect(find.text('0'), findsOneWidget);
    });

    testWidgets('should update widget with store', (WidgetTester tester) async {
      s.dispatch(EQ(0));
      await tester.pumpWidget(BW());
      expect(find.text('0'), findsOneWidget);
      s.dispatch(EP(1));
      await tester.pump();
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('should not rebuild widgets unless projection is changed',
            (WidgetTester tester) async {
          await tester.pumpWidget(BW());
          var buildCount = bwBuildCount;
          s.dispatch(EP(0));
          await tester.pump();
          expect(bwBuildCount, buildCount);
          s.dispatch(EP(1));
          await tester.pump();
          expect(bwBuildCount, buildCount + 1);
          s.dispatch(EP(0));
          await tester.pump();
          expect(bwBuildCount, buildCount + 1);
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

class EQ extends E {
  EQ(this.v);

  final int v;
}

final Store<E> s = createStore<E>();

var projectCount = 0;

int p(int prev, Events<E> events) {
  var result = prev ?? 0;
  debugPrint(events.toString());
  for (var event in events) {
    projectCount++;
    if (event is EP)
      result += event.v;
    else if (event is EM)
      result -= int.tryParse(event.value) ?? 0;
    else if (event is EQ) {
      result = event.v;
    }
  }
  return result;
}

var bBuildCount = 0;

class B extends StoreWidget<E> {
  final store = s;

  @override
  State<StatefulWidget> createState() {
    return BS();
  }
}

class BS extends StoreState<B, E, int> {
  @override
  Widget build(BuildContext context) {
    bBuildCount++;
    return Text('${projection.toString()}', textDirection: TextDirection.ltr);
  }

  @override
  int projector(int cached, Events<E> events) {
    return p(cached, events);
  }
}

var bwBuildCount = 0;

class BW extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StoreBuilder(
      builder: (BuildContext context, int p) {
        bwBuildCount++;
        return Text(
          '$p',
          textDirection: TextDirection.ltr,
        );
      },
      store: s,
      projector: p,
    );
  }
}
