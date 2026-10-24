// Web'de sqflite çalışmaz; web için ayrı bir veritabanı fabrikası kullanılır.
export 'db_factory_stub.dart' if (dart.library.js_interop) 'db_factory_web.dart';
