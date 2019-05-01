import 'dart:async';

import 'package:flock/flock.dart';

typedef SideEffect<E> = Stream<E> Function(
    Stream<E> events, Projectable<E> project);

StoreEnhancer<E> withSideEffect<E>(SideEffect<E> sideEffect) {
  return (StoreCreator<E> createStore) => (List<E> prepublish) => _Proxy(
        createStore(prepublish),
        sideEffect ?? _emptyEffect,
      );
}

Stream<E> _emptyEffect<E>(Stream<E> events, Projectable<E> store) async* {}

class _Proxy<E> extends StoreProxyBase<E> {
  _Proxy(StoreForEnhancer<E> inner, this.sideEffect) : super(inner) {
    _resubscribe();
  }

  @override
  E publish(E event) {
    _incoming.add(event);
    return inner.publish(event);
  }

  @override
  void replaceEvents(List<E> events, [int cursor]) {
    inner.replaceEvents(events, cursor);
    _resubscribe();
  }

  StreamSubscription<E> _subscription;

  void _resubscribe() {
    if (_subscription is StreamSubscription<E>) _subscription.cancel();
    _subscription = _incoming.stream
        .transform(
            StreamTransformer.fromBind((stream) => sideEffect(stream, this)))
        .listen(publish);
  }

  final _incoming = StreamController<E>();
  final SideEffect<E> sideEffect;
}
