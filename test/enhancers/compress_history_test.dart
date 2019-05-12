import 'package:flock/enhancers/compress_history.dart';
import 'package:flock/flock.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('onlyPublishWhen', () {
    test('should only publish value when filter returns true', () async {
      final StoreForEnhancer store = createStore(enhancers: [
        compressHistory((store) {
          if (store.events.length > 3) store.events.removeFirst();
        }),
      ]);
      store.publish(1);
      store.publish(2);
      store.publish(3);
      expect(store.events, [1, 2, 3]);
      store.publish(4);
      expect(store.events, [2, 3, 4]);
    });
  });
}
