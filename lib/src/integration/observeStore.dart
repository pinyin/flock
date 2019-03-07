import 'package:flock/flock.dart';
import 'package:observable_state_lifecycle/observable_state_lifecycle.dart';

StateLifecycleObserver observeStore<E, P>(
    Store<E> getStore(), Projector<P, E> projector, void Function(P) setState) {
  Store<E> store;
  P projection;
  Unsubscribe unsubscribe;

  void resubscribeToStore() {
    if (unsubscribe is Unsubscribe) unsubscribe();
    projection = store.project(projector);
    setState(projection);
    unsubscribe = store.subscribe(() {
      var newProjection = store.project(projector);
      if (newProjection == projection) return;
      projection = newProjection;
      setState(projection);
    });
  }

  return (phase) {
    switch (phase) {
      case StateLifecyclePhase.initState:
        store = getStore();
        resubscribeToStore();
        break;
      case StateLifecyclePhase.reassemble:
        if (store == getStore()) break;
        store = getStore();
        resubscribeToStore();
        break;
      case StateLifecyclePhase.dispose:
        unsubscribe();
        break;
      default:
        ;
    }
  };
}
