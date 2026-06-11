import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/material_item.dart';
import '../../domain/repositories/materials_repository.dart';
import '../models/model_parsers.dart';

class MaterialsRepositoryImpl implements MaterialsRepository {
  MaterialsRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<List<MaterialItem>> getMaterials() async {
    final data = await _client
        .from('materials')
        .select('*, units(unit_number, title)')
        .order('created_at', ascending: false);
    return (data as List)
        .map((e) => materialFromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
