import 'dart:collection';

void matchEvents<E>(List<E> events, Map<String, EventMatcher<E>> states) {
  void enterState(EventIterator<E> iterator, EventMatcher<E> match) {
    if (match == null) return;
    enterState(iterator, states[match(iterator)]);
  }

  enterState(EventIterator(events), states['start']);
}

typedef EventMatcher<E> = String Function(EventIterator<E> events);

class EventIterator<E> extends IterableBase<E>
    with Iterator<E>
    implements Iterable<E> {
  EventIterator(this.list, [this.cursor]);

  List<E> list;
  int cursor = 0;

  @override
  E get current => list[cursor];

  @override
  bool moveNext() {
    cursor++;
    return cursor < list.length;
  }

  EventIterator<E> fork() {
    return EventIterator(list, cursor);
  }

  @override
  Iterator<E> get iterator => this;
}
