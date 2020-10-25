/* Show all recipes (paginated).
 */
import 'package:flutter/material.dart';

import 'package:jedzenioplanner/api/database.dart';
import 'package:jedzenioplanner/widgets/recipe_grid.dart';

class FavouritesPage extends StatefulWidget {
  @override
  _FavouritesPageState createState() => _FavouritesPageState();
}

class _FavouritesPageState extends State<FavouritesPage> {
  int page = -1;
  bool isLoading = false;

  List<dynamic> recipes = [];

  @override
  void initState() {
    super.initState();
    isLoading = true;
    _loadData();
  }

  Future _loadData() async {
    page++;
    print("load page $page");
    // update data and loading status
    recipes.addAll(await DbApi.listFavourtes());
    print("recipes: $recipes");
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Zapisane Przepisy"),
      ),
      body: FutureBuilder(
        future: DbApi.listFavourtes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done)
            // loading
            return Center(child: CircularProgressIndicator());

          if(snapshot.hasError)
            return Center(child: Text("Coś poszło nie tak X("));
          
          var recipes = snapshot.data;

          return GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1 / 1.5,
                  crossAxisSpacing: 10.0,
                  mainAxisSpacing: 5.0,
                ),
                itemCount: recipes.length,
                itemBuilder: (context, index) {
                  return RecipeGrid(recipe: recipes[index], id: index);
                },
              );
        },
      ),
    );
  }
}
