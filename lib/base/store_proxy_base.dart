import 'package:flock/flock.dart';

abstract class StoreProxyBase extends StoreForEnhancer {
  final StoreForEnhancer inner;

  StoreProxyBase(this.inner);

  @override
  int get cursor => inner.cursor;

  @override
  List get events => inner.events;

  @override
  P project<P>(projector) {
    return inner.project(projector);
  }

  @override
  E publish<E>(E event) {
    inner.publish(event);
    return event;
  }

  @override
  void replaceEvents(List events, [int cursor]) {
    inner.replaceEvents(events, cursor);
  }

  @override
  subscribe(subscriber) {
    return inner.subscribe(subscriber);
  }
}
