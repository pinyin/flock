import 'package:flock/flock.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_utils.dart';

void main() {
  group('onlyPublishWhen', () {
    test('should only publish value when filter returns true', () async {
      final store = createStore(enhancers: [
        onlyPublishWhen(
            (store) => (event) => store.project(sum) < 1 || event is Minus)
      ]);
      var emitCount = 0;
      store.subscribe(() => emitCount++);
      store.publish(Plus(1));
      expect(store.project(sum), 1);
      store.publish(Plus(1));
      expect(store.project(sum), 1);
      store.publish(Minus('1'));
      expect(store.project(sum), 0);
    });
  });
}
