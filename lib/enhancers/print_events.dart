import 'package:flock/flock.dart';

StoreEnhancer printEventOnPublish([String tag = '']) {
  return (StoreCreator createStore) => (Iterable events) =>
      _PrintEventOnPublishStoreProxy(createStore(events), tag);
}

class _PrintEventOnPublishStoreProxy extends StoreProxyBase {
  final String tag;

  _PrintEventOnPublishStoreProxy(StoreForEnhancer inner, this.tag)
      : super(inner);

  @override
  E publish<E>(E event) {
    print('$tag$event');
    inner.publish(event);
    return event;
  }
}
