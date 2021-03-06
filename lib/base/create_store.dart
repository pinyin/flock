import 'dart:collection';
import 'dart:core';

import 'package:collection/collection.dart';

import 'types.dart';

/// Create a Flock [Store].
StoreForEnhancer createStore({List<StoreEnhancer> enhancers = const []}) {
  return combineStoreEnhancers(enhancers)(() => _EventStoreImpl())();
}

class _EventStoreImpl implements StoreForEnhancer {
  _EventStoreImpl() {
    _events = QueueList();
    _cursor = _events.length;
    _headCursor = 0;
  }

  @override
  P project<P>(Projector<P> projector) {
    assert(projector is Projector<P>);
    final isCacheReusable = _stateCache[projector] != null &&
        _stateCache[projector].cursor <= _cursor;
    final prev = isCacheReusable
        ? _stateCache[projector]
        : CacheItem(_cursor, projector(null, _events, this));
    if (isCacheReusable && prev.cursor == cursor) return prev.state as P;
    P nextState = prev.state as P;
    if (prev.cursor < _cursor) {
      nextState = projector(
        nextState,
        (_tailCache[prev.cursor] ??=
            ListTail<Object>(_events, prev.cursor - _headCursor)),
        this,
      );
    }
    _stateCache[projector] = CacheItem(_cursor, nextState);
    return nextState;
  }

  @override
  E publish<E>(E event) {
    assert(event is E);
    _events.add(event);
    _cursor++;
    _listeners.forEach((listener) => listener());
    return event;
  }

  @override
  void rewriteHistory(QueueList<Object> events, [int cursor]) {
    if (_events != events) {
      _events = events;
      _tailCache.clear();
    }
    if (_cursor != cursor) {
      assert(cursor >= events.length);
      _stateCache = Expando<CacheItem>();
      _headCursor = cursor - events.length;
      _cursor = cursor;
      _tailCache.clear();
    }
  }

  @override
  Unsubscribe subscribe(Subscriber subscriber) {
    assert(subscriber is Subscriber);
    final uniqueRef = () => subscriber();
    _listeners.add(uniqueRef);
    return () => _listeners.remove(uniqueRef);
  }

  @override
  QueueList<Object> get history => _events;

  @override
  int get cursor => _cursor;

  QueueList<Object> _events;
  int _headCursor;
  int _cursor;
  final _listeners = Set<Subscriber>();
  var _stateCache = Expando<CacheItem>();
  final _tailCache = Map<int, ListTail<Object>>();
}

class CacheItem {
  final int cursor;
  final dynamic state;

  CacheItem(this.cursor, this.state);
}

class ListTail<T> extends ListMixin<T> {
  @override
  int get length => parent.length - since;

  @override
  set length(int newLength) {
    throw 'Length cannot be modified.';
  }

  ListTail(this.parent, this.since);

  @override
  T operator [](int index) {
    return parent[index + since];
  }

  @override
  void operator []=(int index, T value) {
    throw 'Content cannot be modified.';
  }

  final List<T> parent;
  final int since;
}
