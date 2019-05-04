import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flock/flock.dart';
import 'package:meta/meta.dart';

SideEffect useCaseEffects(UseCaseEffectCreator creator) {
  return (events, store) {
    final inputs = Map<UseCaseID, StreamController<UseCaseEvent>>();
    final outputs = Map<UseCaseID, StreamSubscription>();
    final result = StreamController<Object>();

    bool hasEffect(UseCaseID forUseCase) {
      return inputs.containsKey(forUseCase);
    }

    void terminateEffect(UseCaseID useCase) {
      if (!inputs.containsKey(useCase)) return;
      outputs[useCase].cancel();
      outputs.remove(useCase);
      inputs[useCase].close();
      inputs.remove(useCase);
    }

    void handle(Object event) {
      if (event is UseCaseEvent) {
        final useCaseMap = store.project(toUseCaseMap);

        if (event is UseCaseCreated) {
          final useCase = creator(event);
          if (useCase != null) {
            final input = StreamController<UseCaseEvent>();
            inputs[event.context] = input;
            outputs[event.context] = useCase(input.stream, store)
                .listen(result.add, onError: result.addError);
          }
        }

        if (!useCaseMap.isRunning(event.context) && event is! UseCaseEnded) {
          // TODO report this
          return;
        }

        if (hasEffect(event.context)) inputs[event.context].add(event);
        for (final ancestor in useCaseMap.ancestors(event.context)) {
          if (hasEffect(ancestor)) inputs[ancestor].add(event);
        }

        bool withEndEvent(UseCaseID event) {
          final events = useCaseMap.events(event);
          return events.isNotEmpty && events.last is UseCaseEnded;
        }

        if (event is UseCaseEnded) {
          terminateEffect(event.context);
          for (final descendant in useCaseMap.descendants(event.context,
              skipRoot: withEndEvent)) {
            terminateEffect(descendant);
          }
        }
      }
    }

    for (final event in store.project(toAllUseCaseEvents)) {
      handle(event);
    }
    events.where((e) => e is UseCaseEvent).listen(handle);

    return result.stream;
  };
}

typedef UseCaseEffectCreator = SideEffect Function(UseCaseCreated spec);

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

        if (!isRunning(event.context)) return; // TODO report this

        _toEvents[event.context].add(event);
        for (final ancestor in ancestors(event.context)) {
          _toEvents[ancestor].add(event);
        }

        if (event is UseCaseEnded) {
          _ended.add(event.context);
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
      {bool skipRoot(UseCaseID root)}) sync* {
    for (final child in _toChildren[of]) {
      if (skipRoot != null && skipRoot(child)) continue;
      yield child;
      yield* descendants(child);
    }
  }

  Iterable<UseCaseEvent> events(UseCaseID of) sync* {
    yield* _toEvents[of];
  }

  bool isRunning(UseCaseID of) {
    final path = <UseCaseID>[];
    if (_ended.contains(of)) return false;
    for (final ancestor in ancestors(of)) {
      path.add(ancestor);
      if (_ended.contains(ancestor)) {
        for (final visited in path) {
          // cache result to improve future performance
          _ended.add(visited);
        }
        return false;
      }
    }
    return true;
  }

  final _ended = Set<UseCaseID>();
  final _toParent = Map<UseCaseID, UseCaseID>();
  final _toChildren = Map<UseCaseID, QueueList<UseCaseID>>()
    ..[UseCaseID.root] = QueueList();
  final _toEvents = Map<UseCaseID, QueueList<UseCaseEvent>>()
    ..[UseCaseID.root] = QueueList();
}

class UseCaseCreated extends UseCaseEvent {
  final Object spec;
  final UseCaseID parent;
  UseCaseCreated(this.spec, this.parent) : super(UseCaseID());
}

class UseCaseUpdated extends UseCaseEvent {
  final Object update;
  UseCaseUpdated(UseCaseID context, this.update) : super(context);
}

class UseCaseInteracted extends UseCaseEvent {
  final Object interaction;
  UseCaseInteracted(UseCaseID context, this.interaction) : super(context);
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
    return runtimeType.toString() + '#${id.id}';
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
