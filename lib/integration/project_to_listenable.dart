import 'package:flock/flock.dart';
import 'package:flutter/foundation.dart';

ValueListenable<P> projectToListenable<P, E>(
        Store<E> store, Projector<P, E> projector) =>
    _ProjectToListenable(store, projector);

class _ProjectToListenable<P, E> implements ValueListenable<P> {
  _ProjectToListenable(this.store, this.projector);

  final Store<E> store;
  final Projector<P, E> projector;
  final Set<VoidCallback> listeners = Set<VoidCallback>();
  Unsubscribe unsubscribe;

  @override
  void addListener(listener) {
    listeners.add(listener);
    if (listeners.length == 1) {
      var latestProjection = store.project(projector);
      unsubscribe = store.subscribe(() {
        final currentProjection = store.project(projector);
        if (latestProjection != currentProjection)
          listeners.forEach((l) => l());
        latestProjection = currentProjection;
      });
    }
  }

  @override
  void removeListener(listener) {
    listeners.remove(listener);
    if (listeners.length == 0 && unsubscribe != null) {
      unsubscribe();
      unsubscribe = null;
    }
  }

  @override
  P get value => store.project(projector);
}
