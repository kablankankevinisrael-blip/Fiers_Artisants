class CategoryModel {
  final String id;
  final String name;
  final String? icon;
  final String? description;
  final List<SubcategoryModel> subcategories;

  CategoryModel({
    required this.id,
    required this.name,
    this.icon,
    this.description,
    this.subcategories = const [],
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      icon: json['icon'],
      description: json['description'],
      subcategories: (json['subcategories'] as List<dynamic>?)
              ?.map((s) => SubcategoryModel.fromJson(s))
              .toList() ??
          [],
    );
  }
}

class SubcategoryModel {
  final String id;
  final String name;
  final String? categoryId;

  SubcategoryModel({
    required this.id,
    required this.name,
    this.categoryId,
  });

  factory SubcategoryModel.fromJson(Map<String, dynamic> json) {
    return SubcategoryModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      categoryId: json['categoryId']?.toString(),
    );
  }
}
