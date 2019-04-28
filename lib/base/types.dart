// TODO separate types into different files

import 'package:flutter/foundation.dart';

/// An [Store] records all events happened in app and acts as the single source of truth.
abstract class Store<E> implements Listenable, Projectable<E> {
  E publish(E event);
  Unsubscribe subscribe(Subscriber subscriber);
}

/// [Store] interface for store enhancers.
abstract class StoreForEnhancer<E> extends Store<E> {
  int get cursor;

  List<E> get events;

  void replaceEvents(List<E> events, [int cursor]);
}

abstract class Projectable<E> {
  P project<P>(Projector<P, E> projector);
}

/// [Store.publish] interface
typedef Publish<E> = E Function<E>(E);

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
typedef Projector<P, E> = P Function(
    P prev, List<E> event, Projectable<E> projectable);
