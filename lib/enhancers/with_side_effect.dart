import 'dart:async';

import 'package:flock/flock.dart';

StoreEnhancer<E> withSideEffect<E>(SideEffect<E> sideEffect) {
  return (StoreCreator<E> createStore) => (List<E> prepublish) => _Proxy(
        createStore(prepublish),
        sideEffect ?? emptySideEffect,
      );
}

typedef SideEffect<E> = Stream<E> Function(Stream<E> events, Store<E> store);

Stream<E> emptySideEffect<E>(Stream<E> events, Store<E> store) async* {}

class _Proxy<E> extends StoreProxyBase<E> {
  _Proxy(StoreForEnhancer<E> inner, this.sideEffect) : super(inner) {
    resubscribe();
  }

  @override
  E publish(E event) {
    incoming.add(event);
    return inner.publish(event);
  }

  @override
  void replaceEvents(List<E> events, [int cursor]) {
    inner.replaceEvents(events, cursor);
    resubscribe();
  }

  StreamSubscription<E> subscription;
  StreamController<E> incoming;

  void resubscribe() {
    if (subscription is StreamSubscription<E>) {
      incoming.close();
      subscription.cancel();
      subscription = null;
    }

    incoming = StreamController();

    subscription = incoming.stream
        .transform(
            StreamTransformer.fromBind((stream) => sideEffect(stream, this)))
        .listen(publish);
  }

  final SideEffect<E> sideEffect;
}
