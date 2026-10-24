import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

// Web: veritabanı tarayıcının içinde (IndexedDB) saklanır.
void initDbFactory() {
  databaseFactory = databaseFactoryFfiWebNoWebWorker;
}
