import 'package:flock/flock.dart';

class MathEvent {}

class Minus extends MathEvent {
  Minus(this.value);

  final String value;
}

class Plus extends MathEvent {
  Plus(this.v);

  final int v;
}

class Equals extends MathEvent {
  Equals(this.v);

  final int v;
}

final Projector<int, MathEvent> sum = (prev, events, _) {
  return events.fold<int>(prev is int ? prev : 0, (int next, MathEvent event) {
    if (event is Plus)
      next += event.v;
    else if (event is Minus)
      next -= int.tryParse(event.value) ?? 0;
    else if (event is Equals) {
      next = event.v;
    }
    return next;
  });
};
