import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:sqflite/sqflite.dart' as mobile;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/platform/platform_info.dart';
import '../../domain/repositories/product_extract_repository.dart';

class ProductExtractRepositoryImpl implements ProductExtractRepository {
  @override
  Future<Result<ProductCsv>> extract(String path) async {
    final DatabaseFactory factory = PlatformInfo.isDesktop ? databaseFactoryFfi : mobile.databaseFactory;
    Database? source;
    try {
      source = await factory.openDatabase(path, options: OpenDatabaseOptions(readOnly: true, singleInstance: false));
      final hasProducts = await source.rawQuery("SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = 'products'");
      if (hasProducts.isEmpty) return const Err(ValidationFailure('That file has no products table'));
      final columns = [for (final c in await source.rawQuery('PRAGMA table_info(products)')) c['name'] as String];
      final rows = await source.query('products', orderBy: 'id');
      final text = csv.encode([
        columns,
        for (final r in rows) [for (final c in columns) r[c] ?? ''],
      ]);
      // A byte order mark so Excel reads Sinhala and Tamil names correctly.
      return Ok((products: rows.length, bytes: Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode(text)])));
    } catch (e) {
      return Err(ValidationFailure('$e'.contains('not a database') ? 'That file is not a database' : 'Could not read the database'));
    } finally {
      await source?.close();
    }
  }
}
