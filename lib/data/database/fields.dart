class RecipeFields {
  static const columns = <String>[
    'id',
    'lable',
    'image',
    'description',
    'bookmarked',
  ];
  static const tableName = 'Recipes';
  static const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
  static const textType = 'TEXT NOT NULL';
  static const boolType = 'INTEGER NOT NULL';
  static const id = 'id';
  static const lable = 'lable';
  static const image = 'image';
  static const description = 'description';
  static const bookmarked = 'bookmarked';
}

class IngredientFields {
  static const columns = <String>['id', 'recipe_id', 'name', 'amount'];
  static const tableName = 'Ingredients';
  static const intgerType = 'INTEGER NOT NULL';
  static const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
  static const textType = 'TEXT NOT NULL';
  static const doubleType = 'REAL NOT NULL';
  static const id = 'id';
  static const recipeId = 'recipe_id';
  static const name = 'name';
  static const amount = 'amount';
}
