import 'package:flock/flock.dart';
import 'package:flutter/widgets.dart';

abstract class StoreWidget<E> extends StatefulWidget {
  StoreWidget({Key key, @required this.store}) : super(key: key);

  final Store<E> store;
}

abstract class StoreState<W extends StoreWidget<E>, E> extends State<W> {
  @override
  void initState() {
    super.initState();
    _unsubscribe = widget.store.subscribe(_storeUpdated);
  }

  Unsubscribe _unsubscribe;

  @override
  void didUpdateWidget(W oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.store != widget.store) {
      _unsubscribe();
      _unsubscribe = widget.store.subscribe(_storeUpdated);
    }
  }

  @override
  void dispose() {
    super.dispose();
    _unsubscribe();
  }

  void _storeUpdated() {
    setState(() {});
  }
}
