import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cashlytics/core/services/supabase/client.dart';

class DatabaseService {
  const DatabaseService({this.schema = 'public'});

  final String schema;

  SupabaseQueryBuilder _table(String table) =>
      supabase.schema(schema).from(table);

  Future<List<Map<String, dynamic>>> fetchAll(
    String table, {
    String columns = '*',
    Map<String, dynamic>? filters,
    String? orderBy,
    bool ascending = true,
    int? limit,
    int? offset,
  }) async {
    dynamic query = _table(table).select(columns);
    if (filters != null) {
      for (final entry in filters.entries) {
        final key = entry.key;
        final value = entry.value;
        if (value is List) {
          query = query.inFilter(key, value);
        } else {
          query = query.eq(key, value);
        }
      }
    }
    if (orderBy != null) {
      query = query.order(orderBy, ascending: ascending);
    }
    if (offset != null && limit != null) {
      query = query.range(offset, offset + limit - 1);
    } else if (limit != null) {
      query = query.limit(limit);
    }
    final data = await query;
    return List<Map<String, dynamic>>.from(data);
  }

  Future<Map<String, dynamic>?> fetchSingle(
    String table, {
    required String matchColumn,
    required dynamic matchValue,
    String columns = '*',
  }) async {
    final data = await _table(
      table,
    ).select(columns).eq(matchColumn, matchValue).limit(1);
    return data.isEmpty ? null : Map<String, dynamic>.from(data.first);
  }

  Future<Map<String, dynamic>?> insert(
    String table,
    Map<String, dynamic> values, {
    String columns = '*',
  }) async {
    try {
      final data = await _table(
        table,
      ).insert(values).select(columns).maybeSingle();
      
      if (data == null) {
        debugPrint('Warning: Insert into $table succeeded but select returned no rows. Values: $values');
      }
      
      return data == null ? null : Map<String, dynamic>.from(data);
    } catch (e) {
      debugPrint('Error inserting into $table: $e. Values: $values');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> insertMany(
    String table,
    List<Map<String, dynamic>> rows, {
    String columns = '*',
  }) async {
    final data = await _table(table).insert(rows).select(columns);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<Map<String, dynamic>?> updateById(
    String table, {
    required String matchColumn,
    required dynamic matchValue,
    required Map<String, dynamic> values,
    String columns = '*',
  }) async {
    final data = await _table(
      table,
    ).update(values).eq(matchColumn, matchValue).select(columns).maybeSingle();
    return data == null ? null : Map<String, dynamic>.from(data);
  }

  Future<void> deleteById(
    String table, {
    required String matchColumn,
    required dynamic matchValue,
  }) async {
    await _table(table).delete().eq(matchColumn, matchValue);
  }

  Future<List<Map<String, dynamic>>> upsert(
    String table,
    List<Map<String, dynamic>> rows, {
    String columns = '*',
    String? onConflict,
    bool ignoreDuplicates = false,
  }) async {
    final data = await _table(table)
        .upsert(
          rows,
          onConflict: onConflict,
          ignoreDuplicates: ignoreDuplicates,
        )
        .select(columns);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<dynamic> rpc(
    String functionName, {
    Map<String, dynamic>? params,
  }) async {
    return await supabase.rpc(functionName, params: params);
  }
}
