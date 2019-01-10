# flock

[![Build Status](https://travis-ci.com/pinyin/flock.svg?branch=master)](https://travis-ci.com/pinyin/flock)

Coordinate Flutter widgets' states with event sourcing.

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

store.dispatch(EB(1));

store.subscribe((E e){
  final projection = store.getState(projector);
  // projection will be 1
});

//or

class BW extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StoreBuilder( 
      build: (BuildContext context, int p) => Text(
            '$p',
            textDirection: TextDirection.ltr,
          ),
      store: store, // receive store from wherever you like
      projector: projector, // you can also provide a method as projector
    );
  }
}


```

## Limits

This is still an early WIP. The future plan includes:
- better Flutter integration
- serialization & time travel support

## License

MIT

