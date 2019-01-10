import 'package:flock/flock.dart';
import 'package:flutter/widgets.dart';

class StoreBuilder<E, P> extends StatefulWidget {
  StoreBuilder(
      {Key key,
        @required this.store,
      @required this.projector,
        @required this.builder})
      : super(key: key);

  final Store<E> store;
  final Projector<E, P> projector;
  final Widget Function(BuildContext context, P projection) builder;

  @override
  _StoreBuilderState<E, P> createState() => _StoreBuilderState<E, P>();
}

class _StoreBuilderState<E, P> extends State<StoreBuilder<E, P>> {
  @override
  void initState() {
    super.initState();
    _unsubscribe = widget.store.subscribe(_updateIfNecessary);
    _projection = widget.store.getState(widget.projector);
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
    if (oldWidget.projector != widget.projector) {
      _updateIfNecessary();
    }
  }

  @override
  void dispose() {
    super.dispose();
    _unsubscribe();
  }

  void _updateIfNecessary() {
    final curr = widget.store.getState<P>(widget.projector);
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
