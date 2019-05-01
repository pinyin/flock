import 'dart:async';

import 'package:flock/flock.dart';

typedef UseCase<E> = Stream<E> Function(
    Stream<E> events, Projectable<E> project);

StoreEnhancer<E> withUseCase<E>(UseCase<E> useCase) {
  return (StoreCreator<E> createStore) => (List<E> prepublish) => _Proxy(
        createStore(prepublish),
        useCase ?? _emptyUseCase,
      );
}

Stream<E> _emptyUseCase<E>(Stream<E> events, Projectable<E> store) async* {}

class _Proxy<E> extends StoreProxyBase<E> {
  _Proxy(StoreForEnhancer<E> inner, this.useCase) : super(inner) {
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
            StreamTransformer.fromBind((stream) => useCase(stream, this)))
        .listen(publish);
  }

  final _incoming = StreamController<E>();
  final UseCase<E> useCase;
}
