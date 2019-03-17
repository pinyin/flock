import 'package:active_observers/active_observers.dart';
import 'package:flock/flock.dart';

ObserveStore<P, E> observeStore<P, E>(
    Store<E> getStore(), Projector<P, E> projector) {
  Store<E> store = getStore();
  ObserveState<P> projection = observeState<P>(() => store.project(projector));

  observeEffect(() {
    store = getStore();
    return store.subscribe(() => projection.value = store.project(projector));
  }, () => store == getStore());

  return ObserveStore(getStore, () => projection.value);
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
