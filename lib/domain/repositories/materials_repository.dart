import '../entities/material_item.dart';

abstract class MaterialsRepository {
  Future<List<MaterialItem>> getMaterials();
}
