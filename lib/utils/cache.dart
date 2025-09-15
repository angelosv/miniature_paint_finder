import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class LogosCacheManager extends CacheManager {
  static const key = 'logosCache';
  LogosCacheManager._()
    : super(
        Config(
          key,
          stalePeriod: const Duration(days: 30),
          maxNrOfCacheObjects: 200,
          repo: JsonCacheInfoRepository(databaseName: key),
          fileService: HttpFileService(),
        ),
      );
  static final LogosCacheManager instance = LogosCacheManager._();
}
