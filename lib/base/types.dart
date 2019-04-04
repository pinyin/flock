// TODO separate types into different files

import 'package:flutter/foundation.dart';

/// An [Store] records all events happened in app and acts as the single source of truth.
abstract class Store<E> implements Listenable {
  void publish(E event);
  Unsubscribe subscribe(Subscriber subscriber);

  P project<P>(Projector<P, E> projector);
}

/// [Store] interface for store enhancers.
abstract class StoreForEnhancer<E> extends Store<E> {
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

/// A [Projector] calculates view derived from events.
/// [prev] is nullable
typedef Projector<P, E> = P Function(P prev, List<E> event);
