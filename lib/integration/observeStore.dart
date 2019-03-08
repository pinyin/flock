import 'package:active_observers/active_observers.dart';
import 'package:flock/flock.dart';

ActiveObserver<ObserveStore<P, E>> observeStore<P, E>(
    Store<E> getStore(), Projector<P, E> projector) {
  return (host) {
    Store<E> store;
    ObserveState<P> projection = observeState<P>(null)(host);

    observeEffect(() {
      store = getStore();
      projection.value = store.project(projector);
      return store.subscribe(() => projection.value = store.project(projector));
    }, () => store == getStore())(host);

    return ObserveStore(getStore, () => projection.value);
  };
}

class ObserveStore<P, E> {
  ObserveStore(Store<E> getStore(), P getProjection())
      : _getStore = getStore,
        _getProjection = getProjection;

  final Store<E> Function() _getStore;
  final P Function() _getProjection;

  P projection() {
    return _getProjection();
  }

  void publish(E event) {
    _getStore().publish(event);
  }
}
