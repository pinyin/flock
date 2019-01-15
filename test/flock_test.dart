import 'package:flock/flock.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matcher/matcher.dart' as Matcher;

void main() {
  group('createStore', () {
    test('should return a valid EventStore', () {
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

    test('should support state', () {
      var state = s.getState(r, i);
      expect(state, 4);
    });
    test('should cache state result for the same p', () {
      final before = reduceCount;
      final v1 = s.getState(r, i);
      expect(reduceCount, before);
      s.dispatch(EM('1'));
      final v2 = s.getState(r, i);
      expect(v1 - 1, v2);
      expect(reduceCount, before + 1);
    });
    test('should clean state cache after events got replaced', () {
      final before = reduceCount;
      (s as StoreForEnhancer<E>).replaceEvents([]);
      s.getState(r, i);
      expect(reduceCount, before);
      s.dispatch(EM('1'));
      final result = s.getState(r, i);
      expect(reduceCount, before + 1);
      expect(result, -1);
    });
  });

  group('Flutter State integration', () {
    testWidgets('should create state on build', (WidgetTester tester) async {
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

    testWidgets('should not rebuild widgets unless state is changed',
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
    testWidgets('should create state on build', (WidgetTester tester) async {
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

    testWidgets('should not rebuild widgets unless state is changed',
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

final Store<E> s = createStore<E>([]);

var reduceCount = 0;

int r(int prev, E event) {
  var next = prev;
  reduceCount++;
  if (event is EP)
    next += event.v;
  else if (event is EM)
    next -= int.tryParse(event.value) ?? 0;
  else if (event is EQ) {
    next = event.v;
  }
  return next;
}

int i(List<E> events) {
  return events.fold(0, r);
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
    return Text('${state.toString()}', textDirection: TextDirection.ltr);
  }

  @override
  int initializer(List<E> events) {
    return i(events);
  }

  @override
  int reducer(int cached, E event) {
    return r(cached, event);
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
      initializer: i,
      store: s,
      reducer: r,
    );
  }
}
