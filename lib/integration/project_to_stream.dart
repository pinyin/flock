import 'dart:async';

import 'package:flock/flock.dart';

Stream<P> Function(Store) projectToStream<P>(Projector<P> projector) {
  return (Store store) {
    var refCount = 0;

    final controller = StreamController<P>();

    // todo batch update
    void emit() {
      controller.add(store.project(projector));
    }

    Unsubscribe unsubscribe;

    controller.onListen = () {
      refCount++;
      if (refCount == 1) unsubscribe = store.subscribe(emit);
    };

    controller.onCancel = () {
      refCount--;
      if (refCount == 0) unsubscribe();
    };

    return controller.stream;
  };
}
