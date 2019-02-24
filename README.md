# flock

[![Build Status](https://travis-ci.com/pinyin/flock.svg?branch=master)](https://travis-ci.com/pinyin/flock)

Coordinate Flutter widgets' states with event sourcing.

Inspired by [Redux](https://github.com/reduxjs/redux/).

## Usage

```dart
import 'package:flock/flock.dart';

// Events
class E {}

class Minus extends E {
  Minus(this.value);

  final String value;
}

class Add extends E {
  Add(this.v);

  final int v;
}

// Store
final store = createStore<E>();

// In you widget:
class BW extends StatelessWidget {
  int reducer(int prev, E event) {
    var result = prev ?? 0;
    if (event is Add)
      result += event.v;
    else if (event is Minus)
      result -= int.tryParse(event.value) ?? 0;
    return result;
  }

  int initializer(int prev, List<E> events) {
    var result = prev ?? 0;
    for (var event in events) {
      if (event is Add)
        result += event.v;
      else if (event is Minus)
        result -= int.tryParse(event.value) ?? 0;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return StoreBuilder( 
      build: (BuildContext context, int p) => Text(
            '$p',
            textDirection: TextDirection.ltr,
          ),
      store: store, // use store from wherever you like
      reducer: reducer,
      initializer: initializer
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

