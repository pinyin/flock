import './EventStackImpl.dart';
import './EventStore.dart';

class EventStorage<E> {
  EventStorage();

  void publish(E event) {
    this._events.add(event);
  }

  EventStack<E> readUpTo(int cursor) {
    if (_cache.containsKey(cursor)) return _cache[cursor];
    final stack = EventStackImpl(_events, cursor);
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
  final _cache = Map<int, EventStack<E>>();
}
