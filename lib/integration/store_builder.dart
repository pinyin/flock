import 'package:flock/flock.dart';
import 'package:flutter/widgets.dart';

class StoreBuilder<P> extends StatefulWidget {
  StoreBuilder(
      {Key key,
      @required this.store,
      @required this.projector,
      @required this.builder})
      : super(key: key) {}

  final Store store;
  final Projector<P> projector;
  final Widget Function(BuildContext context, P projection) builder;

  @override
  _StoreBuilderState<P> createState() => _StoreBuilderState<P>();
}

class _StoreBuilderState<P> extends State<StoreBuilder<P>> {
  @override
  void initState() {
    super.initState();
    _projection = widget.store.project(widget.projector);
    _unsubscribe = widget.store.subscribe(_scheduleUpdate);
  }

  Unsubscribe _unsubscribe;
  P _projection;

  @override
  void didUpdateWidget(StoreBuilder<P> oldWidget) {
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

  @override
  void reassemble() {
    _unsubscribe();
    super.reassemble();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _unsubscribe = widget.store.subscribe(_scheduleUpdate);
      _scheduleUpdate();
    });
  }

  void _scheduleUpdate() {
    final curr = widget.store.project<P>(widget.projector);
    setState(() {
      _projection = curr;
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _projection);
  }
}
