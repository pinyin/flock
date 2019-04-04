import 'dart:async';

import 'package:flock/flock.dart';

Stream<P> projectToStream<P, E>(Store<E> store, Projector<P, E> projector) {
  var refCount = 0;
  var latestProjection = store.project(projector);

  final controller = StreamController<P>();

  void emit() {
    final currentProjection = store.project(projector);
    if (currentProjection != latestProjection)
      controller.add(currentProjection);
    latestProjection = currentProjection;
  }

  controller.onListen = () {
    refCount++;
    if (refCount == 1) store.addListener(emit);
  };

  controller.onCancel = () {
    refCount--;
    if (refCount == 0) store.removeListener(emit);
  };

  return controller.stream;
}
