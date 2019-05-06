import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flock/flock.dart';
import 'package:meta/meta.dart';

StoreEnhancer withUseCaseEffects(UseCaseEffectCreator createUseCaseEffect) {
  return (StoreCreator createStore) => (Iterable<Object> prepublish) =>
      _WithUseCaseEffectsStoreProxy(
          createStore(prepublish), createUseCaseEffect);
}

typedef UseCaseEffectCreator = UseCaseEffect Function(UseCaseCreated spec);
typedef UseCaseEffect = Stream<Object> Function(
    Stream<Object> events, Store store);

class _WithUseCaseEffectsStoreProxy extends StoreProxyBase {
  @override
  E publish<E>(E event) {
    return event is UseCaseEvent
        ? _publishUseCaseEvent(event) as E
        : inner.publish(event);
  }

  UseCaseEvent _publishUseCaseEvent(UseCaseEvent event) {
    final useCase = event.context;

    if (!project(toUseCaseMap)
        .isRunning(event is UseCaseCreated ? event.parent : useCase))
      return null;

    final publishResult = inner.publish(event);
    final useCaseMap = project(toUseCaseMap);

    if (event is UseCaseCreated) {
      _mayStartEffect(createUseCaseEffect(event), useCase);
    }

    if (_hasEffect(useCase)) inputs[useCase].add(event);
    for (final ancestor in useCaseMap.ancestors(useCase)) {
      if (_hasEffect(ancestor)) inputs[ancestor].add(event);
    }

    if (event is UseCaseEnded) {
      _mayTerminateEffect(useCase);

      bool hasEndEvent(UseCaseID event) {
        final events = useCaseMap.events(event);
        return events.isNotEmpty && events.last is UseCaseEnded;
      }

      for (final descendant
          in useCaseMap.descendants(useCase, skipSubtreeWhen: hasEndEvent)) {
        _mayTerminateEffect(descendant);
      }
    }

    return publishResult;
  }

  bool _hasEffect(UseCaseID forUseCase) {
    return inputs.containsKey(forUseCase);
  }

  void _mayStartEffect(UseCaseEffect effect, UseCaseID as) {
    if (effect != null) {
      final input = StreamController<UseCaseEvent>();
      inputs[as] = input;
      outputs[as] = effect(input.stream, this).listen(
        publish,
        onDone: () => publish(UseCaseEnded(as)),
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

  final UseCaseEffectCreator createUseCaseEffect;
  final inputs = Map<UseCaseID, StreamController<UseCaseEvent>>();
  final outputs = Map<UseCaseID, StreamSubscription>();
  final result = StreamController<Object>();

  _WithUseCaseEffectsStoreProxy(
      StoreForEnhancer inner, this.createUseCaseEffect)
      : super(inner);
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
          _toEvents[event.context] = QueueList();
          _toParent[event.context] = event.parent;
          _toChildren[event.context] = QueueList();
          _toChildren[event.parent].add(event.context);
        }

        assert(isRunning(event.context));

        _toEvents[event.context].add(event);
        for (final ancestor in ancestors(event.context)) {
          _toEvents[ancestor].add(event);
        }

        if (event is UseCaseEnded) {
          _endedSet.add(event.context);
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
      yield* descendants(child);
    }
  }

  Iterable<UseCaseEvent> events(UseCaseID of) sync* {
    yield* _toEvents[of];
  }

  bool has(UseCaseID useCase) {
    return _toEvents.containsKey(useCase);
  }

  bool isRunning(UseCaseID of) {
    final path = <UseCaseID>[];
    if (!has(of)) return false;
    if (_endedSet.contains(of)) return false;
    for (final ancestor in ancestors(of)) {
      path.add(ancestor);
      if (_endedSet.contains(ancestor)) {
        for (final visited in path) {
          // cache result to improve future performance
          _endedSet.add(visited);
        }
        return false;
      }
    }
    return true;
  }

  final _endedSet = Set<UseCaseID>(); // TODO auto cleanup
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

  UseCaseID() : id = _RandomString();
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

  UseCaseEventID() : id = _RandomString();
}

const chars = "abcdefghijklmnopqrstuvwxyz0123456789";

String _RandomString([int length = 10]) {
  Random rnd = new Random(new DateTime.now().millisecondsSinceEpoch);
  String result = "";
  for (var i = 0; i < length; i++) {
    result += chars[rnd.nextInt(chars.length)];
  }
  return result;
}
