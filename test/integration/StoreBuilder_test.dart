import 'package:flock/flock.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../MathEvent.dart';

void main() {
  group('StoreBuilder', () {
    testWidgets('should render child widget', (tester) async {
      final store = createStore<MathEvent>();
      await tester.pumpWidget(StoreBuilder<MathEvent, int>(
        projector: sum,
        builder: (context, sum) => Container(
                child: Text(
              sum.toString(),
              textDirection: TextDirection.ltr,
            )),
        store: store,
      ));
      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('should update child widget iff projection updates',
        (tester) async {
      final store = createStore<MathEvent>();
      var renderCount = 0;
      await tester.pumpWidget(StoreBuilder<MathEvent, int>(
        projector: sum,
        builder: (context, sum) {
          renderCount++;
          return Container(
              child: Text(
            sum.toString(),
            textDirection: TextDirection.ltr,
          ));
        },
        store: store,
      ));
      expect(find.text('0'), findsOneWidget);
      expect(renderCount, 1);
      store.publish(Plus(1));
      await tester.pump();
      expect(find.text('1'), findsOneWidget);
      expect(renderCount, 2);
      store.publish(Plus(0));
      await tester.pump();
      expect(find.text('1'), findsOneWidget);
      expect(renderCount, 2);
    });
  });
}
