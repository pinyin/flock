import 'dart:async';

import 'package:flock/flock.dart';

typedef CallSubscribers = Function(Function());

StoreEnhancer batchSubscribe([CallSubscribers scheduleSubscribers]) {
  return (StoreCreator createStore) => () => _BatchSubscribeStoreProxy(
      createStore(), scheduleSubscribers ?? scheduleMicrotask);
}

class _BatchSubscribeStoreProxy extends StoreProxyBase {
  CallSubscribers callSubscribers;
  _BatchSubscribeStoreProxy(StoreForEnhancer inner, this.callSubscribers)
      : super(inner) {
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
