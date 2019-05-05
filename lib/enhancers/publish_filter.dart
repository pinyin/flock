import 'package:flock/flock.dart';

StoreEnhancer publishFilter(PublishFilterCreator filter) {
  return (StoreCreator createStore) {
    return (Iterable<Object> prepublish) {
      final inner = createStore(prepublish);
      return _PublishFilterProxy(inner, filter(inner));
    };
  };
}

typedef PublishFilterCreator = PublishFilter Function(Projectable);

typedef PublishFilter = bool Function(Object);

class _PublishFilterProxy extends StoreProxyBase {
  final PublishFilter filter;

  @override
  E publish<E>(E event) {
    return filter(event) ? inner.publish(event) : null;
  }

  _PublishFilterProxy(StoreForEnhancer inner, this.filter) : super(inner);
}
