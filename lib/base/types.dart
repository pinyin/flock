// TODO separate types into different files

/// An [Store] records all events happened in app and acts as the single source of truth.
abstract class Store<E extends Object>
    implements Projectable<E>, Publishable<E> {
  Unsubscribe subscribe(Subscriber subscriber);
}

/// [Store] interface for store enhancers.
abstract class StoreForEnhancer<E extends Object> extends Store<E> {
  int get cursor;
  List<E> get events;
  void replaceEvents(List<E> events, [int cursor]);
}

abstract class Projectable<E extends Object> {
  P project<P>(Projector<P, E> projector);
}

/// [Store.publish] interface
abstract class Publishable<E extends Object> {
  E publish(E event);
}

/// Callback when [Store] is updated.
typedef Subscriber = void Function();

/// Stop receiving events
typedef Unsubscribe = void Function();

/// Store creator for middleware.
typedef StoreCreator<E> = StoreForEnhancer<E> Function(List<E> prepublish);

/// [StoreEnhancer] are called "store enhancer" in Redux.
/// They wrap store and enable features like time travel.
typedef StoreEnhancer<E> = StoreCreator<E> Function(StoreCreator<E> inner);

/// A [Projector] calculates view derived from events.
/// [prev] is nullable
/// Hint: an object with a `call()` method will also work.
typedef Projector<P, E> = P Function(
    P prev, List<E> event, Projectable<E> projectable);
