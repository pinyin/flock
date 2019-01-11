import 'dart:collection';

import 'package:flock/src/base/types.dart';

class EventStorage<E> {
  EventStorage();

  void publish(E event) {
    this._events.add(event);
  }

  Events<E> readSince(int cursor) {
    if (_cache.containsKey(cursor)) return _cache[cursor];
    final stack = _Sublist(_events, cursor);
    _cache[cursor] = stack;
    return stack;
  }

  void replaceEvents(Iterable<E> events) {
    _cache.clear();
    _events.clear();
    _events.addAll(events);
  }

  int get cursor {
    return _events.length;
  }

  final _events = List<E>();
  final _cache = Map<int, Events<E>>();
}

class _Sublist<E> extends ListBase<E> implements Events<E> {
  _Sublist(this._events, this._since, [this.isReverted = false]);

  List<E> _events;
  int _since;
  bool isReverted;

  @override
  int get length {
    return _events.length - _since;
  }

  @override
  void set length(int newLength) {
    throw 'NewEvent is readonly';
  }

  @override
  E operator [](int index) {
    return isReverted
        ? index < length ? _events[_events.length - 1 - index] : null
        : _events[_since + index];
  }

  @override
  void operator []=(int index, E value) {
    throw 'NewEvent is readonly';
  }

  @override
  _Sublist<E> get reversed {
    return _Sublist(_events, _since, !isReverted);
  }
}
