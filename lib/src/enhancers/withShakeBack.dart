import 'dart:async';

import 'package:flock/flock.dart';
import 'package:flock/src/base/types.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sensors/sensors.dart';

/// Shake your device to go back to previous state
StoreEnhancer<E> withShakeBack<E>(Stream<UserAccelerometerEvent> accEvents) {
  return (StoreCreator<E> inner) =>
      (Iterable<E> prepublish) => _ShakeBackStore(inner(prepublish));
}

class _ShakeBackStore<E> extends InnerStore<E> {
  _ShakeBackStore(this._inner) {
    _isShaking$().where((e) => e).listen((e) {
      _back();
    });
  }

  InnerStore<E> _inner;
  CompositeSubscription cleanup;

  @override
  P getState<P>(projector) {
    return _inner.getState(projector);
  }

  @override
  void dispatch(E event) {
    _events.add(event);
    _inner.dispatch(event);
  }

  final _events = List<E>();

  @override
  void replaceEvents(Iterable<E> events) {
    _inner.replaceEvents(events);
    _events.clear();
    _events.addAll(events);
  }

  void _back() {
    if (_events.length < 1) return;
    _events.removeLast();
    _inner.replaceEvents(_events);
    _listeners.forEach((l) => l());
  }

  @override
  subscribe(subscriber) {
    final unsubscribeFromInner = _inner.subscribe(subscriber);
    _listeners.add(subscriber);
    return () {
      unsubscribeFromInner();
      _listeners.remove(subscriber);
    };
  }

  final _listeners = Set<Subscriber<E>>();
}

Observable<bool> _isShaking$() {
  final timeout = Duration(milliseconds: 300);
  final accelerationThreshold = 1;
  final sampleInterval = Duration(milliseconds: 50);
  final moveCountThreshold = 2;

  Stream<bool> extractShake(Stream<UserAccelerometerEvent> stream) async* {
    int moveCount = 0;

    var lastSampleAt = DateTime.now();

    double lastX = 0;
    double lastY = 0;
    double lastZ = 0;

    bool _isReverted(num now, num rev) {
      return now * rev <= 0;
    }

    bool _isMoving(num now) {
      return now.abs() >= accelerationThreshold;
    }

    await for (final e in stream) {
      final now = DateTime.now();
      final sinceLast = now.difference(lastSampleAt);

      if (sinceLast < sampleInterval) continue;

      if (sinceLast > timeout) {
        moveCount = 0;
      }
      lastSampleAt = now;

      if (!_isMoving(e.x) && !_isMoving(e.y) && !_isMoving(e.z)) continue;

      final bool isShaking = (_isMoving(e.x) && _isReverted(e.x, lastX)) ||
          (_isMoving(e.y) && _isReverted(e.y, lastY)) ||
          (_isMoving(e.z) && _isReverted(e.z, lastZ));

      lastX = e.x;
      lastY = e.y;
      lastZ = e.z;

      if (isShaking) moveCount++;

      if (moveCount >= moveCountThreshold) yield true;
    }
  }

  final shake$ = Observable(userAccelerometerEvents)
      .transform(StreamTransformer.fromBind(extractShake));
  return shake$
      .switchMap((e) => Observable.timer(false, timeout).startWith(e))
      .startWith(false)
      .distinct();
}
