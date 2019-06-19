import 'package:flock/flock.dart';

StoreEnhancer printEventOnPublish([String tag = '']) {
  return (StoreCreator createStore) =>
      () => _PrintEventOnPublishStoreProxy(createStore(), tag);
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
