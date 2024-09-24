import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqlbrite/sqlbrite.dart';

import '../database/fields.dart';
import '../database/sqflite_recipe_db.dart';
import '../models/current_recipe_data.dart';
import '../models/models.dart';
import 'repository.dart';

class SQfDBRepository extends Notifier<CurrentRecipeData>
    implements Repository {
  late Database recipeDatabase;
  late Stream<List<Recipe>>? recipeStream;
  late Stream<List<Ingredient>>? ingredientStream;

  @override
  CurrentRecipeData build() {
    const currentRecipeData = CurrentRecipeData();
    return currentRecipeData;
  }

  @override
  Future<List<Recipe>> findAllRecipes() async {
    final queryResult = await recipeDatabase.query(
      RecipeFields.tableName,
      columns: RecipeFields.columns,
    );
    if (queryResult.isNotEmpty) {
      final recipes = <Recipe>[];
      for (final recipe in queryResult) {
        final ingredients = await findRecipeIngredients(recipe['id'] as int);
        recipes.add(dbRecipeToRecipe(recipe, ingredients));
      }
      return recipes;
    } else {
      return <Recipe>[];
    }
  }

  @override
  Stream<List<Recipe>> watchAllRecipes() {
    print('started watching recipes');
    final briteDB = BriteDatabase(recipeDatabase);
    recipeStream ??= briteDB
        .createQuery(
      RecipeFields.tableName,
      columns: RecipeFields.columns,
    )
        .mapToList((row) {
      return dbRecipeToRecipe(row, <Ingredient>[]);
    });
    return recipeStream!;
  }

//TODO: ingredients might duplicate here
  @override
  Stream<List<Ingredient>> watchAllIngredients() {
    print('started watching ingredients');
    final briteDB = BriteDatabase(recipeDatabase);
    ingredientStream = briteDB
        .createQuery(
          IngredientFields.tableName,
          columns: IngredientFields.columns,
        )
        .mapToList((row) => dbIngredientToIngredient(row));
    return ingredientStream!;
  }

  @override
  Future<Recipe> findRecipeById(int id) async {
    final ingredients = await findRecipeIngredients(id);
    final queryResult = await recipeDatabase.query(
      RecipeFields.tableName,
      columns: RecipeFields.columns,
      where: '${RecipeFields.id} = ?',
      whereArgs: [id],
    );
    if (queryResult.isNotEmpty) {
      return dbRecipeToRecipe(queryResult.first, ingredients);
    } else {
      throw Exception('ID $id not found');
    }
  }

  @override
  Future<List<Ingredient>> findAllIngredients() async {
    final queryResult = await recipeDatabase.query(
      IngredientFields.tableName,
      columns: IngredientFields.columns,
    );
    if (queryResult.isNotEmpty) {
      final ingredients =
          queryResult.map((row) => dbIngredientToIngredient(row)).toList();
      return ingredients;
    } else {
      return <Ingredient>[];
    }
  }

  @override
  Future<List<Ingredient>> findRecipeIngredients(int recipeId) async {
    final queryResult = await recipeDatabase.query(IngredientFields.tableName,
        columns: IngredientFields.columns,
        where: '${IngredientFields.recipeId} = ?',
        whereArgs: [recipeId]);
    if (queryResult.isNotEmpty) {
      final ingredients =
          queryResult.map((row) => dbIngredientToIngredient(row)).toList();
      return ingredients;
    } else {
      throw Exception('RecipeID $recipeId was not Found');
    }
  }

  @override
  Future<int> insertRecipe(Recipe recipe) async {
    if (state.currentRecipes.contains(recipe)) {
      return Future.value(0);
    }
    return Future(() async {
      state = state.copyWith(currentRecipes: [...state.currentRecipes, recipe]);
      final id = await recipeDatabase.insert(
        RecipeFields.tableName,
        recipeToDBRecipe(recipe),
      );
      final ingredients = <Ingredient>[];
      for (final ingredient in recipe.ingredients) {
        ingredients.add(ingredient.copyWith(recipeId: id));
      }
      insertIngredients(ingredients);
      return id;
    });
  }

  @override
  Future<List<int>> insertIngredients(List<Ingredient> ingredients) {
    if (ingredients.isEmpty) {
      return Future(() => <int>[]);
    }
    return Future(() async {
      final resultIds = <int>[];
      for (final ingredient in ingredients) {
        final dbIngredient = ingredientToDBIngredient(ingredient);
        final id = await recipeDatabase.insert(
            IngredientFields.tableName, dbIngredient);
        resultIds.add(id);
      }
      state = state.copyWith(
          currentIngredients: [...state.currentIngredients, ...ingredients]);
      return resultIds;
    });
  }

  @override
  Future<void> deleteIngredient(Ingredient ingredient) async {
    if (ingredient.id != null) {
      await recipeDatabase.delete(
        IngredientFields.tableName,
        where: '${IngredientFields.id} = ?',
        whereArgs: [ingredient.id!],
      );
    } else {
      return Future.value();
    }
  }

  @override
  Future<void> deleteIngredients(List<Ingredient> ingredients) async {
    if (ingredients.isEmpty) {
      return Future.value();
    } else {
      for (final ingredient in ingredients) {
        await deleteIngredient(ingredient);
      }
      return Future.value();
    }
  }

  @override
  Future<void> deleteRecipe(Recipe recipe) async {
    if (recipe.id != null) {
      await recipeDatabase.delete(
        RecipeFields.tableName,
        where: '${RecipeFields.id} = ?',
        whereArgs: [recipe.id],
      );
      deleteRecipeIngredients(recipe.id!);
      return Future.value();
    } else {
      return Future.value();
    }
  }

  @override
  Future<void> deleteRecipeIngredients(int recipeId) async {
    final ingredients = await findRecipeIngredients(recipeId);
    await deleteIngredients(ingredients);
  }

  @override
  Future init() async {
    await Future.microtask(() async {
      recipeDatabase = await RecipeSQFLiteDb.instance.database;
    });
  }

  @override
  void close() {
    recipeDatabase.close();
  }
}
