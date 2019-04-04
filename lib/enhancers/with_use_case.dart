import 'dart:async';

import 'package:flock/base/types.dart';
import 'package:flock/flock.dart';

typedef UseCase<E> = Stream<E> Function(
    Stream<E> events, P Function<P>(Projector<P, E> projector) project);

StoreEnhancer<E> withUseCase<E>(UseCase<E> useCase) {
  return (StoreCreator<E> createStore) => (List<E> prepublish) =>
      _StoreWithUseCase(createStore(prepublish), useCase);
}

class _StoreWithUseCase<E> extends StoreForEnhancer<E> {
  _StoreWithUseCase(this._inner, this._useCase) : super() {
    _resubscribe();
  }

  @override
  int get cursor => _inner.cursor;

  @override
  void publish(E event) {
    _incoming.add(event);
  }

  @override
  List<E> get events => _inner.events;

  @override
  P project<P>(projector) {
    return _inner.project(projector);
  }

  @override
  void replaceEvents(List<E> events, [int cursor]) {
    _inner.replaceEvents(events, cursor);
    _resubscribe();
  }

  @override
  subscribe(subscriber) {
    return _inner.subscribe(subscriber);
  }

  void _resubscribe() {
    if (_subscription is StreamSubscription<E>) _subscription.cancel();
    _subscription = _incoming.stream
        .transform(
            StreamTransformer.fromBind((stream) => _useCase(stream, project)))
        .listen(_inner.publish);
  }

  final _incoming = StreamController<E>();
  StreamSubscription<E> _subscription;
  StoreForEnhancer<E> _inner;
  UseCase<E> _useCase;

  @override
  void addListener(listener) {
    _inner.addListener(listener);
  }

  @override
  void removeListener(listener) {
    _inner.removeListener(listener);
  }
}
