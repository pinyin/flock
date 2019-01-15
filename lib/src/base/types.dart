// TODO separate types into different files

/// An [Store] records all events happened in app and acts as the single source of truth.
abstract class Store<E> {
  void dispatch(E event);

  Unsubscribe subscribe(Subscriber subscriber);

  P getState<P>(Reducer<P, E> projector, Initializer<P, E> initializer);
}

/// [Store] interface for store enhancers.
abstract class StoreForEnhancer<E> extends Store<E> {
  void dispatch([E event]);

  int get cursor;

  List<E> get events;

  void replaceEvents(List<E> events, [int cursor]);
}

/// Callback when [Store] is updated.
typedef Subscriber = Function();

/// Stop receiving events
typedef Unsubscribe = Function();

/// Store creator for middleware.
typedef StoreCreator<E> = StoreForEnhancer<E> Function(List<E> prepublish);

/// [StoreEnhancer] are called "store enhancer" in Redux.
/// They wrap store and enable features like time travel.
typedef StoreEnhancer<E> = StoreCreator<E> Function(StoreCreator<E> inner);

/// A [Reducer] calculates view derived from events.
typedef Reducer<P, E> = P Function(P prev, E event);

/// A [Initializer] is only called when reducer hasn't called
typedef Initializer<P, E> = P Function(List<E> events);
