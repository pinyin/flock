import 'package:flock/flock.dart';
import 'package:flutter/widgets.dart';

abstract class StoreWidget<E> extends StatefulWidget {
  const StoreWidget({Key key, this.store}) : super(key: key);

  final Store<E> store;
}

abstract class StoreState<W extends StoreWidget<E>, E, P> extends State<W> {
  P projector(P cached, Events<E> events);

  P projection;

  void dispatch(E event) {
    widget.store.dispatch(event);
  }

  @override
  void initState() {
    super.initState();
    projection = widget.store.getState(projector);
    _unsubscribe = widget.store.subscribe(_updateIfNecessary);
  }

  Unsubscribe _unsubscribe;

  @override
  void didUpdateWidget(W oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.store != widget.store) {
      _unsubscribe();
      _unsubscribe = widget.store.subscribe(_updateIfNecessary);
      _updateIfNecessary();
    }
  }

  @override
  void dispose() {
    super.dispose();
    _unsubscribe();
  }

  void _updateIfNecessary() {
    final curr = widget.store.getState<P>(projector);
    if (projection != curr) {
      setState(() {
        projection = curr;
      });
    }
  }
}
