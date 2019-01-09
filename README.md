# flock

Coordinate Flutter widgets&#x27; states with event sourcing.

Inspired by [Redux](https://github.com/reduxjs/redux/).

## Usage

```dart
import 'package:flock/flock.dart';

// Events
class E {}

class EA extends E {
  EA(this.value);

  final String value;
}

class EB extends E {
  EB(this.v);

  final int v;
}

// Store
final store = createStore<E>();

// Your projector

final projector = (int prev, EventStack<E> events, Projectable<E> store) {
  var result = prev ?? 0;
   // notice the events are in reverse chronological order
  for (var event in events) {
    if (event is EB)
      result += event.v;
    else if (event is EA)
      result -= int.tryParse(event.value) ?? 0;
  }
  return result;
};

// In you widget:

store.subscribe((E e){
  final projection = store.projectWith(projector);
  // or
  final projection = store.get(projector);
  // update your state
});

```

## Limits

This is still an early WIP. The future plan includes:
- better Flutter integration
- serialization & time travel support

## License

MIT

