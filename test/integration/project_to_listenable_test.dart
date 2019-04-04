import 'package:flock/flock.dart';
import 'package:test_api/test_api.dart';

import '../test_utils.dart';

void main() {
  group('projectToListenable', () {
    test('should emit iff projection is updated', () async {
      final store = createStore<MathEvent>();
      final sum$ = projectToListenable(store, sum);
      final results = <int>[];
      sum$.addListener(() => results.add(sum$.value));
      store.publish(Plus(1));
      store.publish(Plus(1));
      store.publish(Plus(1));
      expect(results, [1, 2, 3]);
      store.publish(Plus(0));
      expect(results, [1, 2, 3]);
    });
  });
}
