/* Used to add recipes to local storage
 */

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import 'package:jedzenioplanner/api/server.dart';

class DbApi {
  static Future<Database> get database async {
    return openDatabase(join(await getDatabasesPath(), 'favourites.db'),
        version: 1, onCreate: (db, version) {
      return db.execute(
          "CREATE TABLE favourites(id INTEGER PRIMARY KEY, recipe_id TEXT)");
    });
  }

  static Future<void> addFavourite(String recipeId) async {
    Database db = await database;
    db.insert('favourites', {'recipe_id': recipeId});
  }

  static Future<void> removeFavourite(String recipeId) async {
    Database db = await database;
    db.delete(
      'favourites',
      where: 'recipe_id = ?',
      whereArgs: [recipeId],
    );
  }

  static Future<List<dynamic>> listFavourtes() async {
    // list all favourites from database, queried from server
    Database db = await database;
    final List<Map<String, dynamic>> ids = await db.query('favourites');

    var res = [];
    for(int i=0; i<ids.length; ++i){
      res.add(await ServerApi.getRecipe(ids[i]['recipe_id']));
    }

    return res;
  }

  static Future<bool> isFavourite(String recipeId) async {
    Database db = await database;
    var res = await db.query(
      'favourites',
      where: 'recipe_id = ?',
      whereArgs: [recipeId],
    );
    return res.length > 0;
  }
}
