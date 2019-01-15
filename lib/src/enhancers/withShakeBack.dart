import 'dart:async';

import 'package:flock/flock.dart';
import 'package:flock/src/base/types.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sensors/sensors.dart';

/// Shake your device to go back to previous state
StoreEnhancer<E> withShakeBack<E>(Stream<UserAccelerometerEvent> accEvents) {
  return (StoreCreator<E> inner) =>
      (List<E> prepublish) => _ShakeBackStore(inner(prepublish));
}

class _ShakeBackStore<E> extends StoreForEnhancer<E> {
  _ShakeBackStore(this._inner) {
    _isShaking$().where((e) => e).listen((e) {
      _back();
    });
  }

  StoreForEnhancer<E> _inner;
  CompositeSubscription cleanup;

  void _back() {
    if (_inner.events.length <= 0) return;
    final events = List<E>.from(_inner.events);
    events.removeLast();
    _inner.replaceEvents(events, _inner.cursor - 1);
    _inner.dispatch();
  }

  @override
  int get cursor => _inner.cursor;

  @override
  void dispatch([E event]) {
    _inner.dispatch();
  }

  @override
  List<E> get events => _inner.events;

  @override
  P getState<P>(projector, initializer) {
    return _inner.getState(projector, initializer);
  }

  @override
  void replaceEvents(List<E> events, [int cursor]) {
    return _inner.replaceEvents(events, cursor);
  }

  @override
  subscribe(subscriber) {
    return _inner.subscribe(subscriber);
  }
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
      .startWith(false);
}
