import 'package:lubao_core/lubao_core.dart';

/// В вебе — без диска: память вкладки.
class DataCacheStore extends MemoryCacheStore {
  DataCacheStore({this.folder = 'lubao_data'});

  final String folder;
}
