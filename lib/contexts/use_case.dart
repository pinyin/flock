import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flock/flock.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

StoreEnhancer withUseCaseActors(UseCaseActorCreator createUseCaseActor) {
  return (StoreCreator createStore) => (Iterable<Object> prepublish) =>
      _WithUseCaseEffectsStoreProxy(
          createStore(prepublish), createUseCaseActor);
}

typedef UseCaseActorCreator = UseCaseActor Function(UseCaseCreated spec);
typedef UseCaseActor = Stream<Object> Function(
    Stream<Object> events, Store store);

class _WithUseCaseEffectsStoreProxy extends StoreProxyBase {
  @override
  E publish<E>(E event) {
    return event is UseCaseEvent
        ? _publishUseCaseEvent(event) as E
        : inner.publish(event);
  }

  @override
  void replaceEvents(QueueList<Object> events, [int cursor]) {
    final prevCursor = inner.cursor;

    super.replaceEvents(events, cursor);

    if (prevCursor != inner.cursor) {
      for (final output in outputs.values) {
        output.cancel();
      }
      outputs.clear();
      for (final input in inputs.values) {
        input.close();
      }
      inputs.clear();

      final useCaseMap = project(toUseCaseMap);
      for (final useCase in useCaseMap.descendants(UseCaseID.root,
          skipSubtreeWhen: useCaseMap.isNotRunning)) {
        final create = useCaseMap.events(useCase).first;
        assert(create is UseCaseCreated);
        _mayStartEffect(create as UseCaseCreated);
      }
    }
  }

  UseCaseEvent _publishUseCaseEvent(UseCaseEvent event) {
    final useCase = event.context;

    if (!project(toUseCaseMap)
        .isRunning(event is UseCaseCreated ? event.parent : useCase))
      return null;

    final publishResult = inner.publish(event);
    final useCaseMap = project(toUseCaseMap);

    if (event is UseCaseCreated) {
      _mayStartEffect(event);
    }

    if (_hasEffect(useCase)) inputs[useCase].add(event);
    for (final ancestor in useCaseMap.ancestors(useCase)) {
      if (_hasEffect(ancestor)) inputs[ancestor].add(event);
    }

    if (event is UseCaseEnded) {
      _mayTerminateEffect(useCase);

      for (final descendant
          in useCaseMap.descendants(useCase, skipSubtreeWhen: _hasNoEffect)) {
        _mayTerminateEffect(descendant);
      }
    }

    return publishResult;
  }

  bool _hasEffect(UseCaseID forUseCase) {
    return inputs.containsKey(forUseCase);
  }

  bool _hasNoEffect(UseCaseID forUseCase) {
    return !_hasEffect(forUseCase);
  }

  void _mayStartEffect(UseCaseCreated event) {
    final startActor = createUseCaseEffect(event);
    final forUseCase = event.context;
    if (startActor != null) {
      final input = StreamController<UseCaseEvent>();
      inputs[forUseCase] = input;
      outputs[forUseCase] =
          startActor(input.stream, _UseCaseEffectStoreProxy(forUseCase, this))
              .listen(
        publish,
        onDone: () => publish(UseCaseEnded(forUseCase)),
      );
    }
  }

  void _mayTerminateEffect(UseCaseID useCase) {
    if (!_hasEffect(useCase)) return;
    outputs[useCase].cancel();
    outputs.remove(useCase);
    inputs[useCase].close();
    inputs.remove(useCase);
  }

  final UseCaseActorCreator createUseCaseEffect;
  final inputs = Map<UseCaseID, StreamController<UseCaseEvent>>();
  final outputs = Map<UseCaseID, StreamSubscription>();

  _WithUseCaseEffectsStoreProxy(
      StoreForEnhancer inner, this.createUseCaseEffect)
      : super(inner);
}

class _UseCaseEffectStoreProxy extends StoreProxyBase {
  @override
  E publish<E>(E event) {
    if (event is UseCaseEvent)
      return inner
              .project(toUseCaseMap)
              .ancestors(event.context)
              .contains(scope)
          ? inner.publish(event)
          : null;
    return inner.publish(event);
  }

  final UseCaseID scope;

  _UseCaseEffectStoreProxy(this.scope, StoreForEnhancer inner) : super(inner);
}

Projector<QueueList<UseCaseEvent>> toAllUseCaseEvents = (prev, events, store) {
  QueueList<UseCaseEvent> result = prev ?? QueueList();
  for (final event in events) {
    if (event is UseCaseEvent) result.add(event);
  }
  return result;
};

Projector<UseCaseMap> toUseCaseMap = (prev, events, store) {
  final result = prev ?? UseCaseMap();
  result.update(events);
  return result;
};

class UseCaseMap {
  void update(Iterable<Object> events) {
    for (final event in events) {
      if (event is UseCaseEvent) {
        if (event is UseCaseCreated) {
          assert(!_toEvents.containsKey(event.context));
          assert(isRunning(event.parent));
          _toEvents[event.context] = QueueList();
          _toParent[event.context] = event.parent;
          _toChildren[event.context] = QueueList();
          _toChildren[event.parent].add(event.context);
          _runningSet.add(event.context);
        }

        assert(isRunning(event.context));

        _toEvents[event.context].add(event);
        for (final ancestor in ancestors(event.context)) {
          _toEvents[ancestor].add(event);
        }

        if (event is UseCaseEnded) {
          assert(event.context != UseCaseID.root);
          _runningSet.remove(event.context);
          for (final descendant
              in descendants(event.context, skipSubtreeWhen: isNotRunning)) {
            _runningSet.remove(descendant);
          }
        }
      }
    }
  }

  Iterable<UseCaseID> ancestors(UseCaseID of) sync* {
    for (var context = _toParent[of];
        context != null;
        context = _toParent[context]) {
      yield context;
    }
  }

  Iterable<UseCaseID> descendants(UseCaseID of,
      {bool skipSubtreeWhen(UseCaseID root)}) sync* {
    for (final child in _toChildren[of]) {
      if (skipSubtreeWhen != null && skipSubtreeWhen(child)) continue;
      yield child;
      yield* descendants(child, skipSubtreeWhen: skipSubtreeWhen);
    }
  }

  Iterable<UseCaseEvent> events(UseCaseID of) sync* {
    yield* _toEvents[of];
  }

  bool has(UseCaseID useCase) {
    return _toEvents.containsKey(useCase);
  }

  bool isNotRunning(UseCaseID of) {
    return !_runningSet.contains(of);
  }

  bool isRunning(UseCaseID of) {
    return _runningSet.contains(of);
  }

  UseCaseCreated getStartEvent(UseCaseID useCase) {
    final result = _toEvents[useCase];
    assert(result.first is UseCaseCreated);
    return result.first as UseCaseCreated;
  }

  UseCaseEnded getEndEvent(UseCaseID useCase) {
    final result = _toEvents[useCase];
    assert(result.last is UseCaseEnded);
    return result.last as UseCaseEnded;
  }

  final _runningSet = Set<UseCaseID>()..add(UseCaseID.root);
  final _toParent = Map<UseCaseID, UseCaseID>();
  final _toChildren = Map<UseCaseID, QueueList<UseCaseID>>()
    ..[UseCaseID.root] = QueueList();
  final _toEvents = Map<UseCaseID, QueueList<UseCaseEvent>>()
    ..[UseCaseID.root] = QueueList();
}

class UseCaseCreated extends UseCaseEvent {
  final UseCaseID parent;
  UseCaseCreated(this.parent) : super(UseCaseID());
}

class UseCaseUpdated extends UseCaseEvent {
  UseCaseUpdated(UseCaseID context) : super(context);
}

class UseCaseEnded extends UseCaseEvent {
  UseCaseEnded(UseCaseID context) : super(context);
}

@immutable
abstract class UseCaseEvent {
  final UseCaseID context;
  final UseCaseEventID id;

  @override
  bool operator ==(dynamic other) {
    return other.runtimeType == runtimeType &&
        other is UseCaseEvent &&
        other.id == id;
  }

  @override
  int get hashCode => runtimeType.hashCode ^ id.hashCode;

  @override
  String toString() {
    return ' UseCase#${context.id} ' + runtimeType.toString();
  }

  UseCaseEvent(this.context) : id = UseCaseEventID();
}

@immutable
class UseCaseID {
  final String id;

  @override
  bool operator ==(dynamic other) {
    return other.runtimeType == runtimeType &&
        other is UseCaseID &&
        other.id == id;
  }

  @override
  int get hashCode => runtimeType.hashCode ^ id.hashCode;

  UseCaseID() : id = uuid.v4();
  const UseCaseID._(this.id);
  static const root = const UseCaseID._('');
}

@immutable
class UseCaseEventID {
  final String id;

  @override
  bool operator ==(dynamic other) {
    return other.runtimeType == runtimeType &&
        other is UseCaseEventID &&
        other.id == id;
  }

  @override
  int get hashCode => runtimeType.hashCode ^ id.hashCode;

  UseCaseEventID() : id = uuid.v4();
}

final uuid = new Uuid();
