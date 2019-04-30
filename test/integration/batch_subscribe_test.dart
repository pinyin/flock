import 'package:flock/flock.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_utils.dart';

void main() {
  group('batchSubscribe', () {
    test('should batch subscriber() calls', () async {
      final store = createStore<MathEvent>([], [
        batchSubscribe((run) async {
          await Future<void>.delayed(Duration(milliseconds: 200));
          run();
        })
      ]);
      var emitCount = 0;
      store.subscribe(() => emitCount++);
      store.publish(Plus(1));
      store.publish(Plus(1));
      expect(emitCount, 0);
      await Future<void>.delayed(Duration(milliseconds: 100));
      expect(emitCount, 0);
      await Future<void>.delayed(Duration(milliseconds: 100));
      expect(emitCount, 1);
    });
  });
}
