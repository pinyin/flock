import 'package:flock/flock.dart';

abstract class StoreProxyBase<E> extends StoreForEnhancer<E> {
  final StoreForEnhancer<E> inner;

  StoreProxyBase(this.inner);

  @override
  int get cursor => inner.cursor;

  @override
  List<E> get events => inner.events;

  @override
  P project<P>(projector) {
    return inner.project(projector);
  }

  @override
  E publish(E event) {
    inner.publish(event);
    return event;
  }

  @override
  void replaceEvents(List<E> events, [int cursor]) {
    inner.replaceEvents(events, cursor);
  }

  @override
  subscribe(subscriber) {
    return inner.subscribe(subscriber);
  }
}
