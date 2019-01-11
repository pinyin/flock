// TODO separate types into different files

/// An [Store] records all events happened in app and acts as the single source of truth.
abstract class Store<E> {
  void dispatch(E event);

  Unsubscribe subscribe(Subscriber<E> subscriber);

  P getState<P>(Projector<E, P> projector);
}

/// [Store] interface for store enhancers.
abstract class InnerStore<E> extends Store<E> {
  void replaceEvents(Iterable<E> events);
}

/// Callback when [Store] is updated.
typedef Subscriber<E> = Function();

/// Stop receiving events
typedef Unsubscribe = Function();

/// Store creator for middleware.
typedef StoreCreator<E> = InnerStore<E> Function(Iterable<E> prepublish);

/// [StoreEnhancer] are called "store enhancer" in Redux.
/// They wrap store and enable features like time travel.
typedef StoreEnhancer<E> = StoreCreator<E> Function(StoreCreator<E> inner);

/// A [Projector] is a view derived from events.
typedef Projector<E, P> = P Function(P cached, Events<E> events);

/// A [Projector] receives events since its last updated as [Events]
abstract class Events<E> implements List<E> {
  @override
  Events<E> get reversed;
}
