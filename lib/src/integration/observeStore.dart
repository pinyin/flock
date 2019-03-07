import 'package:flock/flock.dart';
import 'package:observable_state_lifecycle/observable_state_lifecycle.dart';

ObserveStore<P, E> observeStore<P, E>(
  Store<E> getStore(),
  Projector<P, E> projector,
  ObservableStateLifecycle host,
) {
  Store<E> store = getStore();
  ObserveState<P> projection = observeState(store.project(projector), host);

  observeEffect(() {
    store = getStore();
    projection.value = store.project(projector);
    return store.subscribe(() => projection.value = store.project(projector));
  }, () => store == getStore(), host);

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
