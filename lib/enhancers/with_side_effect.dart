import 'dart:async';

import 'package:flock/flock.dart';

StoreEnhancer<E> withSideEffect<E>(SideEffect<E> sideEffect) {
  return (StoreCreator<E> createStore) => (List<E> prepublish) => _Proxy(
        createStore(prepublish),
        sideEffect ?? _emptyEffect,
      );
}

typedef SideEffect<E> = Unsubscribe Function(Stream<E> events, Store<E> store);

Unsubscribe _emptyEffect<E>(Stream<E> events, Store<E> store) {
  return () {};
}

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

  Unsubscribe unsubscribe;
  void resubscribe() {
    if (unsubscribe != null) unsubscribe();
    unsubscribe = null;
    unsubscribe = sideEffect(incoming.stream, this);
  }

  final incoming = StreamController<E>();
  final SideEffect<E> sideEffect;
}
