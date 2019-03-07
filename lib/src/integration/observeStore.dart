import 'package:flock/flock.dart';
import 'package:observable_state_lifecycle/observable_state_lifecycle.dart';

StateLifecycleObserver observeStore<E, P>(
    Store<E> getStore(), Projector<P, E> projector, void Function(P) setState) {
  Store<E> store;
  Unsubscribe unsubscribe;

  void subscribeToStore() {
    if (store == getStore()) return;
    if (unsubscribe is Unsubscribe) unsubscribe();
    store = getStore();
    P projection = store.project(projector);
    setState(projection);
    unsubscribe = store.subscribe(() {
      var newProjection = store.project(projector);
      if (newProjection == projection) return;
      projection = newProjection;
      setState(projection);
    });
  }

  return (phase) {
    if (phase == StateLifecyclePhase.initState ||
        phase == StateLifecyclePhase.reassemble) {
      subscribeToStore();
    }
    if (phase == StateLifecyclePhase.dispose) {
      unsubscribe();
    }
  };
}
