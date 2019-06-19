import 'package:flock/flock.dart';

StoreEnhancer compressHistory(HistoryCompressor compressor) {
  return (StoreCreator createStore) =>
      () => _CompressHistoryProxy(compressor, createStore());
}

typedef HistoryCompressor = void Function(StoreEventStorage store);

class _CompressHistoryProxy extends StoreProxyBase {
  final HistoryCompressor compressor;

  @override
  void rewriteHistory(QueueList<Object> events, [int cursor]) {
    super.rewriteHistory(events, cursor);
  }

  @override
  E publish<E>(E event) {
    final result = inner.publish(event);
    compressor(this);
    return result;
  }

  _CompressHistoryProxy(this.compressor, StoreForEnhancer inner) : super(inner);
}
