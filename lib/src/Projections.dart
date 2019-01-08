import './EventStore.dart';

class Projections<E> {
  void set<P>(Projector<E, P> projector, int cursor, P projection) {
    _expando[projector] = _CachedProjection(cursor, projection);
  }

  _CachedProjection<P> get<P>(Projector<E, P> projector) {
    return _expando[projector] as _CachedProjection<P>;
  }

  void clear() {
    _expando = new Expando<dynamic>();
  }

  var _expando = new Expando<dynamic>();
}

class _CachedProjection<P> {
  _CachedProjection(this.cursor, this.projection);

  int cursor;
  P projection;
}
