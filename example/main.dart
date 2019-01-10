import 'package:flock/flock.dart';
import 'package:flutter/widgets.dart';

class Example extends StatelessWidget {
  final store = createStore<AppEvent>();

  int counter(
      int prev, EventStack<AppEvent> events, Projectable<AppEvent> store) {
    var next = prev ?? 0;
    for (final event in events) {
      if (event is Increase) next++;
      if (event is Decrease) next--;
    }
    return next;
  }

  Example() {
    store.dispatch(Increase());
  }

  @override
  Widget build(BuildContext context) {
    return StoreBuilder(
      builder: (BuildContext context, int count) {
        return Text(
          '$count',
          textDirection: TextDirection.ltr,
        );
      },
      store: store,
      projector: counter,
    );
  }
}

class AppEvent {}

class Increase extends AppEvent {}

class Decrease extends AppEvent {}
