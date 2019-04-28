import 'dart:async';

import 'package:flock/base/types.dart';
import 'package:flock/flock.dart';

typedef AsyncPublishFilter<E> = Stream<E> Function(
    Stream<E> events, Projectable<E> project);

StoreEnhancer<E> asyncPublish<E>([AsyncPublishFilter<E> filter]) {
  return (StoreCreator<E> createStore) =>
      (List<E> prepublish) => _AsyncPublishStore(
            createStore(prepublish),
            filter ??
                (Stream<E> events, Projectable<E> project) async* {
                  await for (final e in events) {
                    yield e;
                  }
                },
          );
}

class _AsyncPublishStore<E> extends StoreProxyBase<E> {
  _AsyncPublishStore(this._inner, this._filter) : super(_inner) {
    _resubscribe();
  }

  @override
  E publish(E event) {
    _incoming.add(event);
    return event;
  }

  @override
  void replaceEvents(List<E> events, [int cursor]) {
    _inner.replaceEvents(events, cursor);
    _resubscribe();
  }

  void _resubscribe() {
    if (_subscription is StreamSubscription<E>) _subscription.cancel();
    _subscription = _incoming.stream
        .transform(
            StreamTransformer.fromBind((stream) => _filter(stream, this)))
        .listen(_inner.publish);
  }

  final _incoming = StreamController<E>();
  StreamSubscription<E> _subscription;
  StoreForEnhancer<E> _inner;
  AsyncPublishFilter<E> _filter;
}
