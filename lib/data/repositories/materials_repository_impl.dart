import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/material_item.dart';
import '../../domain/repositories/materials_repository.dart';
import '../models/model_parsers.dart';

class MaterialsRepositoryImpl implements MaterialsRepository {
  MaterialsRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<List<MaterialItem>> getMaterials() async {
    debugPrint('=== FETCHING MATERIALS FROM SUPABASE ===');
    try {
      final data = await _client
          .from('materials')
          .select('*, units(unit_number, title)')
          .order('created_at', ascending: false);

      debugPrint('=== RAW RESPONSE TYPE: ${data.runtimeType} ===');
      debugPrint('=== RAW RESPONSE LENGTH: ${(data as List).length} ===');

      final items = <MaterialItem>[];
      for (final e in data) {
        try {
          items.add(materialFromJson(Map<String, dynamic>.from(e as Map)));
        } catch (err, st) {
          debugPrint('❌ Skipped item due to error: $err');
          debugPrint('$st');
        }
      }

      debugPrint('=== SUCCESSFULLY PARSED: ${items.length} items ===');
      return items;
    } catch (e, st) {
      debugPrint('❌ SUPABASE FETCH ERROR: $e');
      debugPrint('$st');
      rethrow;
    }
  }
}