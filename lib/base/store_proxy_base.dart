import 'package:flock/flock.dart';

abstract class StoreProxyBase extends StoreForEnhancer {
  final StoreForEnhancer inner;

  StoreProxyBase(this.inner);

  @override
  int get cursor => inner.cursor;

  @override
  QueueList<Object> get history => inner.history;

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
  void rewriteHistory(QueueList<Object> events, [int cursor]) {
    inner.rewriteHistory(events, cursor);
  }

  @override
  subscribe(subscriber) {
    return inner.subscribe(subscriber);
  }
}
