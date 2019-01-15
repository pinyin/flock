import 'package:flock/flock.dart';
import 'package:flutter/widgets.dart';

class StoreBuilder<E, P> extends StatefulWidget {
  StoreBuilder(
      {Key key,
      @required this.store,
      @required this.reducer,
      @required this.initializer,
      @required this.builder})
      : super(key: key) {}

  final Store<E> store;
  final Reducer<P, E> reducer;
  final Initializer<P, E> initializer;
  final Widget Function(BuildContext context, P projection) builder;

  @override
  _StoreBuilderState<E, P> createState() => _StoreBuilderState<E, P>();
}

class _StoreBuilderState<E, P> extends State<StoreBuilder<E, P>> {
  @override
  void initState() {
    super.initState();
    _projection = widget.store.getState(widget.reducer, widget.initializer);
    _unsubscribe = widget.store.subscribe(_updateIfNecessary);
  }

  Unsubscribe _unsubscribe;
  P _projection;

  @override
  void didUpdateWidget(StoreBuilder<E, P> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.store != widget.store) {
      _unsubscribe();
      _unsubscribe = widget.store.subscribe(_updateIfNecessary);
      _updateIfNecessary();
    }
    if (oldWidget.reducer != widget.reducer) {
      _updateIfNecessary();
    }
  }

  @override
  void dispose() {
    super.dispose();
    _unsubscribe();
  }

  void _updateIfNecessary() {
    final curr = widget.store.getState<P>(widget.reducer, widget.initializer);
    if (_projection != curr) {
      setState(() {
        _projection = curr;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _projection);
  }
}
