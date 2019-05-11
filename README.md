# flock

[![Build Status](https://travis-ci.com/pinyin/flock.svg?branch=master)](https://travis-ci.com/pinyin/flock)

Coordinate Flutter widgets' states with event sourcing.

Inspired by [Redux](https://github.com/reduxjs/redux/).

## Design



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
final store = createStore();

// In you widget:
class BW extends StatelessWidget {
  int sum(int prev, Iterable<E> events, Projectable store) {
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
      builder: (BuildContext context, int p) => Text(
            '$p',
            textDirection: TextDirection.ltr,
          ),
      store: store, // use store from wherever you like
      projector: sum
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

