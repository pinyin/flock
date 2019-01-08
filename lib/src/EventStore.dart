abstract class EventStore<E> extends ReadonlyEventStore<E> {
  void publish(E event);

  void replaceEvents(List<E> E);
}

abstract class ReadonlyEventStore<E> extends Projectable<E>
    with Subscribable<E> {}

abstract class Projectable<E> {
  P projectWith<P>(Projector<E, P> projector);
}

abstract class Subscribable<E> {
  Unsubscribe subscribe(Subscriber<E> subscriber);
}

typedef Subscriber<E> = Function(E event);
typedef Unsubscribe = void Function();
typedef CreateStore<E> = EventStore<E> Function(List<E> prepublish);
typedef Middleware<E> = CreateStore<E> Function(CreateStore<E> inner);
typedef Projector<E, P> = P Function(
    P prev, EventStack<E> eventStack, Projectable<E> store);

abstract class EventStack<E> implements Iterable<E> {}
