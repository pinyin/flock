/// An [EventStore] records all events happened in app and acts as the single source of truth.
/// Use [createEventStore] function to create an event store.
abstract class EventStore<E> extends ReadonlyEventStore<E> {
  void publish(E event);

  void replaceEvents(List<E> E);
}

/// Read from [EventStore]
abstract class ReadonlyEventStore<E> extends Projectable<E>
    with _Subscribable<E> {}

/// [EventStore] only has events, which is not friendly for widgets to read.
/// Widgets use [Projector] to extract information from store.
abstract class Projectable<E> {
  P projectWith<P>(Projector<E, P> projector);
}

abstract class _Subscribable<E> {
  Unsubscribe subscribe(Subscriber<E> subscriber);
}

/// Callback when [EventStore] is updated.
typedef Subscriber<E> = Function(E event);

/// Stop receiving events
typedef Unsubscribe = void Function();

/// Store creator for middleware.
typedef CreateStore<E> = EventStore<E> Function(List<E> prepublish);

/// [Middleware] are called "store enhancer" in Redux.
/// They wrap store and enable features like time travel.
typedef Middleware<E> = CreateStore<E> Function(CreateStore<E> inner);

/// A [Projector] is a view derived from events.
typedef Projector<E, P> = P Function(
    P prev, EventStack<E> eventStack, Projectable<E> store);

/// A [Projector] receives events since its last updated in the format of [EventStack]
/// As it name implies, an [EventStack] iterates over events in reverse chronological order.
abstract class EventStack<E> implements Iterable<E> {}
