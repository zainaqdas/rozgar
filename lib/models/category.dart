class Subcategory {
  final String id;
  final String nameEn;
  final String nameUr;

  const Subcategory({
    required this.id,
    required this.nameEn,
    required this.nameUr,
  });

  factory Subcategory.fromJson(Map<String, dynamic> json) => Subcategory(
        id: json['id'] as String,
        nameEn: json['nameEn'] as String,
        nameUr: json['nameUr'] as String,
      );
}

class Category {
  final String id;
  final String nameEn;
  final String nameUr;
  final String iconName;
  final String parentCategory;
  final List<Subcategory> subcategories;

  const Category({
    required this.id,
    required this.nameEn,
    required this.nameUr,
    this.iconName = '',
    this.parentCategory = '',
    this.subcategories = const [],
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'] as String,
        nameEn: json['nameEn'] as String,
        nameUr: json['nameUr'] as String,
        iconName: json['iconName'] as String? ?? '',
        parentCategory: json['parentCategory'] as String? ?? '',
        subcategories: (json['subcategories'] as List<dynamic>?)
                ?.map((e) => Subcategory.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}
