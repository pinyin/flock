import 'dart:collection';
import 'dart:core';

import 'package:collection/collection.dart';
import 'package:flock/base/types.dart';

/// Create a Flock [Store].
StoreForEnhancer<E> createStore<E>(
    [List<E> prepublish = const [],
    List<StoreEnhancer<E>> enhancers = const []]) {
  final createStore = enhancers.reversed.fold<StoreCreator<E>>(
      (List<E> p) => _EventStoreImpl(p), (prev, curr) => curr(prev));
  return createStore(prepublish);
}

class _EventStoreImpl<E> implements StoreForEnhancer<E> {
  _EventStoreImpl(List<E> prepublish) {
    assert(prepublish is List<E>);
    this._events = QueueList.from(prepublish);
    _cursor = this._events.length;
  }

  @override
  P project<P>(Projector<P, E> projector) {
    assert(projector is Projector<P, E>);
    final isCacheReusable = _stateCache[projector] != null &&
        _stateCache[projector].cursor <= _cursor;
    final prev = isCacheReusable
        ? _stateCache[projector]
        : CacheItem(_cursor, projector(null, _events, this));
    if (isCacheReusable && prev.cursor == cursor) return prev.state as P;
    P nextState = prev.state as P;
    if (prev.cursor < _cursor)
      nextState = projector(nextState, ListTail(_events, prev.cursor), this);
    _stateCache[projector] = CacheItem(_cursor, nextState);
    return nextState;
  }

  @override
  E publish(E event) {
    assert(event is E);
    _events.add(event);
    _cursor++;
    _listeners.forEach((listener) => listener());
    return event;
  }

  @override
  void replaceEvents(List<E> events, [int cursor]) {
    assert(events is List<E>);
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
    assert(subscriber is Subscriber);
    final uniqueRef = () => subscriber();
    _listeners.add(uniqueRef);
    return () => _listeners.remove(uniqueRef);
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

class ListTail<T> extends ListMixin<T> {
  @override
  int get length => parent.length - since;

  @override
  void set length(int newLength) {
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
