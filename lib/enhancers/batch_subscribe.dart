import 'package:flock/flock.dart';
import 'package:flutter/scheduler.dart';

typedef CallSubscribers = Function(Function());

StoreEnhancer<E> batchSubscribe<E>([CallSubscribers scheduleSubscribers]) {
  return (StoreCreator<E> createStore) => (List<E> prepublish) => _Proxy(
        createStore(prepublish),
        scheduleSubscribers ?? _scheduleOnFrame,
      );
}

void _scheduleOnFrame(void callback()) {
  SchedulerBinding.instance.scheduleFrameCallback((_) {
    callback();
  });
}

class _Proxy<E> extends StoreProxyBase<E> {
  CallSubscribers callSubscribers;
  _Proxy(StoreForEnhancer<E> inner, this.callSubscribers) : super(inner) {
    var hasScheduledUpdate = false;
    inner.subscribe(() {
      if (hasScheduledUpdate) return;
      hasScheduledUpdate = true;
      callSubscribers(() {
        subscribers.forEach((s) => s());
        hasScheduledUpdate = false;
      });
    });
  }

  final subscribers = Set<Subscriber>();

  @override
  subscribe(subscriber) {
    final uniqueRef = () => subscriber();
    subscribers.add(uniqueRef);
    return () => subscribers.remove(uniqueRef);
  }
}
