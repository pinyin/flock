import 'package:flock/flock.dart';

StoreEnhancer printEventOnPublish([String tag = '']) {
  return (StoreCreator createStore) =>
      (List events) => _Proxy(createStore(events), tag);
}

class _Proxy extends StoreProxyBase {
  final String tag;

  _Proxy(StoreForEnhancer inner, this.tag) : super(inner);

  @override
  E publish<E>(E event) {
    print('$tag$event');
    inner.publish(event);
    return event;
  }
}
