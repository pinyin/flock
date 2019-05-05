import 'dart:async';

import 'package:flock/flock.dart';

StoreEnhancer withSideEffect(SideEffect sideEffect) {
  return (StoreCreator createStore) =>
      (Iterable prepublish) => _WithSideEffectStoreProxy(
            createStore(prepublish),
            sideEffect ?? emptySideEffect,
          );
}

typedef SideEffect = Stream<Object> Function(
    Stream<Object> events, Store store);

Stream<Object> emptySideEffect(Stream<Object> events, Store store) async* {}

class _WithSideEffectStoreProxy extends StoreProxyBase {
  _WithSideEffectStoreProxy(StoreForEnhancer inner, this.sideEffect)
      : super(inner) {
    resubscribe();
  }

  @override
  E publish<E>(E event) {
    incoming.add(event);
    return inner.publish(event);
  }

  @override
  void replaceEvents(Iterable events, [int cursor]) {
    inner.replaceEvents(events, cursor);
    resubscribe();
  }

  StreamSubscription<Object> subscription;
  StreamController<Object> incoming;

  void resubscribe() {
    if (subscription is StreamSubscription) {
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

  final SideEffect sideEffect;
}
