import 'package:flock/src/base/types.dart';

/// Create a Flock [Store].
StoreForEnhancer<E> createStore<E>(List<E> prepublish,
    [Iterable<StoreEnhancer<E>> enhancers = const []]) {
  final createStore = enhancers.fold<StoreCreator<E>>(
      (List<E> p) => _EventStoreImpl(p), (prev, curr) => curr(prev));
  return createStore(prepublish);
}

class _EventStoreImpl<E> implements StoreForEnhancer<E> {
  _EventStoreImpl(List<E> prepublish) {
    this._events = prepublish;
    _cursor = this._events.length;
  }

  @override
  P getState<P>(Reducer<P, E> reducer, Initializer<P, E> initializer) {
    final isCacheUsable =
        _stateCache[reducer] != null && _stateCache[reducer].cursor <= _cursor;
    final prev = isCacheUsable
        ? _stateCache[reducer]
        : CacheItem(_cursor, initializer(_events));
    P next = prev.state as P;
    for (var i = _cursor - prev.cursor; i > 0; i--) {
      next = reducer(next, _events[_events.length - i]);
    }
    _stateCache[reducer] = CacheItem(_cursor, next);
    return next;
  }

  @override
  void dispatch([E event]) {
    if (event != null) {
      _events.add(event);
      _cursor++;
    }
    _listeners.forEach((listener) => listener()); // TODO catch errors
  }

  @override
  void replaceEvents(List<E> events, [int cursor]) {
    if (_events != events) {
      _stateCache = Expando<CacheItem>();
      _events = events;
    }
    if (cursor != null && cursor != _cursor) {
      _stateCache = Expando<CacheItem>();
      _cursor = cursor;
    }
  }

  @override
  Unsubscribe subscribe(Subscriber subscriber) {
    _listeners.add(subscriber);
    return () => _listeners.remove(subscriber);
  }

  @override
  List<E> get events => _events;

  @override
  int get cursor => _cursor;

  List<E> _events;
  int _cursor;
  final _listeners = Set<Subscriber>();
  var _stateCache = Expando<CacheItem>();
}

class CacheItem {
  final int cursor;
  final dynamic state;

  CacheItem(this.cursor, this.state);
}
