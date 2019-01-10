import 'package:flock/flock.dart';
import 'package:flutter/widgets.dart';

class StoreBuilder<E, P> extends StoreWidget<E> {
  StoreBuilder(
      {Key key,
      @required Store<E> store,
      @required this.projector,
      @required this.build})
      : super(key: key, store: store);

  final Projector<E, P> projector;
  final Widget Function(BuildContext context, P projection) build;

  @override
  _StoreBuilderState<E, P> createState() => _StoreBuilderState<E, P>();
}

class _StoreBuilderState<E, P> extends StoreState<StoreBuilder<E, P>, E> {
  @override
  Widget build(BuildContext context) {
    return widget.build(context, widget.store.getState<P>(widget.projector));
  }
}
