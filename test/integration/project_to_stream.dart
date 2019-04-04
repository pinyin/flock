import 'package:flock/flock.dart';
import 'package:test_api/test_api.dart';

import '../test_utils.dart';

void main() {
  group('project to stream', () {
    test('should return value iff projection is updated', () async {
      final store = createStore<MathEvent>();
      final sum$ = projectToStream(store, sum);
      final results = <int>[];
      sum$.listen(results.add);
      store.publish(Plus(1));
      store.publish(Plus(1));
      store.publish(Plus(1));
      // streams are asynchronous
      await Future<void>.delayed(Duration(milliseconds: 10));
      expect(results, [1, 2, 3]);
      store.publish(Plus(0));
      await Future<void>.delayed(Duration(milliseconds: 10));
      expect(results, [1, 2, 3]);
    });
  });
}
