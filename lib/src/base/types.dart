// TODO separate types into different files

/// An [Store] records all events happened in app and acts as the single source of truth.
/// Use [createStore] function to create an event store.
abstract class Store<E> extends Projectable<E> with _Subscribable<E> {
  void dispatch(E event);
}

/// [Store] for extension.
/// We don't want our events get replaced by widgets.
abstract class InnerStore<E> extends Store<E> {
  void replaceEvents(Iterable<E> events);
}

/// Read from store.
/// Widgets use [Projector] to extract information from store.
abstract class Projectable<E> {
  /// Shorthand for projectWith
  /// Too bad we can't use operator overloading here
  /// https://github.com/dart-lang/sdk/issues/300480
  P getState<P>(Projector<E, P> projector);
}

abstract class _Subscribable<E> {
  Unsubscribe subscribe(Subscriber<E> subscriber);
}

/// Callback when [Store] is updated.
typedef Subscriber<E> = Function();

/// Stop receiving events
typedef Unsubscribe = Function();

/// Store creator for middleware.
typedef CreateStore<E> = InnerStore<E> Function(Iterable<E> prepublish);

/// [Middleware] are called "store enhancer" in Redux.
/// They wrap store and enable features like time travel.
typedef Middleware<E> = CreateStore<E> Function(CreateStore<E> inner);

/// A [Projector] is a view derived from events.
typedef Projector<E, P> = P Function(
    P prev, EventStack<E> eventStack, Projectable<E> store);

/// A [Projector] receives events since its last updated in the format of [EventStack]
/// As it name implies, an [EventStack] iterates over events in reverse chronological order.
abstract class EventStack<E> implements Iterable<E> {}
