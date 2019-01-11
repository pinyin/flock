import 'package:flock/flock.dart';

var _cache = Expando<Projector<dynamic, dynamic>>();

Projector<E, P> fromReducer<E, P>(Reducer<E, P> reducer) {
  if (_cache[reducer] != null) return _cache[reducer] as Projector<E, P>;
  P projector(P cached, Events<E> events) {
    var p = cached;
    for (final event in events) {
      p = reducer(p, event);
    }
    return p;
  }

  return projector;
}

typedef Reducer<E, P> = P Function(P prev, E curr);
