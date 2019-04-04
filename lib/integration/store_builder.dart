import 'package:flock/flock.dart';
import 'package:flutter/widgets.dart';

class StoreBuilder<E, P> extends StatefulWidget {
  StoreBuilder(
      {Key key,
      @required this.store,
      @required this.projector,
      @required this.builder})
      : super(key: key) {}

  final Store<E> store;
  final Projector<P, E> projector;
  final Widget Function(BuildContext context, P projection) builder;

  @override
  _StoreBuilderState<E, P> createState() => _StoreBuilderState<E, P>();
}

class _StoreBuilderState<E, P> extends State<StoreBuilder<E, P>> {
  @override
  void initState() {
    super.initState();
    _projection = widget.store.project(widget.projector);
    _unsubscribe = widget.store.subscribe(_scheduleUpdate);
  }

  Unsubscribe _unsubscribe;
  P _projection;

  @override
  void didUpdateWidget(StoreBuilder<E, P> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.store != widget.store) {
      _unsubscribe();
      _unsubscribe = widget.store.subscribe(_scheduleUpdate);
      _scheduleUpdate();
    }
    if (oldWidget.projector != widget.projector) {
      _scheduleUpdate();
    }
  }

  @override
  void dispose() {
    super.dispose();
    _unsubscribe();
  }

  void _scheduleUpdate() {
    // TODO batch updates
    final curr = widget.store.project<P>(widget.projector);
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