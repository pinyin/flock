import 'package:flock/flock.dart';

StoreEnhancer compressHistory(HistoryCompressor compressor) {
  return (StoreCreator createStore) => (Iterable<Object> prepublish) =>
      _CompressHistoryProxy(compressor, createStore(prepublish));
}

typedef HistoryCompressor = void Function(StoreEventStorage store);

class _CompressHistoryProxy extends StoreProxyBase {
  final HistoryCompressor compressor;

  @override
  void replaceEvents(QueueList<Object> events, [int cursor]) {
    super.replaceEvents(events, cursor);
  }

  @override
  E publish<E>(E event) {
    final result = inner.publish(event);
    compressor(this);
    return result;
  }

  _CompressHistoryProxy(this.compressor, StoreForEnhancer inner) : super(inner);
}
