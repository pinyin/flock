import 'package:flock/flock.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Flutter Builder integration', () {
    testWidgets('should create state on build', (WidgetTester tester) async {
      final Store<E> s = createStore<E>([]);
      s.dispatch(EQ(0));
      await tester.pumpWidget(BW(s: s));
      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('should update widget with store', (WidgetTester tester) async {
      final Store<E> s = createStore<E>([]);
      s.dispatch(EQ(0));
      await tester.pumpWidget(BW(s: s));
      expect(find.text('0'), findsOneWidget);
      s.dispatch(EP(1));
      await tester.pump();
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('should not rebuild widgets unless state is changed',
        (WidgetTester tester) async {
          final Store<E> s = createStore<E>([]);
          await tester.pumpWidget(BW(s: s));
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

var bwBuildCount = 0;

class BW extends StatelessWidget {
  BW({@required this.s}) : super();

  final Store<E> s;

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
