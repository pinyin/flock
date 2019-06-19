import 'package:flock/flock.dart';

StoreEnhancer publishFilter(PublishFilterCreator filter) {
  return (StoreCreator createStore) {
    return () {
      final inner = createStore();
      return _PublishFilterStoreProxy(inner, filter(inner));
    };
  };
}

typedef PublishFilterCreator = PublishFilter Function(Projectable);

typedef PublishFilter = bool Function(Object);

class _PublishFilterStoreProxy extends StoreProxyBase {
  final PublishFilter filter;

  @override
  E publish<E>(E event) {
    return filter(event) ? inner.publish(event) : null;
  }

  _PublishFilterStoreProxy(StoreForEnhancer inner, this.filter) : super(inner);
}
