import 'package:flock/flock.dart';

StoreEnhancer<E> printEventOnPublish<E>([String tag = '']) {
  return (StoreCreator<E> createStore) =>
      (List<E> events) => _Proxy(createStore(events), tag);
}

class _Proxy<E> extends StoreProxyBase<E> {
  final String tag;

  _Proxy(StoreForEnhancer<E> inner, this.tag) : super(inner);

  @override
  E publish(E event) {
    print('$tag$event');
    inner.publish(event);
    return event;
  }
}
