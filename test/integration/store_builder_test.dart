import 'package:flock/flock.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_utils.dart';

void main() {
  group('StoreBuilder', () {
    testWidgets('should render child widget', (tester) async {
      final store = createStore();
      await tester.pumpWidget(StoreBuilder<int>(
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
  });
}
