import './EventStorage.dart';
import './EventStore.dart';
import './Projections.dart';

/// Create a Flock [EventStore].
EventStore<E> createEventStore<E>(
    [List<E> prepublish = const [],
    List<Middleware<E>> middleware = const []]) {
  final createStore = middleware.fold<CreateStore<E>>(
      (List<E> p) => _EventStoreImpl(p), (prev, curr) => curr(prev));
  return createStore(prepublish);
}

class _EventStoreImpl<E> implements EventStore<E> {
  _EventStoreImpl(List<E> prepublish) {
    this._storage.replaceEvents(prepublish);
  }

  @override
  P projectWith<P>(Projector<E, P> projector) {
    final cached = _projections.get<P>(projector);
    if (cached?.cursor == _storage.cursor) return cached.projection;
    final projection = cached != null && cached.cursor < _storage.cursor
        ? projector(cached?.projection, _storage.readUpTo(cached?.cursor), this)
        : projector(cached?.projection, _storage.readUpTo(0), this);
    _projections.set(projector, _storage.cursor, projection);
    return projection;
  }

  @override
  E publish(E event) {
    _storage.publish(event);
    _listeners.forEach((listener) => listener(event));
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
