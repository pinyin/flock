import 'package:flock/enhancers/compress_history.dart';
import 'package:flock/flock.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('compressHistory', () {
    test('should be able to rewrite history', () async {
      final StoreForEnhancer store = createStore(enhancers: [
        compressHistory((store) {
          if (store.history.length > 3) store.history.removeFirst();
        }),
      ]);
      store.publish(1);
      store.publish(2);
      store.publish(3);
      expect(store.history, [1, 2, 3]);
      store.publish(4);
      expect(store.history, [2, 3, 4]);
    });
  });
}
