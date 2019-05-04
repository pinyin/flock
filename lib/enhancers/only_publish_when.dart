import 'package:flock/flock.dart';

StoreEnhancer onlyPublishWhen(SkipPublishFilterCreator filter) {
  return (StoreCreator createStore) {
    return (Iterable<Object> prepublish) {
      final inner = createStore(prepublish);
      return _SkipPublishProxy(inner, filter(inner));
    };
  };
}

typedef SkipPublishFilterCreator = SkipPublishFilter Function(Projectable);

typedef SkipPublishFilter = bool Function(Object);

class _SkipPublishProxy extends StoreProxyBase {
  final SkipPublishFilter filter;

  @override
  E publish<E>(E event) {
    return filter(event) ? inner.publish(event) : null;
  }

  _SkipPublishProxy(StoreForEnhancer inner, this.filter) : super(inner);
}
