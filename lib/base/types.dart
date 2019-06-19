import 'package:collection/collection.dart';

/// An [Store] records all events happened in app and acts as the single source of truth.
abstract class Store implements Projectable, Publishable {
  Unsubscribe subscribe(Subscriber subscriber);
}

/// [Store] interface for store enhancers.
abstract class StoreForEnhancer extends Store implements StoreEventStorage {}

/// combine multiple store enhancers into one enhancer
StoreEnhancer combineStoreEnhancers(List<StoreEnhancer> enhancers) {
  return (StoreCreator createStore) {
    return enhancers.reversed.fold(createStore, (prev, curr) => curr(prev));
  };
}

abstract class StoreEventStorage {
  int get cursor;
  QueueList<Object> get history;
  void rewriteHistory(QueueList<Object> history, [int cursor]);
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
typedef StoreCreator = StoreForEnhancer Function();

/// [StoreEnhancer] are called "store enhancer" in Redux.
/// They wrap store and enable features like time travel.
typedef StoreEnhancer = StoreCreator Function(StoreCreator inner);

/// A [Projector] calculates view derived from events.
/// [since] is null at first call
/// Hint: an object with a `call()` method will also work.
typedef Projector<P extends Object> = P Function(
    P since, List updates, Projectable projectable);
