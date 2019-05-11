/// An [Store] records all events happened in app and acts as the single source of truth.
abstract class Store implements Projectable, Publishable {
  Unsubscribe subscribe(Subscriber subscriber);
}

/// [Store] interface for store enhancers.
abstract class StoreForEnhancer extends Store {
  int get cursor;
  Iterable<Object> get events;
  void replaceEvents(Iterable<Object> events, [int cursor]);
}

/// combine multiple store enhancers into one enhancer
StoreEnhancer combineStoreEnhancers(List<StoreEnhancer> enhancers) {
  return (StoreCreator createStore) {
    return enhancers.reversed.fold(
        (Iterable<Object> prepublish) => createStore(prepublish),
        (prev, curr) => curr(prev));
  };
}

/// [Store.project] interface
abstract class Projectable {
  P project<P>(Projector<P> projector);
}

/// [Store.publish] interface
abstract class Publishable {
  E publish<E>(E event);
}

/// Callback when [Store] is updated.
typedef Subscriber = void Function();

/// Stop receiving events
typedef Unsubscribe = void Function();

/// Store creator for middleware.
typedef StoreCreator = StoreForEnhancer Function(Iterable<Object> prepublish);

/// [StoreEnhancer] are called "store enhancer" in Redux.
/// They wrap store and enable features like time travel.
typedef StoreEnhancer = StoreCreator Function(StoreCreator inner);

/// A [Projector] calculates view derived from events.
/// [prev] is nullable
/// Hint: an object with a `call()` method will also work.
typedef Projector<P extends Object> = P Function(
    P prev, List event, Projectable projectable);
