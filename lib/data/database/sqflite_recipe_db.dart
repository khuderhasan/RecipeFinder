import 'package:sqflite/sqflite.dart';
import '../models/ingredient.dart';
import '../models/recipe.dart';
import 'fields.dart';

class RecipeSQFLiteDb {
  static final instance = RecipeSQFLiteDb._internal();

  RecipeSQFLiteDb._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = '$databasePath/sqfliterecipes.db';
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
    );
  }

  Future<void> _createDatabase(Database db, _) async {
    print('creating database');
    try {
      return await db.execute('''CREATE TABLE  ${RecipeFields.tableName} (
    ${RecipeFields.id} ${RecipeFields.idType},
    ${RecipeFields.lable} ${RecipeFields.textType},
    ${RecipeFields.image} ${RecipeFields.textType},
    ${RecipeFields.description} ${RecipeFields.textType},
    ${RecipeFields.bookmarked} ${RecipeFields.boolType}
    );
    CREATE TABLE ${IngredientFields.tableName} (
    ${IngredientFields.id} ${IngredientFields.intgerType},
    ${IngredientFields.name} ${IngredientFields.textType},
    ${IngredientFields.recipeId} ${IngredientFields.intgerType},
    ${IngredientFields.amount} ${IngredientFields.doubleType},
    );
    ''');
    } on Exception catch (e) {
      print('******************** exception $e');
    } catch (error) {
      print('******************** $error');
    }
  }
}

Recipe dbRecipeToRecipe(
    Map<String, Object?> json, List<Ingredient> ingredients) {
  return Recipe(
      id: json[RecipeFields.id] as int,
      image: json[RecipeFields.image] as String,
      label: json[RecipeFields.lable] as String,
      description: json[RecipeFields.description] as String,
      bookmarked: json[RecipeFields.bookmarked] == 1,
      ingredients: ingredients);
}

Map<String, Object?> recipeToDBRecipe(Recipe recipe) {
  return {
    RecipeFields.id: recipe.id,
    RecipeFields.image: recipe.image,
    RecipeFields.lable: recipe.label,
    RecipeFields.description: recipe.description,
    RecipeFields.bookmarked: recipe.bookmarked == true ? 1 : 0,
  };
}

Ingredient dbIngredientToIngredient(Map<String, Object?> json) {
  return Ingredient(
    id: json[IngredientFields.id] as int,
    recipeId: json[IngredientFields.recipeId] as int,
    name: json[IngredientFields.name] as String,
    amount: json[IngredientFields.amount] as double,
  );
}

Map<String, Object?> ingredientToDBIngredient(Ingredient ingredient) {
  return {
    IngredientFields.id: ingredient.id,
    IngredientFields.recipeId: ingredient.recipeId,
    IngredientFields.amount: ingredient.amount,
    IngredientFields.name: ingredient.name,
  };
}
