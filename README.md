# flock

Coordinate Flutter widgets&#x27; states with event sourcing.

Inspired by [Redux](https://github.com/reduxjs/redux/).

## Usage

```dart
import 'package:flock/flock.dart';

// Events
class E {}
class EA extends E {}
class EB extends E {}

// EventStore
final eventStore = createEventStore<E>();

// Your projector

final projector = (int prev, EventStack<E> events, Projectable<E> store) {
  var result = prev ?? 0;
   // notice the events are in reverse chronological order
  for (var event in events) {
    projectCount++;
    if (event is EB)
      result += event.v;
    else if (event is EA)
      result -= int.tryParse(event.value) ?? 0;
  }
  return result;
};

// In you widget:

eventStore.subscribe((E e){
  final projection = eventStore.projectWith(projector);
  // update your state
});

```

## Limits

This is still an early WIP. The future plan includes:
- better Flutter integration
- serialization & time travel support

## License

MIT

