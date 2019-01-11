import 'package:flock/src/base/EventStorage.dart';
import 'package:flock/src/base/Projections.dart';
import 'package:flock/src/base/types.dart';

/// Create a Flock [Store].
InnerStore<E> createStore<E>(
    [Iterable<E> prepublish = const [],
    Iterable<StoreEnhancer<E>> enhancers = const []]) {
  final createStore = enhancers.fold<StoreCreator<E>>(
      (Iterable<E> p) => _EventStoreImpl(p), (prev, curr) => curr(prev));
  return createStore(prepublish);
}

class _EventStoreImpl<E> implements InnerStore<E> {
  _EventStoreImpl(Iterable<E> prepublish) {
    this._storage.replaceEvents(prepublish);
  }

  @override
  P getState<P>(Projector<E, P> projector) {
    final cached = _projections.get<P>(projector);
    if (cached?.cursor == _storage.cursor) return cached.projection;
    final projection = cached != null && cached.cursor < _storage.cursor
        ? projector(cached?.projection, _storage.readSince(cached?.cursor))
        : projector(cached?.projection, _storage.readSince(0));
    _projections.set(projector, _storage.cursor, projection);
    return projection;
  }

  @override
  E dispatch(E event) {
    _storage.publish(event);
    _listeners.forEach((listener) => listener()); // TODO catch errors
    return null;
  }

  @override
  void replaceEvents(Iterable<E> events) {
    _projections.clear();
    _storage.replaceEvents(events);
  }

  @override
  Unsubscribe subscribe(Subscriber<E> subscriber) {
    _listeners.add(subscriber);
    return () => _listeners.remove(subscriber);
  }

  final _listeners = Set<Subscriber<E>>();
  final _storage = EventStorage<E>();
  final _projections = Projections<E>();
}
