import 'dart:collection';

import 'package:flock/src/base/types.dart';

class EventStackImpl<E> extends IterableMixin<E> implements EventStack<E> {
  EventStackImpl(this._events, this._upTo);

  List<E> _events;
  int _upTo;

  @override
  Iterator<E> get iterator => _EventStackIterator(_events, _upTo);
}

class _EventStackIterator<E> extends Iterator<E> {
  _EventStackIterator(this._events, this._upTo) {
    this._cursor = _events.length;
  }

  List<E> _events;
  int _cursor;
  int _upTo;

  @override
  get current => _events[_cursor];

  @override
  bool moveNext() {
    _cursor--;
    return _cursor >= _upTo;
  }
}
